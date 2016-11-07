//
//  KSCrashReport.m
//  Bugsnag
//
//  Created by Simon Maynard on 11/26/14.
//
//

#import "Bugsnag.h"
#import "BugsnagCollections.h"
#import "BugsnagCrashReport.h"

NSMutableDictionary *BSGFormatFrame(NSDictionary *frame,
                                    NSArray *binaryImages) {
  NSMutableDictionary *formatted = [NSMutableDictionary dictionary];

  unsigned long instructionAddress =
      [frame[@"instruction_addr"] unsignedLongValue];
  unsigned long symbolAddress = [frame[@"symbol_addr"] unsignedLongValue];
  unsigned long imageAddress = [frame[@"object_addr"] unsignedLongValue];

  BSGDictSetSafeObject(formatted,
                       [NSString stringWithFormat:@"0x%lx", instructionAddress],
                       @"frameAddress");
  BSGDictSetSafeObject(formatted,
                       [NSString stringWithFormat:@"0x%lx", symbolAddress],
                       @"symbolAddress");
  BSGDictSetSafeObject(formatted,
                       [NSString stringWithFormat:@"0x%lx", imageAddress],
                       @"machoLoadAddress");
  BSGDictInsertIfNotNil(formatted, frame[@"isPC"], @"isPC");
  BSGDictInsertIfNotNil(formatted, frame[@"isLR"], @"isLR");

  NSString *file = frame[@"object_name"];
  NSString *method = frame[@"symbol_name"];

  BSGDictInsertIfNotNil(formatted, file, @"machoFile");
  BSGDictInsertIfNotNil(formatted, method, @"method");

  for (NSDictionary *image in binaryImages) {
    if ([(NSNumber *)image[@"image_addr"] unsignedLongValue] == imageAddress) {
      unsigned long imageSlide = [image[@"image_vmaddr"] unsignedLongValue];

      BSGDictInsertIfNotNil(formatted, image[@"uuid"], @"machoUUID");
      BSGDictInsertIfNotNil(formatted, image[@"name"], @"machoFile");
      BSGDictSetSafeObject(formatted,
                           [NSString stringWithFormat:@"0x%lx", imageSlide],
                           @"machoVMAddress");

      return formatted;
    }
  }

  return nil;
}

NSString *BSGParseErrorClass(NSDictionary *error, NSString *errorType) {
    if ([errorType isEqualToString:@"cpp_exception"]) {
        return error[@"cpp_exception"][@"name"];
    } else if ([errorType isEqualToString:@"mach"]) {
        return error[@"mach"][@"exception_name"];
    } else if ([errorType isEqualToString:@"signal"]) {
        return error[@"signal"][@"name"];
    } else if ([errorType isEqualToString:@"nsexception"]) {
        return error[@"nsexception"][@"name"];
    } else if ([errorType isEqualToString:@"user"]) {
        return error[@"user_reported"][@"name"];
    }
    return @"Exception";
}

NSString *BSGParseErrorMessage(NSDictionary *report, NSDictionary *error, NSString *errorType) {
    if ([errorType isEqualToString:@"mach"] || error[@"reason"] == nil) {
        NSString *diagnosis = [report valueForKeyPath:@"crash.diagnosis"];
        if (diagnosis && ![diagnosis hasPrefix:@"No diagnosis"]) {
            return [[diagnosis componentsSeparatedByString:@"\n"] firstObject];
        }
    }
    return error[@"reason"] ?: @"";
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
    NSDictionary *system = report[@"system"];
    NSMutableDictionary *app = [NSMutableDictionary dictionary];

    BSGDictSetSafeObject(app, system[@"CFBundleVersion"], @"bundleVersion");
    BSGDictSetSafeObject(app, system[@"CFBundleIdentifier"], @"id");
    BSGDictSetSafeObject(app, system[@"CFBundleExecutable"], @"name");
    BSGDictSetSafeObject(app, [Bugsnag configuration].releaseStage,
                         @"releaseStage");
    if ([appVersion isKindOfClass:[NSString class]]) {
        BSGDictSetSafeObject(app, appVersion, @"version");
    } else {
        BSGDictSetSafeObject(app, system[@"CFBundleShortVersionString"],
                             @"version");
    }
    
    return app;
}

