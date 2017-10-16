# Bugsnag, CocoaPods, and React Native together

Sample project demonstrating integrating Bugsnag into a project using React
Native via CocoaPods, where React Native is not the entry point of the entire
native application.

## Running this project

### Dependencies

* [CocoaPods](https://cocoapods.org)
* [npm](https://www.npmjs.com) or [yarn](https://yarnpkg.com/en/)
* [bugsnag-sourcemaps](https://github.com/bugsnag/bugsnag-sourcemaps)

### Setup

Install the dependencies via either `npm install` or `yarn install`, followed by
`pod install`.

Add your Bugsnag API key to Info.plist:

```
<key>BugsnagAPIKey</key>
<string>YOUR-API-KEY-HERE</string>
```

Start the packager:

```sh
npm run start
```

And then run the project from Xcode!

## Structure

* `Source/`: Native application files
* `app/`, `index.ios.js`: React Native components
* `package.json`, `yarn.lock`: JS module dependency management files
* `Podfile`, `Podfile.lock`: Native component dependency management files
* `.babelrc`: [Babel](https://babeljs.io) compilation settings

Pods depend on JS module components being installed, but are recommended to be
checked in to not require every team member to run `pod install` to run the
project.

## Steps taken to configure a basic project

### Creating a project with React Native from scratch
1. Create a new Xcode project
2. Create a package.json with empty contents (`{}`), then `yarn add --save` the
   following modules:
   * react-native
   * bugsnag-react-native
3. In order to compile React Native source, the React Native preset needs to be
   included in a .babelrc file in the root of the project:
   ```json
   {
     "presets": ["react-native"]
   }
   ```
4. Create a [Podfile](Podfile) requiring the libraries as frameworks in the
   Xcode project:

   ```ruby
   # React Native requirements
   pod 'yoga', path: './node_modules/react-native/ReactCommon/yoga'
   pod 'DoubleConversion', :podspec => './node_modules/react-native/third-party-podspecs/DoubleConversion.podspec'
   pod 'Folly', :podspec => './node_modules/react-native/third-party-podspecs/Folly.podspec'
   pod 'GLog', :podspec => './node_modules/react-native/third-party-podspecs/GLog.podspec'
   pod 'React', path: './node_modules/react-native', subspecs: [
     'Core',
     'jschelpers',
     'cxxreact',
     'CxxBridge',
     'DevSupport',
     'RCTText',
     'RCTImage',
     'RCTNetwork',
     'RCTActionSheet',
     'RCTAnimation',
     'RCTWebSocket',
   ]

   pod 'BugsnagReactNative', path: './node_modules/bugsnag-react-native'
   ```

   and run `pod install` to generate a workspace.
5. Create an entry point file for React Native components, I used `index.ios.js`
6. Open the workspace, add a view to a view controller to display the React
   Native component (I added a view called "ReactComponentView" to the main
   storyboard).

   Load the component when the view controller loads:

   ```objc
   #import <React/RCTBundleURLProvider.h>
   #import <React/RCTRootView.h>
   #import "ViewController.h"

   @interface ViewController ()
   @property (weak, nonatomic) IBOutlet UIView *reactComponentView;
   @end

   @implementation ViewController

   - (void)viewDidLoad {
        [super viewDidLoad];
        // The code location uses the entry point file name as the bundle root.
        // "index.ios.js" becomes "index.ios"
        NSURL *jsCodeLocation = [[RCTBundleURLProvider sharedSettings] jsBundleURLForBundleRoot:@"index.ios"
                                                                               fallbackResource:@"main"];
        RCTRootView *rootView = [[RCTRootView alloc] initWithBundleURL:jsCodeLocation
                                                            moduleName:@"BugsnagReactNativeExample"
                                                     initialProperties:nil
                                                         launchOptions:nil];
        [self.reactComponentView addSubview:rootView];
        rootView.frame = self.reactComponentView.bounds;
   }
   @end
   ```
7. Add an exception to localhost for App Transport Security settings requiring
   TLS in Info.plist. This allows the local packager to work:

   ```xml
   <key>NSAppTransportSecurity</key>
   <dict>
       <key>NSExceptionDomains</key>
       <dict>
           <key>localhost</key>
           <dict>
               <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
               <true/>
           </dict>
       </dict>
   </dict>
   ```
8. Run the React Native packager

   ```
   ./node_modules/react-native/scripts/packager.sh
   ```

   You can also add it to package.json to make it easier to find:

   ```json
   {
     "scripts": {
       "start": "./node_modules/react-native/scripts/packager.sh"
     }
   }
   ```
9. Start the app in Xcode to see your handiwork! Additional code and JS modules
   can then be added in the entry point or other files.

### Adding Bugsnag

1. Set your Bugsnag API key in Info.plist:

   ```xml
   <plist version="1.0">
   <dict>
     <key>BugsnagAPIKey</key>
     <string>YOUR-API-KEY-HERE</string>
   </dict>
   ```
2. Import BugsnagReactNative in the AppDelegate file:

   ```objc
   #import <BugsnagReactNative/BugsnagReactNative.h>
   ```

3. Start monitoring in `application:didFinishLaunchingWithOptions:`

   ```objc
   - (BOOL)application:(UIApplication *)application
     didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
      [BugsnagReactNative start];
      return YES;
   }
   ```

### Manually notifying of exceptions

To send a notification to Bugsnag manually, import Bugsnag and use the `notify:`
function:

```objc
#import <BugsnagReactNative/Bugsnag.h>

// ...

[Bugsnag notify:someException];
```

### Uploading source maps

React Native includes a script for creating a JavaScript bundle which can also
output a source map:

```
node ./node_modules/react-native/local-cli/cli.js bundle
```

This script can be shortened by adding an alias in package.json:

```json
{
  "scripts": {
    "bundle": "node ./node_modules/react-native/local-cli/cli.js bundle"
  }
}
```

At this point we can largely follow the instructions in the [Bugsnag React Native guide
for showing full stacktraces](https://docs.bugsnag.com/platforms/react-native/showing-full-stacktraces/)

Debug example:
```bash
npm run bundle -- \
  --platform ios \
  --entry-file index.ios.js \
  --dev true \
  --bundle-output ios-debug.bundle \
  --sourcemap-output ios-debug.bundle.map
```

Release example:
```bash
npm run bundle -- \
  --platform ios \
  --entry-file index.ios.js \
  --dev false \
  --bundle-output ios.bundle \
  --sourcemap-output ios.bundle.map
```

[bugsnag-sourcemaps](https://github.com/bugsnag/bugsnag-sourcemaps) can then be
used to upload the source map files:

```bash
bugsnag-sourcemaps upload \
  --api-key YOUR-API-KEY-HERE \
  --app-version YOUR-SHORT-BUNDLE-VERSION-STRING \
  --minified-file ios-debug.bundle \
  --source-map ios-debug.bundle.map \
  --minified-url "http://localhost:8081/index.ios.bundle?platform=ios&dev=true&minify=false"
```

Release example:
```bash
bugsnag-sourcemaps upload \
  --api-key YOUR-API-KEY-HERE \
  --app-version YOUR-SHORT-BUNDLE-VERSION-STRING \
  --minified-file ios.bundle \
  --source-map ios.bundle.map \
  --minified-url "main.jsbundle" \
  --upload-sources
```

This process can be automated by adding a Run Script build phase to your iOS
project to automatically upload source maps for Release builds. An example is
included in the project.
