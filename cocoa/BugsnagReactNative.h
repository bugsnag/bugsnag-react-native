#import <Foundation/Foundation.h>

#import <React/RCTBridgeModule.h>

#if __has_include(<React/RCTBridge.h>)
// React Native >= 0.40
#import <React/RCTBridge.h>
#else
// React Native <= 0.39
#import "RCTBridge.h"
#endif

@class BugsnagConfiguration;

@interface BugsnagReactNative: NSObject <RCTBridgeModule>

/**
 * Initializes the crash handler with the default options and using the API key
 * stored in the Info.plist using the key "BugsnagAPIKey"
 */
+ (void)start;
/**
 * Initializes the crash handler with the default options
 * @param APIKey the API key to use when sending error reports
 */
+ (void)startWithAPIKey:(NSString *)APIKey;
/**
 * Initializes the crash handler with custom options
 * @param config the configuration options to use
 */
+ (void)startWithConfiguration:(BugsnagConfiguration *)config;

- (void)startWithOptions:(NSDictionary *)options;
- (void)leaveBreadcrumb:(NSDictionary *)options;
- (void)notify:(NSDictionary *)payload
       resolve:(RCTPromiseResolveBlock)resolve
        reject:(RCTPromiseRejectBlock)reject;
- (void)setUser:(NSDictionary *)userInfo;
- (void)clearUser;
- (void)startSession;
- (void)stopSession;
- (void)resumeSession;

@end
