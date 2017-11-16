//
//  BugsnagCrashReport.m
//  Bugsnag
//
//  Created by Simon Maynard on 11/26/14.
//
//

#if TARGET_OS_MAC || TARGET_OS_TV
#elif TARGET_IPHONE_SIMULATOR || TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#include <sys/utsname.h>
#endif

#import "BSGSerialization.h"
#import "Bugsnag.h"
#import "BugsnagCollections.h"
#import "BugsnagCrashReport.h"
#import "BugsnagHandledState.h"
#import "BugsnagLogger.h"
#import "BugsnagKeys.h"

NSMutableDictionary *BSGFormatFrame(NSDictionary *frame,
                                    NSArray *binaryImages) {
    NSMutableDictionary *formatted = [NSMutableDictionary dictionary];

    unsigned long instructionAddress =
        [frame[@"instruction_addr"] unsignedLongValue];
    unsigned long symbolAddress = [frame[@"symbol_addr"] unsignedLongValue];
    unsigned long imageAddress = [frame[@"object_addr"] unsignedLongValue];

    BSGDictSetSafeObject(
        formatted, [NSString stringWithFormat:BSGKeyFrameAddrFormat, instructionAddress],
        @"frameAddress");
    BSGDictSetSafeObject(formatted,
                         [NSString stringWithFormat:BSGKeyFrameAddrFormat, symbolAddress],
                         BSGKeySymbolAddr);
    BSGDictSetSafeObject(formatted,
                         [NSString stringWithFormat:BSGKeyFrameAddrFormat, imageAddress],
                         BSGKeyMachoLoadAddr);
    BSGDictInsertIfNotNil(formatted, frame[BSGKeyIsPC], BSGKeyIsPC);
    BSGDictInsertIfNotNil(formatted, frame[BSGKeyIsLR], BSGKeyIsLR);

    NSString *file = frame[@"object_name"];
    NSString *method = frame[@"symbol_name"];

    BSGDictInsertIfNotNil(formatted, file, BSGKeyMachoFile);
    BSGDictInsertIfNotNil(formatted, method, @"method");

    for (NSDictionary *image in binaryImages) {
        if ([(NSNumber *)image[@"image_addr"] unsignedLongValue] ==
            imageAddress) {
            unsigned long imageSlide =
                [image[@"image_vmaddr"] unsignedLongValue];

            BSGDictInsertIfNotNil(formatted, image[@"uuid"], BSGKeyMachoUUID);
            BSGDictInsertIfNotNil(formatted, image[BSGKeyName], BSGKeyMachoFile);
            BSGDictSetSafeObject(
                formatted, [NSString stringWithFormat:BSGKeyFrameAddrFormat, imageSlide],
                BSGKeyMachoVMAddress);

            return formatted;
        }
    }

    return nil;
}

NSString *_Nonnull BSGParseErrorClass(NSDictionary *error,
                                      NSString *errorType) {
    NSString *errorClass;

    if ([errorType isEqualToString:BSGKeyCppException]) {
        errorClass = error[BSGKeyCppException][BSGKeyName];
    } else if ([errorType isEqualToString:BSGKeyMach]) {
        errorClass = error[BSGKeyMach][BSGKeyExceptionName];
    } else if ([errorType isEqualToString:BSGKeySignal]) {
        errorClass = error[BSGKeySignal][BSGKeyName];
    } else if ([errorType isEqualToString:@"nsexception"]) {
        errorClass = error[@"nsexception"][BSGKeyName];
    } else if ([errorType isEqualToString:BSGKeyUser]) {
        errorClass = error[@"user_reported"][BSGKeyName];
    }

    if (!errorClass) { // use a default value
        errorClass = @"Exception";
    }
    return errorClass;
}

