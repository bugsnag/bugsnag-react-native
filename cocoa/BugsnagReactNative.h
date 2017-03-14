#import <Foundation/Foundation.h>

#import <React/RCTBridgeModule.h>

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
- (void)notify:(NSDictionary *)payload;
- (void)setUser:(NSDictionary *)userInfo;
- (void)clearUser;

@end
