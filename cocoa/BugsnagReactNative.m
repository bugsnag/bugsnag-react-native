#import "Bugsnag.h"
#import "BSG_KSCrashC.h"
#import "BugsnagReactNative.h"
#import "RCTVersion.h"
#import <React/RCTConvert.h>

NSString *const BSGInfoPlistKey = @"BugsnagAPIKey";

BSGBreadcrumbType BreadcrumbTypeFromString(NSString *type) {
    if ([type isEqualToString:@"log"])
        return BSGBreadcrumbTypeLog;
    else if ([type isEqualToString:@"user"])
        return BSGBreadcrumbTypeUser;
    else if ([type isEqualToString:@"error"])
        return BSGBreadcrumbTypeError;
    else if ([type isEqualToString:@"state"])
        return BSGBreadcrumbTypeState;
    else if ([type isEqualToString:@"process"])
        return BSGBreadcrumbTypeProcess;
    else if ([type isEqualToString:@"request"])
        return BSGBreadcrumbTypeRequest;
    else if ([type isEqualToString:@"navigation"])
        return BSGBreadcrumbTypeNavigation;
    else
        return BSGBreadcrumbTypeManual;
}

NSDictionary *BSGConvertTypedNSDictionary(id rawData) {
    NSDictionary *data = [RCTConvert NSDictionary:rawData];
    NSMutableDictionary *converted = [NSMutableDictionary new];
    NSArray *keys = [data allKeys];
    for (int i = 0; i < data.count; i++) {
        NSString *key = [RCTConvert NSString:keys[i]];
        NSDictionary *pair = [RCTConvert NSDictionary:data[key]];
        NSString *type = [RCTConvert NSString:pair[@"type"]];
        id value = pair[@"value"];
        if ([@"boolean" isEqualToString:type]) {
            converted[key] = @([RCTConvert BOOL:value]);
        } else if ([@"number" isEqualToString:type]) {
            converted[key] = [RCTConvert NSNumber:value];
        } else if ([@"string" isEqualToString:type]) {
            converted[key] = [RCTConvert NSString:value];
        } else if ([@"map" isEqualToString:type]) {
            converted[key] = BSGConvertTypedNSDictionary(value);
        }
    }
    return converted;
}

/**
 *  Convert a string stacktrace into individual frames
 *
 *  @param stacktrace a stacktrace represented as a single block
 *
 *  @return array of frames
 */
