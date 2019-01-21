# Bugsnag React Native Example
A robust example of how to make best use of the Bugsnag React Native notifier.

## Demonstrates

- [Extracting common configuration for multiple files and environments](app/lib)
- [Identifying users](app/components/scenes/register.js#L47-50)
- [Handling rejected promises](app/lib/github.js#L26)
- [Logging Handled exceptions](app/index.js#L52)
- Using breadcrumbs
  - [Navigation](app/index.js#L77)
  - [Submitting forms](app/components/scenes/register.js#L38-L42)
  - [Network requests](app/lib/github.js#L34)

## Setup

1. Install dependencies
   with npm
   ```
   npm install
   ```
   or with [yarn](https://yarnpkg.com)
   ```
   yarn
   ```

1. [Create a bugsnag account](https://app.bugsnag.com/user/new) and create
   a react native project.

1. Add your project api key to [android/app/src/main/AndroidManifest.xml](android/app/src/main/AndroidManifest.xml#L30-L31):

   ```xml
      <meta-data android:name="com.bugsnag.android.API_KEY"
                 android:value="YOUR-API-KEY-HERE" />
   ```

   and [ios/BugsnagReactNativeExample/Info.plist](ios/BugsnagReactNativeExample/Info.plist#L4-L5):

   ```xml
    <key>BugsnagAPIKey</key>
    <string>YOUR-API-KEY-HERE</string>
   ```

   The API key can be found in the the bugsnag settings for your project.

1. Run the app
   ```
   react-native run-ios --configuration Release
   ```

   or
   ```
   react-native run-android --variant=release
   ```

## Deobfuscating stacktraces

This app provides working examples of how to deobfuscate stacktraces for JS, Android, and iOS. For further information, please consult [our React Native documentation](https://docs.bugsnag.com/platforms/react-native/showing-full-stacktraces/).

### JavaScript

You will need to upload source maps to Bugsnag in order to deobfuscate JavaScript stack traces. Example scripts for achieving this on Android/iOS in both debug and release builds can be found [here](scripts). The example scripts use [bugsnag-sourcemaps](https://github.com/bugsnag/bugsnag-sourcemaps), which is installed as a dev dependency of the project. The scripts can also be invoked in this example project using [npm run](https://docs.npmjs.com/cli/run-script.html):

```bash
npm run upload-sourcemaps:debug:android
npm run upload-sourcemaps:debug:ios
npm run upload-sourcemaps:release:android
npm run upload-sourcemaps:release:ios
```

Please note that if you use Code Push, you should specify `codeBundleId` in your JS configuration, and use that as the value of `app-version` instead. See [the docs](https://docs.bugsnag.com/platforms/react-native/showing-full-stacktraces) for further detail.

Note: recent versions of React Native have an [issue](https://github.com/facebook/react-native/issues/6946#issuecomment-405525464) which may result in the failure to apply source maps or incorrect line numbers being mapped.

### Android

The [Bugsnag Gradle Plugin](https://docs.bugsnag.com/build-integrations/gradle/) will automatically upload all the necessary mapping files when `react-native run-android --variant=release` is invoked.

ProGuard mapping files can also be uploaded manually in this example project by using [npm run](https://docs.npmjs.com/cli/run-script.html):

```bash
npm run upload-proguard:release:android
```

### iOS

If Bitcode is enabled in your project, you will first need to download your dSYMs from XCode or iTunes Connect, then upload them by using our fastlane plugin or bugsnag-dsym-upload. A working example of this can be found [here](ios/upload-react-native-dsyms.sh). The example script requires the installation of [bugsnag-dsym-upload](https://github.com/bugsnag/bugsnag-dsym-upload) to work, and can be invoked using [npm run](https://docs.npmjs.com/cli/run-script.html):

```bash
npm run upload-dsyms:release:ios
```


If you are not using Bitcode, you can use our Fastlane or Cocoapods integrations, or add a manual Build phase to upload the dSYMs.

Read the [iOS symbolication guide](https://docs.bugsnag.com/platforms/ios/symbolication-guide) for further details.