NSDictionary *BSGParseAppState(NSDictionary *report) {
    NSDictionary *appStats = report[@"system"][@"application_stats"];
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
                         [report valueForKeyPath:@"report.timestamp"],
                         @"time");
    return deviceState;
}

NSString *BSGParseContext(NSDictionary *report, NSDictionary *metaData) {
    id context = [report valueForKeyPath:@"user.overrides.context"];
    if ([context isKindOfClass:[NSString class]])
        return context;
    context = metaData[@"context"];
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
    groupingHash = metaData[@"groupingHash"];
    if ([groupingHash isKindOfClass:[NSString class]])
        return groupingHash;
    return nil;
}

NSArray *BSGParseBreadcrumbs(NSDictionary *report) {
    return [report valueForKeyPath:@"user.overrides.breadcrumbs"] ?:
        [report valueForKeyPath:@"user.state.crash.breadcrumbs"];
}

NSString *BSGParseReleaseStage(NSDictionary *report) {
    return [report valueForKeyPath:@"user.overrides.releaseStage"] ?:
    [report valueForKeyPath:@"user.config.releaseStage"];
}

BSGSeverity BSGParseSeverity(NSString *severity) {
    if ([severity isEqualToString:@"info"])
        return BSGSeverityInfo;
    else if ([severity isEqualToString:@"warning"])
        return BSGSeverityWarning;
    return BSGSeverityError;
}

NSString *BSGFormatSeverity(BSGSeverity severity) {
    switch (severity) {
        case BSGSeverityInfo:
            return @"info";
        case BSGSeverityError:
            return @"error";
        case BSGSeverityWarning:
            return @"warning";
    }
}

NSDictionary *BSGParseCustomException(NSDictionary *report, NSString *errorClass, NSString *message) {
    id frames = [report valueForKeyPath:@"user.overrides.customStacktraceFrames"];
    id type = [report valueForKeyPath:@"user.overrides.customStacktraceType"];
    if (type && frames) {
        return @{ @"stacktrace": frames,
                  @"type": type,
                  @"errorClass": errorClass,
                  @"message": message};
    }

    return nil;
}

static NSString *const DEFAULT_EXCEPTION_TYPE = @"cocoa";

@interface BugsnagCrashReport ()

/**
 *  The type of the error, such as `mach` or `user`
 */
@property (nonatomic, readwrite, copy, nullable) NSString *errorType;
/**
 *  The UUID of the dSYM file
 */
@property (nonatomic, readonly, copy, nullable) NSString *dsymUUID;
/**
 *  A unique hash identifying this device for the application or vendor
 */
@property (nonatomic, readonly, copy, nullable) NSString *deviceAppHash;
/**
 *  Binary images used to identify application symbols
 */
@property (nonatomic, readonly, copy, nullable) NSArray *binaryImages;
/**
 *  Thread information captured at the time of the error
 */
@property (nonatomic, readonly, copy, nullable) NSArray *threads;
/**
 *  User-provided exception metadata
 */
@property (nonatomic, readwrite, copy, nullable) NSDictionary *customException;
@end

@implementation BugsnagCrashReport

- (instancetype)initWithKSReport:(NSDictionary *)report {
  if (self = [super init]) {
      _notifyReleaseStages = [report valueForKeyPath:@"user.config.notifyReleaseStages"];
      _releaseStage = BSGParseReleaseStage(report);
      _error = [report valueForKeyPath:@"crash.error"];
      _errorType = _error[@"type"];
      _errorClass = BSGParseErrorClass(_error, _errorType);
      _errorMessage = BSGParseErrorMessage(report, _error, _errorType);
      _binaryImages = report[@"binary_images"];
      _threads = [report valueForKeyPath:@"crash.threads"];
      _breadcrumbs = BSGParseBreadcrumbs(report);
      _severity = BSGParseSeverity([report valueForKeyPath:@"user.state.crash.severity"]);
      _depth = [[report valueForKeyPath:@"user.state.crash.depth"] unsignedIntegerValue];
      _dsymUUID = [report valueForKeyPath:@"system.app_uuid"];
      _deviceAppHash = [report valueForKeyPath:@"system.device_app_hash"];
      _metaData = [report valueForKeyPath:@"user.metaData"] ?: [NSDictionary new];
      _context = BSGParseContext(report, _metaData);
      _deviceState = BSGParseDeviceState(report);
      _device = BSGParseDevice(report);
      _app = BSGParseApp(report, [report valueForKeyPath:@"user.config.appVersion"]);
      _appState = BSGParseAppState(report);
      _groupingHash = BSGParseGroupingHash(report, _metaData);
      _overrides = [report valueForKeyPath:@"user.overrides"];
      _customException = BSGParseCustomException(report, [_errorClass copy], [_errorMessage copy]);
  }
  return self;
}