NSString *BSGParseErrorMessage(NSDictionary *report, NSDictionary *error,
                               NSString *errorType) {
    if ([errorType isEqualToString:BSGKeyMach] || error[BSGKeyReason] == nil) {
        NSString *diagnosis = [report valueForKeyPath:@"crash.diagnosis"];
        if (diagnosis && ![diagnosis hasPrefix:@"No diagnosis"]) {
            return [[diagnosis componentsSeparatedByString:@"\n"] firstObject];
        }
    }
    return error[BSGKeyReason] ?: @"";
}

NSDictionary *BSGParseDevice(NSDictionary *report) {
    NSDictionary *system = report[@"system"];
    NSMutableDictionary *device = [NSMutableDictionary dictionary];
    
    BSGDictSetSafeObject(device, @"Apple", @"manufacturer");
    BSGDictSetSafeObject(device, [[NSLocale currentLocale] localeIdentifier],
                         @"locale");

    BSGDictSetSafeObject(device, system[@"device_app_hash"], @"id");
    BSGDictSetSafeObject(device, system[@"time_zone"], @"timezone");
    BSGDictSetSafeObject(device, system[@"model"], @"modelNumber");
    BSGDictSetSafeObject(device, system[@"machine"], @"model");
    BSGDictSetSafeObject(device, system[@"system_name"], @"osName");
    BSGDictSetSafeObject(device, system[@"system_version"], @"osVersion");
    BSGDictSetSafeObject(device, system[@"memory"][@"usable"],
                         @"totalMemory");
    return device;
}

NSDictionary *BSGParseApp(NSDictionary *report, NSString *appVersion) {
    NSDictionary *system = report[BSGKeySystem];
    NSMutableDictionary *app = [NSMutableDictionary dictionary];

    BSGDictSetSafeObject(app, system[@"CFBundleVersion"], @"bundleVersion");
    BSGDictSetSafeObject(app, system[@"CFBundleIdentifier"], BSGKeyId);
    BSGDictSetSafeObject(app, system[BSGKeyExecutableName], BSGKeyName);
    BSGDictSetSafeObject(app, [Bugsnag configuration].releaseStage,
                         BSGKeyReleaseStage);
    if ([appVersion isKindOfClass:[NSString class]]) {
        BSGDictSetSafeObject(app, appVersion, BSGKeyVersion);
    } else {
        BSGDictSetSafeObject(app, system[@"CFBundleShortVersionString"],
                             BSGKeyVersion);
    }

    return app;
}

NSDictionary *BSGParseAppState(NSDictionary *report) {
    NSDictionary *appStats = report[BSGKeySystem][@"application_stats"];
    NSMutableDictionary *appState = [NSMutableDictionary dictionary];
    NSInteger activeTimeSinceLaunch =
        [appStats[@"active_time_since_launch"] doubleValue] * 1000.0;
    NSInteger backgroundTimeSinceLaunch =
        [appStats[@"background_time_since_launch"] doubleValue] * 1000.0;

    BSGDictSetSafeObject(appState, @(activeTimeSinceLaunch),
                         @"durationInForeground");
    BSGDictSetSafeObject(appState,
                         @(activeTimeSinceLaunch + backgroundTimeSinceLaunch),
                         @"duration");
    BSGDictSetSafeObject(appState, appStats[@"application_in_foreground"],
                         @"inForeground");
    BSGDictSetSafeObject(appState, appStats, @"stats");

    return appState;
}

NSDictionary *BSGParseDeviceState(NSDictionary *report) {
    NSMutableDictionary *deviceState =
        [[report valueForKeyPath:@"user.state.deviceState"] mutableCopy];
    BSGDictSetSafeObject(deviceState,
                         [report valueForKeyPath:@"system.memory.free"],
                         @"freeMemory");
    BSGDictSetSafeObject(deviceState,
                         [report valueForKeyPath:@"report.timestamp"], @"time");

    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(
        NSDocumentDirectory, NSUserDomainMask, true);
    NSString *path = [searchPaths lastObject];

    NSError *error;
    NSDictionary *fileSystemAttrs =
        [fileManager attributesOfFileSystemForPath:path error:&error];

    if (error) {
        bsg_log_warn(@"Failed to read free disk space: %@", error);
    }

    NSNumber *freeBytes = [fileSystemAttrs objectForKey:NSFileSystemFreeSize];
    BSGDictSetSafeObject(deviceState, freeBytes, @"freeDisk");
    return deviceState;
}

