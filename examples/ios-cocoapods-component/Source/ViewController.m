#import <React/RCTBundleURLProvider.h>
#import <React/RCTRootView.h>
#import <BugsnagReactNative/Bugsnag.h>
#import "ViewController.h"


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIView *reactComponentView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Load React Native component
    NSURL *jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index.ios"
                                                                           fallbackResource:@"main"];
    RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                        moduleName:@"BugsnagReactNativeExample"
                                                 initialProperties:nil
                                                     launchOptions:nil];
    [self.reactComponentView addSubview:rootView];
    rootView.frame = self.reactComponentView.bounds;
}

- (IBAction)triggerHandledException:(id)sender {
    NSException *exception = [NSException exceptionWithName:@"Handled exception!"
                                                     reason:@"An exception was instantiated and sent"
                                                   userInfo:nil];
    [Bugsnag notify:exception];
}

- (IBAction)triggerUnhandledException:(id)sender {
    [NSException raise:@"Exception raised!"
                format:@"Native exception raised from native component in React Native app"];
}

@end
