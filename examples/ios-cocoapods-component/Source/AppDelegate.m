#import "AppDelegate.h"
#import <BugsnagReactNative/BugsnagReactNative.h>

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [BugsnagReactNative start];
    return YES;
}

@end
