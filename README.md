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

