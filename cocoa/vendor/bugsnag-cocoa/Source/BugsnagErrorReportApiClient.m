//
//  BugsnagErrorReportApiClient.m
//  Pods
//
//  Created by Jamie Lynch on 11/08/2017.
//
//

#import "BugsnagSink.h"
#import "BugsnagNotifier.h"
#import "Bugsnag.h"
#import "BugsnagCrashReport.h"
#import "BugsnagCollections.h"
#import "BugsnagLogger.h"
#import "BugsnagErrorReportApiClient.h"

// This is private in Bugsnag, but really we want package private so define
// it here.
@interface Bugsnag ()
+ (BugsnagNotifier*)notifier;
@end

@interface BugsnagErrorReportApiClient ()
@property (nonatomic, strong) NSOperationQueue *sendQueue;
@end

@interface BSGDelayOperation : NSOperation
@end

@interface BSGDeliveryOperation : NSOperation
@end

@implementation BugsnagErrorReportApiClient

- (instancetype)init {
    if (self = [super init]) {
        _sendQueue = [[NSOperationQueue alloc] init];
        _sendQueue.maxConcurrentOperationCount = 1;
        if ([_sendQueue respondsToSelector:@selector(qualityOfService)])
            _sendQueue.qualityOfService = NSQualityOfServiceUtility;
        _sendQueue.name = @"Bugsnag Delivery Queue";
    }
    return self;
}

- (void)sendPendingReports {
    [self.sendQueue cancelAllOperations];
    BSGDelayOperation *delay = [BSGDelayOperation new];
    BSGDeliveryOperation *deliver = [BSGDeliveryOperation new];
    [deliver addDependency:delay];
    [self.sendQueue addOperations:@[delay, deliver] waitUntilFinished:NO];
}

- (void)sendReports:(NSArray <BugsnagCrashReport *>*)reports
            payload:(NSDictionary *)reportData
              toURL:(NSURL *)url
       onCompletion:(BSG_KSCrashReportFilterCompletion) onCompletion {
    @try {
        NSError *error = nil;
        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:reportData
                                                           options:NSJSONWritingPrettyPrinted
                                                             error:&error];
        
        if (jsonData == nil) {
            if (onCompletion) {
                onCompletion(reports, NO, error);
            }
            return;
        }
        NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url
                                                               cachePolicy: NSURLRequestReloadIgnoringLocalCacheData
                                                           timeoutInterval: 15];
        request.HTTPMethod = @"POST";
        
        
        if ([NSURLSession class]) {
            NSURLSession *session = [Bugsnag configuration].session;
            if (!session) {
                session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
            }
            NSURLSessionTask *task = [session uploadTaskWithRequest:request fromData:jsonData completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (onCompletion)
                    onCompletion(reports, error == nil, error);
            }];
            [task resume];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            NSURLResponse *response = nil;
            request.HTTPBody = jsonData;
            [NSURLConnection sendSynchronousRequest:request
                                  returningResponse:&response
                                              error:&error];
            if (onCompletion) {
                onCompletion(reports, error == nil, error);
            }
#pragma clang diagnostic pop
        }
    } @catch (NSException *exception) {
        if (onCompletion) {
            onCompletion(reports, NO, [NSError errorWithDomain:exception.reason
                                                          code:420
                                                      userInfo:@{@"exception": exception}]);
        }
    }
}

@end

@implementation BSGDelayOperation
const NSTimeInterval BSG_SEND_DELAY_SECS = 1;

- (void)main {
    [NSThread sleepForTimeInterval:BSG_SEND_DELAY_SECS];
}

@end

@implementation BSGDeliveryOperation

-(void)main {
    @autoreleasepool {
        @try {
            [[BSG_KSCrash sharedInstance] sendAllReportsWithCompletion:^(NSArray *filteredReports, BOOL completed, NSError *error) {
                if (error) {
                    bsg_log_warn(@"Failed to send reports: %@", error);
                } else if (filteredReports.count > 0) {
                    bsg_log_info(@"Reports sent.");
                }
            }];
        }
        @catch (NSException* e) {
            bsg_log_err(@"Could not send report: %@", e);
        }
    }
}

@end
