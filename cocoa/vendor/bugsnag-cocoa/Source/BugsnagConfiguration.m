//
//  BugsnagConfiguration.m
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

#import "BugsnagConfiguration.h"
#import "Bugsnag.h"
#import "BugsnagBreadcrumb.h"
#import "BugsnagMetaData.h"
#import "BugsnagNotifier.h"
#import "BugsnagKeys.h"

@interface Bugsnag ()
+ (BugsnagNotifier *)notifier;
@end

@interface BugsnagConfiguration ()
@property(nonatomic, readwrite, strong) NSMutableArray *beforeNotifyHooks;
@property(nonatomic, readwrite, strong) NSMutableArray *beforeSendBlocks;
@end

@implementation BugsnagConfiguration

- (id)init {
    if (self = [super init]) {
        _metaData = [[BugsnagMetaData alloc] init];
        _config = [[BugsnagMetaData alloc] init];
        _apiKey = @"";
        _autoNotify = YES;
        _notifyURL = [NSURL URLWithString:BSGDefaultNotifyUrl];
        _beforeNotifyHooks = [NSMutableArray new];
        _beforeSendBlocks = [NSMutableArray new];
        _notifyReleaseStages = nil;
        _breadcrumbs = [BugsnagBreadcrumbs new];
        _automaticallyCollectBreadcrumbs = YES;
        if ([NSURLSession class]) {
            _session = [NSURLSession
                sessionWithConfiguration:[NSURLSessionConfiguration
                                             defaultSessionConfiguration]];
        }
#if DEBUG
        _releaseStage = BSGKeyDevelopment;
#else
        _releaseStage = BSGKeyProduction;
#endif
    }
    return self;
}

- (BOOL)shouldSendReports {
    return self.notifyReleaseStages.count == 0 ||
           [self.notifyReleaseStages containsObject:self.releaseStage];
}

- (void)setUser:(NSString *)userId
       withName:(NSString *)userName
       andEmail:(NSString *)userEmail {
    [self.metaData addAttribute:BSGKeyId withValue:userId toTabWithName:BSGKeyUser];
    [self.metaData addAttribute:BSGKeyName
                      withValue:userName
                  toTabWithName:BSGKeyUser];
    [self.metaData addAttribute:BSGKeyEmail
                      withValue:userEmail
                  toTabWithName:BSGKeyUser];
}

- (void)addBeforeSendBlock:(BugsnagBeforeSendBlock)block {
    [(NSMutableArray *)self.beforeSendBlocks addObject:[block copy]];
}

- (void)clearBeforeSendBlocks {
    [(NSMutableArray *)self.beforeSendBlocks removeAllObjects];
}

- (void)addBeforeNotifyHook:(BugsnagBeforeNotifyHook)hook {
    [(NSMutableArray *)self.beforeNotifyHooks addObject:[hook copy]];
}

@synthesize releaseStage = _releaseStage;

- (NSString *)releaseStage {
    @synchronized (self) {
        return _releaseStage;
    }
}

- (void)setReleaseStage:(NSString *)newReleaseStage {
    @synchronized (self) {
        _releaseStage = newReleaseStage;
        [self.config addAttribute:BSGKeyReleaseStage
                        withValue:newReleaseStage
                    toTabWithName:BSGKeyConfig];
    }
}

@synthesize notifyReleaseStages = _notifyReleaseStages;

- (NSArray *)notifyReleaseStages {
    @synchronized (self) {
        return _notifyReleaseStages;
    }
}

- (void)setNotifyReleaseStages:(NSArray *)newNotifyReleaseStages;
{
    @synchronized (self) {
        NSArray *notifyReleaseStagesCopy = [newNotifyReleaseStages copy];
        _notifyReleaseStages = notifyReleaseStagesCopy;
        [self.config addAttribute:BSGKeyNotifyReleaseStages
                        withValue:notifyReleaseStagesCopy
                    toTabWithName:BSGKeyConfig];
    }
}

@synthesize automaticallyCollectBreadcrumbs = _automaticallyCollectBreadcrumbs;

- (BOOL)automaticallyCollectBreadcrumbs {
    @synchronized (self) {
        return _automaticallyCollectBreadcrumbs;
    }
}

- (void)setAutomaticallyCollectBreadcrumbs:
    (BOOL)automaticallyCollectBreadcrumbs {
    @synchronized (self) {
        if (automaticallyCollectBreadcrumbs == _automaticallyCollectBreadcrumbs)
            return;

        _automaticallyCollectBreadcrumbs = automaticallyCollectBreadcrumbs;
        [[Bugsnag notifier] updateAutomaticBreadcrumbDetectionSettings];
    }
}

@synthesize context = _context;

- (NSString *)context {
    @synchronized (self) {
        return _context;
    }
}

- (void)setContext:(NSString *)newContext {
    @synchronized (self) {
        _context = newContext;
        [self.config addAttribute:BSGKeyContext
                        withValue:newContext
                    toTabWithName:BSGKeyConfig];
    }
}

@synthesize appVersion = _appVersion;

- (NSString *)appVersion {
    @synchronized (self) {
        return _appVersion;
    }
}

- (void)setAppVersion:(NSString *)newVersion {
    @synchronized (self) {
        _appVersion = newVersion;
        [self.config addAttribute:BSGKeyAppVersion
                        withValue:newVersion
                    toTabWithName:BSGKeyConfig];
    }
}
@end