- (instancetype)initWithErrorName:(NSString *)name
                     errorMessage:(NSString *)message
                    configuration:(BugsnagConfiguration *)config
                         metaData:(NSDictionary *)metaData
                         severity:(BSGSeverity)severity {
    if (self = [super init]) {
        _errorClass = name;
        _errorMessage = message;
        _metaData = metaData ?: [NSDictionary new];
        _severity = severity;
        _releaseStage = config.releaseStage;
        _notifyReleaseStages = config.notifyReleaseStages;
        _context = BSGParseContext(nil, metaData);
        _breadcrumbs = [config.breadcrumbs arrayValue];
        _overrides = [NSDictionary new];
    }
    return self;
}

- (BOOL)shouldBeSent {
    return [self.notifyReleaseStages containsObject:self.releaseStage]
        || (self.notifyReleaseStages.count == 0 && [[Bugsnag configuration] shouldSendReports]);
}

- (void)setContext:(NSString *)context {
    [self setOverrideProperty:@"context" value:context];
    _context = context;
}

- (void)setGroupingHash:(NSString *)groupingHash {
    [self setOverrideProperty:@"groupingHash" value:groupingHash];
    _groupingHash = groupingHash;
}

- (void)setBreadcrumbs:(NSArray *)breadcrumbs {
    [self setOverrideProperty:@"breadcrumbs" value:breadcrumbs];
    _breadcrumbs = breadcrumbs;
}

- (void)setReleaseStage:(NSString *)releaseStage {
    [self setOverrideProperty:@"releaseStage" value:releaseStage];
    _releaseStage = releaseStage;
}

- (void)attachCustomStacktrace:(NSArray *)frames withType:(NSString *)type {
    [self setOverrideProperty:@"customStacktraceFrames" value:frames];
    [self setOverrideProperty:@"customStacktraceType" value:type];
}

- (void)setOverrideProperty:(NSString *)key value:(id)value {
    NSMutableDictionary *metadata = [self.overrides mutableCopy];
    if (value) {
        metadata[key] = value;
    } else {
        [metadata removeObjectForKey:key];
    }
    _overrides = metadata;
}

