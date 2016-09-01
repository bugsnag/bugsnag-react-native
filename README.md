# bugsnag-react-native

## Installation (dev mode)

1. Add `bugsnag-react-native` to your `package.json`:

   ```json
   {
     "dependencies": {
       "bugsnag-react-native": "../"
     }
   }
   ```

2. Run `npm install` and `npm link`

3. Add the library to `android/app/build.gradle`:

   ```groovy
   dependencies {
     compile project(':bugsnag-react-native')
   }
   ```

4. Link the library in `android/settings.gradle`:

   ```groovy
   include ':app'
   // must be after `include ':app'`

   include ':bugsnag-react-native'
   project(':bugsnag-react-native').projectDir = new File(rootProject.projectDir,
                                                          '../node_modules/bugsnag-react-native/android')
   ```

5. Add the library package to native packages listed in `android/{...}/MainActivity.java`:

   ```java
    protected List<ReactPackage> getPackages() {
        return Arrays.<ReactPackage>asList(
            new MainReactPackage(), BugsnagReactNative.getPackage()
        );
    }
   ```

6. Open `ios/[project].xcodeproj` and drag
   `node_modules/bugsnag-react-native/cocoa/BugsnagReactNative.xcodeproj` into
   the `Libraries` group, alongside ReactNative and other dependencies.

7. Select the `BugsnagReactNative` project in `Libraries`, and open `Build
   Settings`. Find the "Header Search Paths" setting and add
   `$(SRCROOT)/../../react-native/React` and change "non-recursive" to
   "recursive".

8. Close the Xcode project

9. Open or create and edit `ios/Podfile` and add the Bugsnag Cocoa library to
   the BugsnagReactNative target as well as your app target:

   ```ruby
   source 'https://github.com/CocoaPods/Specs'

   workspace '{your project name}.xcworkspace'

   target '{your project}' do
     pod 'Bugsnag'
   end

   target 'BugsnagReactNative' do
     project '../node_modules/bugsnag-react-native/cocoa/BugsnagReactNative.xcodeproj'
     pod 'Bugsnag'
   end
   ```

10. Run `pod install` within the `ios` directory

11. Run your project with either `react-native run-android` or
    `react-native run-ios`
