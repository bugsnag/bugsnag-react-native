//
//  BugsnagConfiguration.h
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

#import "BSGKSCrashReportWriter.h"
#import "BugsnagBreadcrumb.h"
#import "BugsnagCrashReport.h"
#import "BugsnagMetaData.h"
#import <Foundation/Foundation.h>

@class BugsnagBreadcrumbs;

/**
 *  A configuration block for modifying an error report
 *
 *  @param report The default report
 */
typedef void (^BugsnagNotifyBlock)(BugsnagCrashReport *_Nonnull report);

/**
 *  A handler for modifying data before sending it to Bugsnag
 *
 *  @param rawEventData The raw event data written at crash time. This
 *                      includes data added in onCrashHandler.
 *  @param reports      The report generated from the rawEventData
 *
 *  @return YES if the report should be sent
 */
typedef bool (^BugsnagBeforeSendBlock)(
    NSDictionary *_Nonnull rawEventData,
    BugsnagCrashReport *_Nonnull reports);

/**
 *  A handler for modifying data before sending it to Bugsnag
 *
 *  @param rawEventReports The raw event data written at crash time. This
 *                         includes data added in onCrashHandler.
 *  @param report          The default report payload
 *
 *  @return the report payload intended to be sent or nil to cancel sending
 */
typedef NSDictionary *_Nullable (^BugsnagBeforeNotifyHook)(
    NSArray *_Nonnull rawEventReports, NSDictionary *_Nonnull report);

@interface BugsnagConfiguration : NSObject
/**
 *  The API key of a Bugsnag project
 */
@property(nonatomic, readwrite, retain, nullable) NSString *apiKey;
/**
 *  The URL used to notify Bugsnag
 */
@property(nonatomic, readwrite, retain, nullable) NSURL *notifyURL;
/**
 *  The release stage of the application, such as production, development, beta
 *  et cetera
 */
@property(nonatomic, readwrite, retain, nullable) NSString *releaseStage;
/**
 *  Release stages which are allowed to notify Bugsnag
 */
@property(nonatomic, readwrite, retain, nullable) NSArray *notifyReleaseStages;
/**
 *  A general summary of what was occuring in the application
 */
@property(nonatomic, readwrite, retain, nullable) NSString *context;
/**
 *  The version of the application
 */
@property(nonatomic, readwrite, retain, nullable) NSString *appVersion;

/**
 *  The URL session used to send requests to Bugsnag.
 */
@property(nonatomic, readwrite, strong, nonnull) NSURLSession *session;

/**
 *  Additional information about the state of the app or environment at the 
 *  time the report was generated
 */
@property(nonatomic, readwrite, retain, nullable) BugsnagMetaData *metaData;
/**
 *  Meta-information about the state of Bugsnag
 */
@property(nonatomic, readwrite, retain, nullable) BugsnagMetaData *config;
/**
 *  Rolling snapshots of user actions leading up to a crash report
 */
@property(nonatomic, readonly, strong, nullable)
    BugsnagBreadcrumbs *breadcrumbs;

/**
 *  Whether to allow collection of automatic breadcrumbs for notable events
 */
@property(nonatomic, readwrite) BOOL automaticallyCollectBreadcrumbs;

/**
 *  Hooks for modifying crash reports before it is sent to Bugsnag
 */
@property(nonatomic, readonly, strong, nullable)
    NSArray <BugsnagBeforeSendBlock>* beforeSendBlocks;
/**
 *  Optional handler invoked when a crash or fatal signal occurs
 */
@property(nonatomic) void (*_Nullable onCrashHandler)
    (const BSGCrashReportWriter *_Nonnull writer);
/**
 *  YES if uncaught exceptions should be reported automatically
 */
@property(nonatomic) BOOL autoNotify;

/**
 *  Set user metadata
 *
 *  @param userId ID of the user
 *  @param name   Name of the user
 *  @param email  Email address of the user
 */
- (void)setUser:(NSString *_Nullable)userId
       withName:(NSString *_Nullable)name
       andEmail:(NSString *_Nullable)email;

/**
 *  Add a callback to be invoked before a report is sent to Bugsnag, to
 *  change the report contents as needed
 *
 *  @param block A block which returns YES if the report should be sent
 */
- (void)addBeforeSendBlock:(BugsnagBeforeSendBlock _Nonnull)block;


/**
 * Clear all callbacks
 */
- (void)clearBeforeSendBlocks;

/**
 *  Whether reports shoould be sent, based on release stage options
 *
 *  @return YES if reports should be sent based on this configuration
 */
- (BOOL)shouldSendReports;

- (void)addBeforeNotifyHook:(BugsnagBeforeNotifyHook _Nonnull)hook
    __deprecated_msg("Use addBeforeSendBlock: instead.");
/**
 *  Hooks for processing raw report data before it is sent to Bugsnag
 */
@property(nonatomic, readonly, strong, nullable) NSArray *beforeNotifyHooks
    __deprecated_msg("Use beforeNotify instead.");
@end