NSString *BSGParseContext(NSDictionary *report, NSDictionary *metaData) {
    id context = [report valueForKeyPath:@"user.overrides.context"];
    if ([context isKindOfClass:[NSString class]])
        return context;
    context = metaData[BSGKeyContext];
    if ([context isKindOfClass:[NSString class]])
        return context;
    context = [report valueForKeyPath:@"user.config.context"];
    if ([context isKindOfClass:[NSString class]])
        return context;
    return nil;
}

NSString *BSGParseGroupingHash(NSDictionary *report, NSDictionary *metaData) {
    id groupingHash = [report valueForKeyPath:@"user.overrides.groupingHash"];
    if (groupingHash)
        return groupingHash;
    groupingHash = metaData[BSGKeyGroupingHash];
    if ([groupingHash isKindOfClass:[NSString class]])
        return groupingHash;
    return nil;
}

NSArray *BSGParseBreadcrumbs(NSDictionary *report) {
    return [report valueForKeyPath:@"user.overrides.breadcrumbs"]
               ?: [report valueForKeyPath:@"user.state.crash.breadcrumbs"];
}

NSString *BSGParseReleaseStage(NSDictionary *report) {
    return [report valueForKeyPath:@"user.overrides.releaseStage"]
               ?: [report valueForKeyPath:@"user.config.releaseStage"];
}

BSGSeverity BSGParseSeverity(NSString *severity) {
    if ([severity isEqualToString:BSGKeyInfo])
        return BSGSeverityInfo;
    else if ([severity isEqualToString:BSGKeyWarning])
        return BSGSeverityWarning;
    return BSGSeverityError;
}

NSString *BSGFormatSeverity(BSGSeverity severity) {
    switch (severity) {
    case BSGSeverityInfo:
        return BSGKeyInfo;
    case BSGSeverityError:
        return BSGKeyError;
    case BSGSeverityWarning:
        return BSGKeyWarning;
    }
}

NSDictionary *BSGParseCustomException(NSDictionary *report,
                                      NSString *errorClass, NSString *message) {
    id frames =
        [report valueForKeyPath:@"user.overrides.customStacktraceFrames"];
    id type = [report valueForKeyPath:@"user.overrides.customStacktraceType"];
    if (type && frames) {
        return @{
            BSGKeyStacktrace : frames,
            BSGKeyType : type,
            BSGKeyErrorClass : errorClass,
            BSGKeyMessage : message
        };
    }

    return nil;
}

static NSString *const DEFAULT_EXCEPTION_TYPE = @"cocoa";

@interface NSDictionary (BSGKSMerge)
- (NSDictionary *)BSG_mergedInto:(NSDictionary *)dest;
@end

@interface BugsnagCrashReport ()

/**
 *  The type of the error, such as `mach` or `user`
 */
@property(nonatomic, readwrite, copy, nullable) NSString *errorType;
/**
 *  The UUID of the dSYM file
 */
@property(nonatomic, readonly, copy, nullable) NSString *dsymUUID;
/**
 *  A unique hash identifying this device for the application or vendor
 */
@property(nonatomic, readonly, copy, nullable) NSString *deviceAppHash;
/**
 *  Binary images used to identify application symbols
 */
@property(nonatomic, readonly, copy, nullable) NSArray *binaryImages;
/**
 *  Thread information captured at the time of the error
 */
@property(nonatomic, readonly, copy, nullable) NSArray *threads;
/**
 *  User-provided exception metadata
 */
@property(nonatomic, readwrite, copy, nullable) NSDictionary *customException;

