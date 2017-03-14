#import "Bugsnag.h"
#import "BugsnagReactNative.h"
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
    if (APIKey.length == 0)
        APIKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:BSGInfoPlistKey];

    [Bugsnag startBugsnagWithApiKey:APIKey];
}

+ (void)startWithConfiguration:(BugsnagConfiguration *)config {
    if (config.apiKey.length == 0)
        config.apiKey = [[NSBundle mainBundle] objectForInfoDictionaryKey:BSGInfoPlistKey];

    [Bugsnag startBugsnagWithConfiguration:config];
}

RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(notify:(NSDictionary *)options) {
    NSString *const EXCEPTION_TYPE = @"browserjs";
    NSException *exception = [NSException
                              exceptionWithName:[RCTConvert NSString:options[@"errorClass"]]
                              reason:[RCTConvert NSString:options[@"errorMessage"]]
                              userInfo:nil];
    [Bugsnag notify:exception block:^(BugsnagCrashReport *report) {
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
        if (options[@"severity"])
            report.severity = BSGParseSeverity([RCTConvert NSString:options[@"severity"]]);
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
}

RCT_EXPORT_METHOD(setUser:(NSDictionary *)userInfo) {
    NSString *identifier = userInfo[@"id"] ? [RCTConvert NSString:userInfo[@"id"]] : nil;
    NSString *name = userInfo[@"name"] ? [RCTConvert NSString:userInfo[@"name"]] : nil;
    NSString *email = userInfo[@"email"] ? [RCTConvert NSString:userInfo[@"email"]] : nil;
    [[Bugsnag configuration] setUser:identifier withName:name andEmail:email];
}

RCT_EXPORT_METHOD(clearUser) {
    [[Bugsnag configuration] setUser:nil withName:nil andEmail:nil];
}

RCT_EXPORT_METHOD(leaveBreadcrumb:(NSDictionary *)options) {
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
    NSString *appVersion = [RCTConvert NSString:options[@"appVersion"]];
    BugsnagConfiguration* config = [Bugsnag bugsnagStarted] ? [Bugsnag configuration] : [BugsnagConfiguration new];
    config.apiKey = apiKey;
    config.releaseStage = releaseStage;
    config.notifyReleaseStages = notifyReleaseStages;
    [config addBeforeSendBlock:^bool(NSDictionary *_Nonnull rawEventData,
                                     BugsnagCrashReport *_Nonnull report) {
        return !([report.errorClass hasPrefix:@"RCTFatalException"]
                 && [report.errorMessage hasPrefix:@"Unhandled JS Exception"]);
    }];
    if (notifyURLPath.length > 0) {
        NSURL *notifyURL = [NSURL URLWithString:notifyURLPath];
        if (notifyURL)
            config.notifyURL = notifyURL;
    }
    if (appVersion.length > 0) {
        config.appVersion = appVersion;
    }
    if (![Bugsnag bugsnagStarted]) {
        [Bugsnag startBugsnagWithConfiguration:config];
    }
    [self setNotifierDetails:[RCTConvert NSString:options[@"version"]]];
}

- (void)setNotifierDetails:(NSString *)packageVersion {
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
