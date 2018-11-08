# Example integration with Android NDK

Includes a C module which has a function to cause a native crash.

Dependencies:

* Android Gradle Plugin 3.1.4
* Gradle 4.4
* bugsnag-react-native@2.12.3
* bugsnag-android-ndk@4.9.2
* bugsnag-android-gradle-plugin@3.5.0

## To Test

0. Add your Bugsnag API key to `android/app/src/main/AndroidManifest.xml`
1. Install the dependencies with `yarn install`
2. Run the app using `react-native run-android`
3. Press the button to break it
4. Relaunch the app to see a report on Bugsnag