- (NSDictionary *)serializableValueWithTopLevelData:
    (NSMutableDictionary *)data {
  NSMutableDictionary *event = [NSMutableDictionary dictionary];
  NSMutableDictionary *metaData = [[self metaData] mutableCopy];

  if (self.customException) {
      BSGDictSetSafeObject(event, @[self.customException], @"exceptions");
      BSGDictSetSafeObject(event,
                           [self serializeThreadsWithException:nil],
                           @"threads");
  } else {
      NSMutableDictionary *exception = [NSMutableDictionary dictionary];
      BSGDictSetSafeObject(exception, [self errorClass], @"errorClass");
      BSGDictInsertIfNotNil(exception, [self errorMessage], @"message");
      BSGDictInsertIfNotNil(exception, DEFAULT_EXCEPTION_TYPE, @"type");
      BSGDictSetSafeObject(event, @[exception], @"exceptions");

      // HACK: For the Unity Notifier. We don't include ObjectiveC exceptions or
      // threads
      // if this is an exception from Unity-land.
      NSDictionary *unityReport = metaData[@"_bugsnag_unity_exception"];
      if (unityReport) {
          BSGDictSetSafeObject(data, unityReport[@"notifier"], @"notifier");
          BSGDictSetSafeObject(exception, unityReport[@"stacktrace"], @"stacktrace");
          [metaData removeObjectForKey:@"_bugsnag_unity_exception"];
          return event;
      }

      BSGDictSetSafeObject(event,
                           [self serializeThreadsWithException:exception],
                           @"threads");
  }
  // Build Event
  BSGDictInsertIfNotNil(event, [self dsymUUID], @"dsymUUID");
  BSGDictSetSafeObject(event, BSGFormatSeverity(self.severity), @"severity");
  BSGDictSetSafeObject(event, [self breadcrumbs], @"breadcrumbs");
  BSGDictSetSafeObject(event, @"3", @"payloadVersion");
  BSGDictSetSafeObject(event, metaData, @"metaData");
  BSGDictSetSafeObject(event, [self deviceState], @"deviceState");
  BSGDictSetSafeObject(event, [self device], @"device");
  BSGDictSetSafeObject(event, [self appState], @"appState");
  BSGDictSetSafeObject(event, [self app], @"app");
  BSGDictSetSafeObject(event, [self context], @"context");
  BSGDictInsertIfNotNil(event, self.groupingHash, @"groupingHash");

  //  Inserted into `context` property
  [metaData removeObjectForKey:@"context"];
  // Build metadata
  BSGDictSetSafeObject(metaData, [self error], @"error");

  // Make user mutable and set the id if the user hasn't already
  NSMutableDictionary *user = [metaData[@"user"] mutableCopy];
  if (user == nil)
    user = [NSMutableDictionary dictionary];
  BSGDictSetSafeObject(metaData, user, @"user");

  if (!user[@"id"]) {
    BSGDictSetSafeObject(user, [self deviceAppHash], @"id");
  }

  return event;
}

// Build all stacktraces for threads and the error
- (NSArray *)serializeThreadsWithException:(NSMutableDictionary *)exception {
  NSMutableArray *bugsnagThreads = [NSMutableArray array];
  for (NSDictionary *thread in [self threads]) {
    NSArray *backtrace = thread[@"backtrace"][@"contents"];
    BOOL stackOverflow = [thread[@"stack"][@"overflow"] boolValue];

    if ([thread[@"crashed"] boolValue]) {
      NSUInteger seen = 0;
      NSMutableArray *stacktrace = [NSMutableArray array];

      for (NSDictionary *frame in backtrace) {
        NSMutableDictionary *mutableFrame = [frame mutableCopy];
        if (seen++ >= [self depth]) {
          // Mark the frame so we know where it came from
          if (seen == 1 && !stackOverflow) {
            BSGDictSetSafeObject(mutableFrame, @YES, @"isPC");
          }
          if (seen == 2 && !stackOverflow &&
              [@[ @"signal", @"deadlock", @"mach" ]
                  containsObject:[self errorType]]) {
            BSGDictSetSafeObject(mutableFrame, @YES, @"isLR");
          }
          BSGArrayInsertIfNotNil(
              stacktrace, BSGFormatFrame(mutableFrame, [self binaryImages]));
        }
      }

      BSGDictSetSafeObject(exception, stacktrace, @"stacktrace");
    } else {
      NSMutableArray *threadStack = [NSMutableArray array];

      for (NSDictionary *frame in backtrace) {
        BSGArrayInsertIfNotNil(threadStack,
                               BSGFormatFrame(frame, [self binaryImages]));
      }

      NSMutableDictionary *threadDict = [NSMutableDictionary dictionary];
      BSGDictSetSafeObject(threadDict, thread[@"index"], @"id");
      BSGDictSetSafeObject(threadDict, threadStack, @"stacktrace");
      BSGDictSetSafeObject(threadDict, DEFAULT_EXCEPTION_TYPE, @"type");
      // only if this is enabled in KSCrash.
      if (thread[@"name"]) {
        BSGDictSetSafeObject(threadDict, thread[@"name"], @"name");
      }

      BSGArrayAddSafeObject(bugsnagThreads, threadDict);
    }
  }
  return bugsnagThreads;
}

@end