@end

@implementation BugsnagCrashReport

- (instancetype)initWithKSReport:(NSDictionary *)report {
    if (self = [super init]) {
        _notifyReleaseStages =
            [report valueForKeyPath:@"user.config.notifyReleaseStages"];
        _releaseStage = BSGParseReleaseStage(report);

        _error = [report valueForKeyPath:@"crash.error"];
        _errorType = _error[BSGKeyType];
        _errorClass = BSGParseErrorClass(_error, _errorType);
        _errorMessage = BSGParseErrorMessage(report, _error, _errorType);
        _binaryImages = report[@"binary_images"];
        _threads = [report valueForKeyPath:@"crash.threads"];
        _breadcrumbs = BSGParseBreadcrumbs(report);
        _severity = BSGParseSeverity(
            [report valueForKeyPath:@"user.state.crash.severity"]);
        _depth = [[report valueForKeyPath:@"user.state.crash.depth"]
            unsignedIntegerValue];
        _dsymUUID = [report valueForKeyPath:@"system.app_uuid"];
        _deviceAppHash = [report valueForKeyPath:@"system.device_app_hash"];
        _metaData =
            [report valueForKeyPath:@"user.metaData"] ?: [NSDictionary new];
        _context = BSGParseContext(report, _metaData);
        _deviceState = BSGParseDeviceState(report);
        _device = BSGParseDevice(report);
        _app = BSGParseApp(report,
                           [report valueForKeyPath:@"user.config.appVersion"]);
        _appState = BSGParseAppState(report);
        _groupingHash = BSGParseGroupingHash(report, _metaData);
        _overrides = [report valueForKeyPath:@"user.overrides"];
        _customException = BSGParseCustomException(report, [_errorClass copy],
                                                   [_errorMessage copy]);

        NSDictionary *recordedState =
            [report valueForKeyPath:@"user.handledState"];

        if (recordedState) {
            _handledState =
                [[BugsnagHandledState alloc] initWithDictionary:recordedState];
        } else { // the event was unhandled.
            BOOL isSignal = [BSGKeySignal isEqualToString:_errorType];
            SeverityReasonType severityReason =
                isSignal ? Signal : UnhandledException;
            _handledState = [BugsnagHandledState
                handledStateWithSeverityReason:severityReason
                                      severity:BSGSeverityError
                                     attrValue:_errorClass];
        }
        _severity = _handledState.currentSeverity;
    }
    return self;
}

- (instancetype _Nonnull)
initWithErrorName:(NSString *_Nonnull)name
     errorMessage:(NSString *_Nonnull)message
    configuration:(BugsnagConfiguration *_Nonnull)config
         metaData:(NSDictionary *_Nonnull)metaData
     handledState:(BugsnagHandledState *_Nonnull)handledState {
    if (self = [super init]) {
        _errorClass = name;
        _errorMessage = message;
        _metaData = metaData ?: [NSDictionary new];
        _releaseStage = config.releaseStage;
        _notifyReleaseStages = config.notifyReleaseStages;
        _context = BSGParseContext(nil, metaData);
        _breadcrumbs = [config.breadcrumbs arrayValue];
        _overrides = [NSDictionary new];

        _handledState = handledState;
        _severity = handledState.currentSeverity;
    }
    return self;
}

@synthesize metaData = _metaData;

- (NSDictionary *)metaData {
    @synchronized (self) {
        return _metaData;
    }
}

- (void)setMetaData:(NSDictionary *)metaData {
    @synchronized (self) {
        _metaData = BSGSanitizeDict(metaData);
    }
}