NSArray *BSGParseJavaScriptStacktrace(NSString *stacktrace, NSNumberFormatter *formatter) {
    NSCharacterSet* methodSeparator = [NSCharacterSet characterSetWithCharactersInString:@"@"];
    NSCharacterSet* locationSeparator = [NSCharacterSet characterSetWithCharactersInString:@":"];
    NSArray *lines = [stacktrace componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *frames = [NSMutableArray arrayWithCapacity:lines.count];
    for (NSString *line in lines) {
        NSMutableDictionary *frame = [NSMutableDictionary new];
        NSString *location = line;
        NSRange methodRange = [line rangeOfCharacterFromSet:methodSeparator];
        if (methodRange.location != NSNotFound) {
            frame[@"method"] = [line substringToIndex:methodRange.location];
            location = [line substringFromIndex:methodRange.location + 1];
        }
        NSRange search = [location rangeOfCharacterFromSet:locationSeparator options:NSBackwardsSearch];
        if (search.location != NSNotFound) {
            NSRange matchRange = NSMakeRange(search.location + 1, location.length - search.location - 1);
            NSNumber *value = [formatter numberFromString:[location substringWithRange:matchRange]];
            if (value) {
                frame[@"columnNumber"] = value;
                location = [location substringToIndex:search.location];
            }
        }
        search = [location rangeOfCharacterFromSet:locationSeparator options:NSBackwardsSearch];
        if (search.location != NSNotFound) {
            NSRange matchRange = NSMakeRange(search.location + 1, location.length - search.location - 1);
            NSNumber *value = [formatter numberFromString:[location substringWithRange:matchRange]];
            if (value) {
                frame[@"lineNumber"] = value;
                location = [location substringToIndex:search.location];
            }
        }
        NSURL *bundleURL = [[NSBundle mainBundle] bundleURL];
        search = [location rangeOfString:[bundleURL absoluteString]];
        if (search.location != NSNotFound) {
            location = [location substringFromIndex:search.location + search.length];
        } else {
            search = [location rangeOfString:[bundleURL path]];
            if (search.location != NSNotFound)
                location = [location substringFromIndex:search.location + search.length + 1];
        }
        frame[@"file"] = location;
        [frames addObject:frame];
    }
    return frames;
}

bool (^BSGReactNativeReportFilter)(NSDictionary *, BugsnagCrashReport *) = ^bool(NSDictionary *rawEventData,
                                                                                 BugsnagCrashReport *_Nonnull report) {
    return !([report.errorClass hasPrefix:@"RCTFatalException"]
          && [report.errorMessage hasPrefix:@"Unhandled JS Exception"]);
};

@interface Bugsnag ()
+ (id)notifier;
+ (BOOL)bugsnagStarted;
@end

@implementation BugsnagReactNative

+ (NSNumberFormatter *)numberFormatter {
    static dispatch_once_t onceToken;
    static NSNumberFormatter *formatter = nil;
    dispatch_once(&onceToken, ^{
        formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterNoStyle;
    });
    return formatter;
}

+ (void)start {
    [self startWithAPIKey:nil];
}

+ (void)startWithAPIKey:(NSString *)APIKey {
    BugsnagConfiguration *config = [BugsnagConfiguration new];
    config.apiKey = APIKey;
    [self startWithConfiguration:config];
}

+ (void)startWithConfiguration:(BugsnagConfiguration *)config {
    if (config.apiKey.length == 0)
        config.apiKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:BSGInfoPlistKey];

    // The first session starts during JS initialization
    // Applications which have specific components in RN instead of the primary
    // way to interact with the application should instead leverage startSession
    // manually.
    config.shouldAutoCaptureSessions = NO;
    [config addBeforeSendBlock:BSGReactNativeReportFilter];
    [Bugsnag startBugsnagWithConfiguration:config];
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(notify:(NSDictionary *)options
                  resolve:(RCTPromiseResolveBlock)resolve
                  reject:(RCTPromiseRejectBlock)reject) {
    if (![Bugsnag bugsnagStarted]) {
        return;
    }

    NSString *const EXCEPTION_TYPE = @"browserjs";
    NSException *exception = [NSException
                              exceptionWithName:[RCTConvert NSString:options[@"errorClass"]]
                              reason:[RCTConvert NSString:options[@"errorMessage"]]
                              userInfo:nil];

    [Bugsnag internalClientNotify:exception
                         withData:options
                            block:^(BugsnagCrashReport *report) {
        NSArray* stackframes = nil;
        if (options[@"stacktrace"]) {
            stackframes = BSGParseJavaScriptStacktrace([RCTConvert NSString:options[@"stacktrace"]],
                                                       [BugsnagReactNative numberFormatter]);
            [report attachCustomStacktrace:stackframes withType:EXCEPTION_TYPE];
        }
        if (options[@"context"])
            report.context = [RCTConvert NSString:options[@"context"]];
        if (options[@"groupingHash"])
            report.groupingHash = [RCTConvert NSString:options[@"groupingHash"]];
        if (options[@"metadata"]) {
            NSDictionary *metadata = BSGConvertTypedNSDictionary(options[@"metadata"]);
            NSMutableDictionary *targetMetadata = [report.metaData mutableCopy];
            if (!targetMetadata)
                targetMetadata = [NSMutableDictionary new];
            for (NSString *sectionKey in metadata) {
                if (![metadata[sectionKey] isKindOfClass:[NSDictionary class]]) {
                    NSLog(@"Bugsnag: The metadata recorded for key '%@' is not formatted as key/value pairs. Discarding.", sectionKey);
                    continue;
                }

                NSMutableDictionary *section = [targetMetadata[sectionKey] mutableCopy];
                if (!section)
                    section = [NSMutableDictionary new];
                for (NSString *key in metadata[sectionKey]) {
                    section[key] = metadata[sectionKey][key];
                }
                targetMetadata[sectionKey] = section;
            }
            report.metaData = targetMetadata;
        }
    }];
    resolve(@"");
}

RCT_EXPORT_METHOD(setUser:(NSDictionary *)userInfo) {
    if (![Bugsnag bugsnagStarted]) {
        return;
    }
    NSString *identifier = userInfo[@"id"] ? [RCTConvert NSString:userInfo[@"id"]] : nil;
    NSString *name = userInfo[@"name"] ? [RCTConvert NSString:userInfo[@"name"]] : nil;
    NSString *email = userInfo[@"email"] ? [RCTConvert NSString:userInfo[@"email"]] : nil;
    [[Bugsnag configuration] setUser:identifier withName:name andEmail:email];
}

RCT_EXPORT_METHOD(startSession) {
    if (![Bugsnag bugsnagStarted]) {
        return;
    }
    [Bugsnag startSession];
}

RCT_EXPORT_METHOD(stopSession) {
    if (![Bugsnag bugsnagStarted]) {
        return;
    }
    [Bugsnag stopSession];
}

RCT_EXPORT_METHOD(resumeSession) {
    if (![Bugsnag bugsnagStarted]) {
        return;
    }
    [Bugsnag resumeSession];
}

RCT_EXPORT_METHOD(clearUser) {
    if (![Bugsnag bugsnagStarted]) {
        return;
    }
    [[Bugsnag configuration] setUser:nil withName:nil andEmail:nil];
}

RCT_EXPORT_METHOD(leaveBreadcrumb:(NSDictionary *)options) {
    if (![Bugsnag bugsnagStarted]) {
        return;
    }
    [Bugsnag leaveBreadcrumbWithBlock:^(BugsnagBreadcrumb *crumb) {
        crumb.name = [RCTConvert NSString:options[@"name"]];
        crumb.type = BreadcrumbTypeFromString([RCTConvert NSString:options[@"type"]]);
        crumb.metadata = BSGConvertTypedNSDictionary(options[@"metadata"]);
    }];
}

RCT_EXPORT_METHOD(startWithOptions:(NSDictionary *)options) {
    NSString *apiKey = [RCTConvert NSString:options[@"apiKey"]];
    if (apiKey.length == 0)
        apiKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:BSGInfoPlistKey];

    NSString *releaseStage = [self  parseReleaseStage:[RCTConvert NSString:options[@"releaseStage"]]];
    NSArray *notifyReleaseStages = [RCTConvert NSStringArray:options[@"notifyReleaseStages"]];
    NSString *notifyURLPath = [RCTConvert NSString:options[@"endpoint"]];
    NSString *sessionURLPath = [RCTConvert NSString:options[@"sessionsEndpoint"]];
    NSString *appVersion = [RCTConvert NSString:options[@"appVersion"]];
    NSString *codeBundleId = [RCTConvert NSString:options[@"codeBundleId"]];

    BugsnagConfiguration* config = [Bugsnag bugsnagStarted] ? [Bugsnag configuration] : [BugsnagConfiguration new];

    if (apiKey.length > 0) {
        config.apiKey = apiKey;
    }

    config.releaseStage = releaseStage;
    config.notifyReleaseStages = notifyReleaseStages;
    config.autoNotify = [RCTConvert BOOL:options[@"autoNotify"]];
    config.shouldAutoCaptureSessions = [RCTConvert BOOL:options[@"autoCaptureSessions"]];
    config.automaticallyCollectBreadcrumbs = [RCTConvert BOOL:options[@"automaticallyCollectBreadcrumbs"]];

    [config addBeforeSendSession:^void(NSMutableDictionary *_Nonnull data) {
        data[@"device"] = [self addDeviceRuntimeVersion:data[@"device"]
                                     reactNativeVersion:[self findReactNativeVersion]];
    }];

    [config addBeforeSendBlock:^bool(NSDictionary *_Nonnull rawEventData,
                                     BugsnagCrashReport *_Nonnull report) {
        NSString *reactNativeVersion = report.metaData[@"_bugsnag"][@"reactNativeVersion"];
        if (reactNativeVersion != nil) {
            report.device = [self addDeviceRuntimeVersion:report.device reactNativeVersion:reactNativeVersion];
        }
        report.metaData = [self removeRuntimeVersionFromMetaData:report];

        return !([report.errorClass hasPrefix:@"RCTFatalException"]
                 && [report.errorMessage hasPrefix:@"Unhandled JS Exception"]);
    }];

    if (notifyURLPath.length > 0) {
        [config setEndpointsForNotify:notifyURLPath
                             sessions:sessionURLPath];
    }

    if (appVersion.length > 0) {
        config.appVersion = appVersion;
    }
    if (codeBundleId.length > 0) {
        [config.metaData addAttribute:@"codeBundleId"
                            withValue:codeBundleId
                        toTabWithName:@"app"];
    }
    if ([Bugsnag bugsnagStarted]) {
        if (!config.autoNotify) {
            bsg_kscrash_setHandlingCrashTypes(BSG_KSCrashTypeUserReported);
        }
    } else {
        [config addBeforeSendBlock:BSGReactNativeReportFilter];
        [Bugsnag startBugsnagWithConfiguration:config];
    }
    [self setNotifierDetails:[RCTConvert NSString:options[@"version"]]];
    if (config.shouldAutoCaptureSessions) {
        // The launch event session is skipped because shouldAutoCaptureSessions
        // was not set when Bugsnag was first initialized. Manually sending a
        // session to compensate.
        [Bugsnag resumeSession];
    }
    [self addRuntimeVersionToMetaData:config];
}

