# Bugsnag+React Native+CodePush example

A sample application demonstrating using Bugsnag with React Native and CodePush.

## Usage

0. Run `npm install` (or `yarn install`)

1. Add your Bugsnag API key and Code Push deployment key to
   `ios/BugsnagReactNativeExample/Info.plist`:

   ```xml
    <key>CodePushDeploymentKey</key>
    <string>YOUR-DEPLOYMENT-KEY</string>
    <key>BugsnagAPIKey</key>
    <string>YOUR-BUGSNAG-API-KEY</string>
   ```

   and `android/app/src/main/AndroidManifest.xml`:

   ```xml
   <meta-data android:name="com.microsoft.codepush.DEPLOYMENT_KEY"
              android:value="YOUR-CODEPUSH-DEPLOYMENT-KEY" />
   <meta-data android:name="com.bugsnag.android.API_KEY"
              android:value="YOUR-BUGSNAG-API-KEY" />
   ```

2. Run the application, deploying new bundles as needed using
   `npm run release -- [version number]`. Feel free to customize and reuse the
   release script ([release.sh](release.sh)) to your needs.