- (void)addMetadata:(NSDictionary *_Nonnull)tabData
      toTabWithName:(NSString *_Nonnull)tabName {
    NSDictionary *cleanedData = BSGSanitizeDict(tabData);
    if ([cleanedData count] == 0) {
        bsg_log_err(@"Failed to add metadata: Values not convertible to JSON");
        return;
    }
    NSMutableDictionary *allMetadata = [self.metaData mutableCopy];
    NSMutableDictionary *allTabData =
        allMetadata[tabName] ?: [NSMutableDictionary new];
    allMetadata[tabName] = [cleanedData BSG_mergedInto:allTabData];
    self.metaData = allMetadata;
}

- (void)addAttribute:(NSString *)attributeName
           withValue:(id)value
       toTabWithName:(NSString *)tabName {
    NSMutableDictionary *allMetadata = [self.metaData mutableCopy];
    NSMutableDictionary *allTabData =
        allMetadata[tabName] ?: [NSMutableDictionary new];
    if (value) {
        id cleanedValue = BSGSanitizeObject(value);
        if (!cleanedValue) {
            bsg_log_err(@"Failed to add metadata: Value of type %@ is not "
                        @"convertible to JSON",
                        [value class]);
            return;
        }
        allTabData[attributeName] = cleanedValue;
    } else {
        [allTabData removeObjectForKey:attributeName];
    }
    allMetadata[tabName] = allTabData;
    self.metaData = allMetadata;
}

- (BOOL)shouldBeSent {
    return [self.notifyReleaseStages containsObject:self.releaseStage] ||
           (self.notifyReleaseStages.count == 0 &&
            [[Bugsnag configuration] shouldSendReports]);
}

@synthesize context = _context;

- (NSString *)context {
    @synchronized (self) {
        return _context;
    }
}

- (void)setContext:(NSString *)context {
    [self setOverrideProperty:BSGKeyContext value:context];
    @synchronized (self) {
        _context = context;
    }
}

@synthesize groupingHash = _groupingHash;

- (NSString *)groupingHash {
    @synchronized (self) {
        return _groupingHash;
    }
}

- (void)setGroupingHash:(NSString *)groupingHash {
    [self setOverrideProperty:BSGKeyGroupingHash value:groupingHash];
    @synchronized (self) {
        _groupingHash = groupingHash;
    }
}

@synthesize breadcrumbs = _breadcrumbs;

- (NSArray *)breadcrumbs {
    @synchronized (self) {
        return _breadcrumbs;
    }
}

- (void)setBreadcrumbs:(NSArray *)breadcrumbs {
    [self setOverrideProperty:BSGKeyBreadcrumbs value:breadcrumbs];
    @synchronized (self) {
        _breadcrumbs = breadcrumbs;
    }
}

@synthesize releaseStage = _releaseStage;

- (NSString *)releaseStage {
    @synchronized (self) {
        return _releaseStage;
    }
}

- (void)setReleaseStage:(NSString *)releaseStage {
    [self setOverrideProperty:BSGKeyReleaseStage value:releaseStage];
    @synchronized (self) {
        _releaseStage = releaseStage;
    }
}

- (void)attachCustomStacktrace:(NSArray *)frames withType:(NSString *)type {
    [self setOverrideProperty:@"customStacktraceFrames" value:frames];
    [self setOverrideProperty:@"customStacktraceType" value:type];
}

@synthesize severity = _severity;

- (BSGSeverity)severity {
    @synchronized (self) {
        return _severity;
    }
}

- (void)setSeverity:(BSGSeverity)severity {
    @synchronized (self) {
        _severity = severity;
        _handledState.currentSeverity = severity;
    }
}

- (void)setOverrideProperty:(NSString *)key value:(id)value {
    @synchronized (self) {
        NSMutableDictionary *metadata = [self.overrides mutableCopy];
        if (value) {
            metadata[key] = value;
        } else {
            [metadata removeObjectForKey:key];
        }
        _overrides = metadata;
    }
    
}

