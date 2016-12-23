#import <Foundation/Foundation.h>

#import "RCTBridgeModule.h"

@interface BugsnagReactNative: NSObject <RCTBridgeModule>

- (void)startWithOptions:(NSDictionary *)options;
- (void)leaveBreadcrumb:(NSDictionary *)options;
- (void)notify:(NSDictionary *)payload;
- (void)setUser:(NSDictionary *)userInfo;
- (void)clearUser;

@end
