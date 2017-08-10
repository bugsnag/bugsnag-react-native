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
   react-native run-ios
   ```

   or
   ```
   react-native run-android
   ```