- (NSDictionary *)serializableValueWithTopLevelData:
    (NSMutableDictionary *)data {
    NSMutableDictionary *event = [NSMutableDictionary dictionary];
    NSMutableDictionary *metaData = [[self metaData] mutableCopy];

    if (self.customException) {
        BSGDictSetSafeObject(event, @[ self.customException ], BSGKeyExceptions);
        BSGDictSetSafeObject(event, [self serializeThreadsWithException:nil],
                             BSGKeyThreads);
    } else {
        NSMutableDictionary *exception = [NSMutableDictionary dictionary];
        BSGDictSetSafeObject(exception, [self errorClass], BSGKeyErrorClass);
        BSGDictInsertIfNotNil(exception, [self errorMessage], BSGKeyMessage);
        BSGDictInsertIfNotNil(exception, DEFAULT_EXCEPTION_TYPE, BSGKeyType);
        BSGDictSetSafeObject(event, @[ exception ], BSGKeyExceptions);

        BSGDictSetSafeObject(
            event, [self serializeThreadsWithException:exception], BSGKeyThreads);
    }
    // Build Event
    BSGDictInsertIfNotNil(event, [self dsymUUID], @"dsymUUID");
    BSGDictSetSafeObject(event, BSGFormatSeverity(self.severity), BSGKeySeverity);
    BSGDictSetSafeObject(event, [self breadcrumbs], BSGKeyBreadcrumbs);
    BSGDictSetSafeObject(event, @"3", BSGKeyPayloadVersion);
    BSGDictSetSafeObject(event, metaData, BSGKeyMetaData);
    BSGDictSetSafeObject(event, [self deviceState], BSGKeyDeviceState);
    BSGDictSetSafeObject(event, [self device], BSGKeyDevice);
    BSGDictSetSafeObject(event, [self appState], BSGKeyAppState);
    BSGDictSetSafeObject(event, [self app], BSGKeyApp);
    BSGDictSetSafeObject(event, [self context], BSGKeyContext);
    BSGDictInsertIfNotNil(event, self.groupingHash, BSGKeyGroupingHash);

    BSGDictSetSafeObject(event, @(self.handledState.unhandled), BSGKeyUnhandled);

    // serialize handled/unhandled into payload
    NSMutableDictionary *severityReason = [NSMutableDictionary new];
    NSString *reasonType = [BugsnagHandledState
        stringFromSeverityReason:self.handledState.calculateSeverityReasonType];
    severityReason[BSGKeyType] = reasonType;

    if (self.handledState.attrKey && self.handledState.attrValue) {
        severityReason[BSGKeyAttributes] =
            @{self.handledState.attrKey : self.handledState.attrValue};
    }

    BSGDictSetSafeObject(event, severityReason, BSGKeySeverityReason);

    //  Inserted into `context` property
    [metaData removeObjectForKey:BSGKeyContext];
    // Build metadata
    BSGDictSetSafeObject(metaData, [self error], BSGKeyError);

    // Make user mutable and set the id if the user hasn't already
    NSMutableDictionary *user = [metaData[BSGKeyUser] mutableCopy];
    if (user == nil)
        user = [NSMutableDictionary dictionary];
    BSGDictSetSafeObject(metaData, user, BSGKeyUser);

    if (!user[BSGKeyId] && self.device[BSGKeyId]) { // if device id is null, don't set user id to default
        BSGDictSetSafeObject(user, [self deviceAppHash], BSGKeyId);
    }

    return event;
}

