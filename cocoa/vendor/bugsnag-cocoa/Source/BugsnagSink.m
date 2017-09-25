//
//  BugsnagSink.m
//
//  Created by Conrad Irwin on 2014-10-01.
//
//  Copyright (c) 2014 Bugsnag, Inc. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//

#import "BugsnagSink.h"
#import "BugsnagNotifier.h"
#import "Bugsnag.h"
#import "BugsnagCrashReport.h"
#import "BugsnagCollections.h"
#import "BugsnagLogger.h"

// This is private in Bugsnag, but really we want package private so define
// it here.
@interface Bugsnag ()
+ (BugsnagNotifier*)notifier;
@end

@implementation BugsnagSink

- (instancetype)initWithApiClient:(BugsnagErrorReportApiClient *)apiClient {
    if (self = [super init]) {
        self.apiClient = apiClient;
    }
    return self;
}

// Entry point called by BSG_KSCrash when a report needs to be sent. Handles report filtering based on the configuration
// options for `notifyReleaseStages`.
// Removes all reports not meeting at least one of the following conditions:
// - the report-specific config specifies the `notifyReleaseStages` property and it contains the current stage
// - the report-specific and global `notifyReleaseStages` properties are unset
// - the report-specific `notifyReleaseStages` property is unset and the global `notifyReleaseStages` property
//   and it contains the current stage
- (void)filterReports:(NSArray*) reports
         onCompletion:(BSG_KSCrashReportFilterCompletion) onCompletion {
    NSMutableArray *bugsnagReports = [NSMutableArray new];
    BugsnagConfiguration *configuration = [Bugsnag configuration];
    for (NSDictionary* report in reports) {
        BugsnagCrashReport *bugsnagReport = [[BugsnagCrashReport alloc] initWithKSReport:report];
        if (![bugsnagReport shouldBeSent])
            continue;
        BOOL shouldSend = YES;
        for (BugsnagBeforeSendBlock block in configuration.beforeSendBlocks) {
            shouldSend = block(report, bugsnagReport);
            if (!shouldSend)
                break;
        }
        if(shouldSend) {
            [bugsnagReports addObject:bugsnagReport];
        }
    }

    if (bugsnagReports.count == 0) {
        if (onCompletion) {
            onCompletion(bugsnagReports, YES, nil);
        }
        return;
    }

    NSDictionary *reportData = [self getBodyFromReports:bugsnagReports];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    for (BugsnagBeforeNotifyHook hook in configuration.beforeNotifyHooks) {
        if (reportData) {
            reportData = hook(reports, reportData);
        } else {
            break;
        }
    }
#pragma clang diagnostic pop

    if (reportData == nil) {
        if (onCompletion) {
            onCompletion(@[], YES, nil);
        }
        return;
    }

    [self.apiClient sendReports:bugsnagReports
              payload:reportData
                toURL:configuration.notifyURL
         onCompletion:onCompletion];
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
        [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

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

// Generates the payload for notifying Bugsnag
- (NSDictionary*) getBodyFromReports:(NSArray*) reports {
    NSMutableDictionary* data = [[NSMutableDictionary alloc] init];
    BSGDictSetSafeObject(data, [Bugsnag configuration].apiKey, @"apiKey");
    BSGDictSetSafeObject(data, [Bugsnag notifier].details, @"notifier");

    NSMutableArray* formatted = [[NSMutableArray alloc] initWithCapacity:[reports count]];

    for (BugsnagCrashReport* report in reports) {
        BSGArrayAddSafeObject(formatted, [report serializableValueWithTopLevelData:data]);
    }

    BSGDictSetSafeObject(data, formatted, @"events");

    return data;
}

@end
