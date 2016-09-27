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

2. Run `npm install`

3. Run `react-native link`

### iOS Configuration

1. Run `./node_modules/.bin/bugsnag-vendor-deps` to install the native
   dependencies

2. Open the iOS project in `./ios`, and in the Project Navigator select
   BugsnagReactNative in Libraries, then:
   * Select the static library target
   * Select the Build Phases tab
   * Select the `+` under Link Binary with Libraries
   * Add `Bugsnag.framework` and `KSCrash.framework`

3. In the iOS project, select you app in the Project Navigator, then:
   * Select the Build Phases tab
   * Select the `+` under Link Binary with Libraries
   * Add `libz.tbd`

Once complete, start your project with either `react-native run-android` or
`react-native run-ios`.