// Build all stacktraces for threads and the error
- (NSArray *)serializeThreadsWithException:(NSMutableDictionary *)exception {
    NSMutableArray *bugsnagThreads = [NSMutableArray array];
    for (NSDictionary *thread in [self threads]) {
        NSArray *backtrace = thread[@"backtrace"][@"contents"];
        BOOL stackOverflow = [thread[@"stack"][@"overflow"] boolValue];
        BOOL isCrashedThread = [thread[@"crashed"] boolValue];
        
        if (isCrashedThread) {
            NSString *errMsg = [self enhancedErrorMessageForThread:thread];
            
            if (errMsg) { // use enhanced error message (currently swift assertions)
                BSGDictInsertIfNotNil(exception, errMsg, BSGKeyMessage);
            }
            
            NSUInteger seen = 0;
            NSMutableArray *stacktrace = [NSMutableArray array];

            for (NSDictionary *frame in backtrace) {
                NSMutableDictionary *mutableFrame = [frame mutableCopy];
                if (seen++ >= [self depth]) {
                    // Mark the frame so we know where it came from
                    if (seen == 1 && !stackOverflow) {
                        BSGDictSetSafeObject(mutableFrame, @YES, BSGKeyIsPC);
                    }
                    if (seen == 2 && !stackOverflow &&
                        [@[ BSGKeySignal, @"deadlock", BSGKeyMach ]
                            containsObject:[self errorType]]) {
                        BSGDictSetSafeObject(mutableFrame, @YES, BSGKeyIsLR);
                    }
                    BSGArrayInsertIfNotNil(
                        stacktrace,
                        BSGFormatFrame(mutableFrame, [self binaryImages]));
                }
            }

            BSGDictSetSafeObject(exception, stacktrace, BSGKeyStacktrace);
        } else {
            NSMutableArray *threadStack = [NSMutableArray array];

            for (NSDictionary *frame in backtrace) {
                BSGArrayInsertIfNotNil(
                    threadStack, BSGFormatFrame(frame, [self binaryImages]));
            }

            NSMutableDictionary *threadDict = [NSMutableDictionary dictionary];
            BSGDictSetSafeObject(threadDict, thread[@"index"], BSGKeyId);
            BSGDictSetSafeObject(threadDict, threadStack, BSGKeyStacktrace);
            BSGDictSetSafeObject(threadDict, DEFAULT_EXCEPTION_TYPE, BSGKeyType);
            // only if this is enabled in BSG_KSCrash.
            if (thread[BSGKeyName]) {
                BSGDictSetSafeObject(threadDict, thread[BSGKeyName], BSGKeyName);
            }

            BSGArrayAddSafeObject(bugsnagThreads, threadDict);
        }
    }
    return bugsnagThreads;
}

/**
 * Returns the enhanced error message for the thread, or nil if none exists.
 *
 * This relies very heavily on heuristics rather than any documented APIs.
 */
- (NSString *)enhancedErrorMessageForThread:(NSDictionary *)thread {
    NSDictionary *notableAddresses = thread[@"notable_addresses"];
    NSMutableArray *msgBuffer = [NSMutableArray new];
    BOOL hasReservedWord = NO;
    
    if (notableAddresses) {
        for (NSString *key in notableAddresses) {
            if (![key hasPrefix:@"stack"]) { // skip stack frames, only use register values
                NSDictionary *data = notableAddresses[key];
                NSString *contentValue = data[@"value"];
                
                hasReservedWord = hasReservedWord || [self isReservedWord:contentValue];
                
                // must be a string that isn't a reserved word and isn't a filepath
                if ([@"string" isEqualToString:data[BSGKeyType]]
                    && ![self isReservedWord:contentValue]
                    && !([[contentValue componentsSeparatedByString:@"/"] count] > 2)) {
                    
                    [msgBuffer addObject:contentValue];
                }
            }
        }
        [msgBuffer sortUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    }
    
    if (hasReservedWord && [msgBuffer count] > 0) { // needs to have a reserved word used + a message
        return [msgBuffer componentsJoinedByString:@" | "];
    } else {
        return nil;
    }
}

/**
 * Determines whether a string is a "reserved word" that identifies it as a known value.
 *
 * For fatalError, preconditionFailure, and assertionFailure, "fatal error" will be in one of the registers.
 *
 * For assert, "assertion failed" will be in one of the registers.
 */
- (BOOL)isReservedWord:(NSString *)contentValue {
    return [@"assertion failed" isEqualToString:contentValue]
    || [@"fatal error" isEqualToString:contentValue];
}

@end