/**
 * Stores runtime version info in a metadata tab (it will be moved to a
 * different payload location before sending)
 */
- (void)addRuntimeVersionToMetaData:(BugsnagConfiguration *)config {
    [config.metaData addAttribute:@"reactNativeVersion"
                        withValue:[self findReactNativeVersion]
                    toTabWithName:@"_bugsnag"];
}

- (NSDictionary *)removeRuntimeVersionFromMetaData:(BugsnagCrashReport *)report {
    NSMutableDictionary *metadata = report.metaData.mutableCopy;
    metadata[@"_bugsnag"] = nil;
    return metadata;
}

- (NSDictionary *)addDeviceRuntimeVersion:(NSDictionary *)device
                       reactNativeVersion:(NSString *)reactNativeVersion {
    NSMutableDictionary *copy = [device mutableCopy];
    NSMutableDictionary *runtimeVersions = [copy[@"runtimeVersions"] mutableCopy];

    if (runtimeVersions == nil) {
        runtimeVersions = [NSMutableDictionary new];
    }
    runtimeVersions[@"reactNative"] = reactNativeVersion;
    copy[@"runtimeVersions"] = runtimeVersions;
    return copy;
}

// see https://github.com/facebook/react-native/blob/6df2edeb2a33d529e4b13a5b6767f300d08aeb0a/scripts/bump-oss-version.js
- (NSString *)findReactNativeVersion {
    static dispatch_once_t onceToken;
    static NSString *BSGReactNativeVersion = nil;
    dispatch_once(&onceToken, ^{
        #ifdef RCT_REACT_NATIVE_VERSION
            // for react-native versions prior 0.55
            // see https://github.com/react-native-community/releases/blob/451f8e7fa53f80daec9c2381c7984bee73efa51d/CHANGELOG.md#ios-specific-additions
            NSDictionary *versionMap = RCT_REACT_NATIVE_VERSION;
        #else
            NSDictionary *versionMap = RCTGetReactNativeVersion();
        #endif
        NSNumber *major = versionMap[@"major"];
        NSNumber *minor = versionMap[@"minor"];
        NSNumber *patch = versionMap[@"patch"];
        NSString *prerelease = versionMap[@"prerelease"];
        NSMutableString *versionString = [NSMutableString new];

        if (![major isEqual:[NSNull null]]) {
            [versionString appendString:[major stringValue]];
            [versionString appendString:@"."];
        }
        if (![minor isEqual:[NSNull null]]) {
            [versionString appendString:[minor stringValue]];
            [versionString appendString:@"."];
        }
        if (![patch isEqual:[NSNull null]]) {
            [versionString appendString:[patch stringValue]];
        }
        if (![prerelease isEqual:[NSNull null]]) {
            [versionString appendString:@"-"];
            [versionString appendString:prerelease];
        }
        BSGReactNativeVersion = [NSString stringWithString:versionString];
    });
    return BSGReactNativeVersion;
}

- (void)setNotifierDetails:(NSString *)packageVersion {
    if (![Bugsnag bugsnagStarted]) {
        return;
    }
    id notifier = [Bugsnag notifier];
    NSDictionary *details = [notifier valueForKey:@"details"];
    NSString *version;
    if ([details[@"version"] containsString:@"("]) {
        version = details[@"version"];
    } else {
        version = [NSString stringWithFormat:@"%@ (Cocoa %@)", packageVersion, details[@"version"]];
    }
    NSDictionary *newDetails = @{
        @"version": version,
        @"name": @"Bugsnag for React Native",
        @"url": @"https://github.com/bugsnag/bugsnag-react-native"
    };
    [notifier setValue:newDetails forKey:@"details"];
}

- (NSString *)parseReleaseStage:(NSString *)releaseStage {
    if (releaseStage.length > 0)
        return releaseStage;

#ifdef DEBUG
    return @"development";
#endif
    BOOL isRunningTestFlightBeta = [[[[NSBundle mainBundle] appStoreReceiptURL] lastPathComponent] isEqualToString:@"sandboxReceipt"];
    if (isRunningTestFlightBeta) {
        return @"testflight";
    } else {
        return @"production";
    }
}

@end
