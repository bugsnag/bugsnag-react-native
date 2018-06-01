Changelog
=========

## 2.9.5 (2018-05-31)

### Bug fixes

* (android) Upgrade bugsnag-android dependency to v4.4.1:
  * Refine automatically collected breadcrumbs to a commonly useful set by default
    [bugsnag-android#321](https://github.com/bugsnag/bugsnag-android/pull/321)
  * Ensure that unhandled error reports are always sent immediately on launch for Android P and in situations with no connectivity.
    [bugsnag-android#319](https://github.com/bugsnag/bugsnag-android/pull/319)

* (iOS) Upgrade bugsnag-cocoa dependency to v5.15.6:
  * Ensure device data is attached to minimal reports
    [bugsnag-cocoa#279](https://github.com/bugsnag/bugsnag-cocoa/pull/279)
  * Enforce requiring API key to initialise notifier
    [bugsnag-cocoa#280](https://github.com/bugsnag/bugsnag-cocoa/pull/280)


## 2.9.4 (2018-05-02)

* Enable nativeSerializer to handle Error objects by extracting the stack and message from a given Error class before serialising it. [#239](https://github.com/bugsnag/bugsnag-react-native/issues/239) [#240](https://github.com/bugsnag/bugsnag-react-native/pull/240) [daisy1754](https://github.com/daisy1754) [Cawllec](https://github.com/Cawllec)

* Upgrade bugsnag-android to v4.3.4:
  - *Bug Fixes:*
    - Avoid adding extra comma separator in JSON if File input is empty or null [#284](https://github.com/bugsnag/bugsnag-android/pull/284)
    - Thread safety fixes to JSON file serialisation [#295](https://github.com/bugsnag/bugsnag-android/pull/295)
    - Prevent potential automatic activity lifecycle breadcrumb crash [#300](https://github.com/bugsnag/bugsnag-android/pull/300)
    - Fix serialisation issue with leading to incorrect dashboard display of breadcrumbs [#306](https://github.com/bugsnag/bugsnag-android/pull/306)
    - Prevent duplicate reports being delivered in low connectivity situations [#270](https://github.com/bugsnag/bugsnag-android/pull/270)
    - Fix possible NPE when reading default metadata filters [#263](https://github.com/bugsnag/bugsnag-android/pull/263)
    - Prevent ConcurrentModificationException in Before notify/breadcrumb callbacks [#266](https://github.com/bugsnag/bugsnag-android/pull/266)
    - Ensure that exception message is never null [#256](https://github.com/bugsnag/bugsnag-android/pull/256)
    - Add payload version to JSON body [#244](https://github.com/bugsnag/bugsnag-android/pull/244)
    - Update context tracking to use lifecycle callbacks rather than ActivityManager [#238](https://github.com/bugsnag/bugsnag-android/pull/238)
  - *Enhancements:*
    - Detect whether running on emulator [#245](https://github.com/bugsnag/bugsnag-android/pull/245)
    - Add a callback for filtering breadcrumbs [#237](https://github.com/bugsnag/bugsnag-android/pull/237)
* Upgrade bugsnag-cocoa to v5.15.5:
  - *Bug Fixes:*
    - Changes report generation so that when a minimal or incomplete crash is recorded, essential app/device information is included in the report on the next application launch. [#239](https://github.com/bugsnag/bugsnag-cocoa/pull/239)
  [#250](https://github.com/bugsnag/bugsnag-cocoa/pull/250)
    - Ensure timezone is serialised in report payload.
  [#248](https://github.com/bugsnag/bugsnag-cocoa/pull/248)
    - Ensure error class and message are persisted when thread tracing is disabled [#245](https://github.com/bugsnag/bugsnag-cocoa/pull/245)
    - Re-addapp name to the app tab of reports [#244](https://github.com/bugsnag/bugsnag-cocoa/pull/244)
    - Add payload version to report body to preserve backwards compatibility with older versions of the error reporting API [#241](https://github.com/bugsnag/bugsnag-cocoa/pull/241)
  - *Enhancements:*
    -This release adds additional device metadata for filtering by whether an error occurred in a simulator ([#242](https://github.com/bugsnag/bugsnag-cocoa/pull/242)) and by processor word size ([#228](https://github.com/bugsnag/bugsnag-cocoa/pull/228)).

## 2.9.3 (2018-03-16)

### Bug Fixes

* Add NativeSerializer to packaging step [#227](https://github.com/bugsnag/bugsnag-react-native/pull/227)
[Ben Gourley](https://github.com/bengourley)

## 2.9.2 (2018-03-15)

* Add standardJS linter [#223](https://github.com/bugsnag/bugsnag-react-native/pull/223) [Ben Gourley](https://github.com/bengourley)
* Rework construction of breadcrumbMetaData [224](https://github.com/bugsnag/bugsnag-react-native/pull/224) [bramus](https://github.com/bramus)
* Refactor(typedMap): Extract and rename typedMap function into NativeSerializer module [#225](https://github.com/bugsnag/bugsnag-react-native/pull/225) [Ben Gourley](https://github.com/bengourley)
* Loosen react native dependency version for Android [#220](https://github.com/bugsnag/bugsnag-react-native/pull/220) [Jamie Lynch](https://github.com/fractalwrench)


## 2.9.1 (2018-01-29)

- Adds missing bundle ID in iOS example project
- Fixes missing parameter in Android initialisation

## 2.9.0 (2018-01-26)

This release includes features and fixes to the native interface.

### Enhancements

* Allow disabling of breadcrumbs via the `Configuration` object via the JS
  interface
* Upgrade bugsnag-android to v4.3.1:
  - *Enhancements:*
    - Move capture of thread stacktraces to start of notify process
    - Add configuration option to disable automatic breadcrumb capture
    - Parse manifest meta-data for Session Auto-Capture boolean flag
  - *Bug Fixes:*
    - Fix possible ANR when enabling session tracking via
      `Bugsnag.setAutoCaptureSessions()` and connecting to latent networks.
      [#231](https://github.com/bugsnag/bugsnag-android/pull/231)
    - Fix invalid payloads being sent when processing multiple Bugsnag events
      in the same millisecond
      [#235](https://github.com/bugsnag/bugsnag-android/pull/235)
    - Re-add API key to error report HTTP request body to preserve backwards
      compatibility with older versions of the error reporting API
      [#228](https://github.com/bugsnag/bugsnag-android/pull/228)-
* Upgrade bugsnag-cocoa to v5.15.3:
  - *Bug Fixes:*
    - Remove chatty logging from session tracking
      [#231](https://github.com/bugsnag/bugsnag-cocoa/pull/231)
      [Jamie Lynch](https://github.com/fractalwrench)
    - Re-add API key to payload body to preserve backwards compatibility with older
      versions of the error reporting API
      [#232](https://github.com/bugsnag/bugsnag-cocoa/pull/232)
      [Jamie Lynch](https://github.com/fractalwrench)
    - Fix crash in iPhone X Simulator when reporting user exceptions
      [#234](https://github.com/bugsnag/bugsnag-cocoa/pull/234)
      [Paul Zabelin](https://github.com/paulz)
    - Improve capture of Swift assertion error messages on arm64 devices, inserting
      the assertion type into the report's `errorClass`
      [#235](https://github.com/bugsnag/bugsnag-cocoa/pull/235)
    - Fix default user/device ID generation on iOS devices
    - Fix mach exception detection

## 2.8.0 (2018-01-09)

### Enhancements

* Add support for tracking app sessions and enabling overall crash rate metrics

### Bug Fixes

* Fix issue where breadcrumb functions are called before initialization
  [bugsnag-android#211](https://github.com/bugsnag/bugsnag-android/pull/211)

## 2.7.5 (2017-11-30)

### Bug Fixes

* (iOS - CocoaPods only) Fix ambiguous headers issue in 2.7.3+
* (iOS) Fix intermittent dropped native crash reports due to parsing runtime
  options incorrectly

## 2.7.4 (2017-11-30)
* (iOS) Fix encoding of control characters in crash reports. Ensures crash reports are written correctly and delivered when containing U+0000 - U+001F

## 2.7.3 (2017-11-23)

* (iOS) Use `BSG_KSCrashReportWriter` header rather than `KSCrashReportWriter` for custom JSON serialization
* (Android) Enqueue activity lifecycle events when initialisation not complete to prevent NPE

## 2.7.2 (2017-11-21)

* (iOS) Remove misleading information (address, mach, signal) from non-fatal error reports

## 2.7.1 (2017-11-20)

* Improved validation of handled/unhandled state

## 2.7.0 (2017-11-16)

* Add typescript definitions

## 2.6.1 (2017-11-14)

* Fix duplicate dependencies key in `package.json`
* Handle null in console breadcrumbs

## 2.6.0 (2017-11-07)

#### IMPORTANT UPGRADE NOTE:
Please ensure that Google's maven repository is specified in your `android/build.gradle`:

```
allprojects {
    repositories {
        maven { url 'https://maven.google.com' }
    }
}
```

* (Android) Compile annotations dependency as api rather than implementation
* (Android) [Support missing case in handled/unhandled tracker](https://github.com/bugsnag/bugsnag-android/pull/208)


## 2.5.4 (2017-11-06)

* Update Cocoa code to fix archive issue on older versions of XCode

## 2.5.3 (2017-11-02)

* Updates native libraries to include latest fixes

## 2.5.2 (2017-11-02)

* Support setting `autoNotify` to disable native crash reporting

## 2.5.1 (2017-10-26)

* Replace PropTypes from React with prop-types package
* Adds example project which uses react native via cocoapods

## 2.5.0 (2017-10-09)

### Enhancements

* Add configuration option to enable capturing console log messages as
  breadcrumbs
  [#159](https://github.com/bugsnag/bugsnag-react-native/pull/159)
  [Ben Gourley](https://github.com/bengourley)

### Bug fixes

* [android] Reuse previously configured Bugsnag native client if available
  [#156](https://github.com/bugsnag/bugsnag-react-native/pull/156)

## 2.4.2 (2017-10-04)
* Fix duplicate symbols in KSCrash when Sentry library included in project

## 2.4.1 (2017-10-03)
* Link Native Cocoa as a static library

## 2.4.0 (2017-10-02)
* Track whether errors are handled or unhandled
* Reduce build warning count

## 2.3.2 (2017-08-18)

### Bug fixes

* Fix regression introduced in 2.3.0 where nested JavaScript objects were being
  serialized incorrectly before being sent to Bugsnag
  [#132](https://github.com/bugsnag/bugsnag-react-native/issues/132)
  [#133](https://github.com/bugsnag/bugsnag-react-native/issues/133)

## 2.3.1 (2017-08-10)

### Bug fixes

* Fix codeBundleId being unset in unhandled exceptions when using CodePush 2+
  [#127](https://github.com/bugsnag/bugsnag-react-native/issues/127)
  [#128](https://github.com/bugsnag/bugsnag-react-native/issues/128)

## 2.3.0 (2017-08-02)

### Enhancements

* Add compatibility for React Native 0.47
  [Jamie Lynch](https://github.com/fractalwrench)
  [#120](https://github.com/bugsnag/bugsnag-react-native/pull/120)

* Make index.js ES2015-compatible
  [Rubén Sospedra](https://github.com/sospedra)
  [#104](https://github.com/bugsnag/bugsnag-react-native/pull/104)

### Bug fixes

* Call previous exception handler when `notify` is cancelled by a callback
  [#106](https://github.com/bugsnag/bugsnag-react-native/issues/106)

* Stringify NaN in breadcrumb metadata before sending over native bridge to
  avoid fatal error
  [#107](https://github.com/bugsnag/bugsnag-react-native/issues/107)

## 2.2.4 (2017-07-14)

### Bug fixes

* Copy breadcrumb data to avoid mutation
  [Jakob Kerkhove](https://github.com/dejakob)
  [#101](https://github.com/bugsnag/bugsnag-react-native/pull/101)
* Tweak podspec to work around missing public headers issue
  [Jonathan Sibley](https://github.com/sibljon)
  [#116](https://github.com/bugsnag/bugsnag-react-native/pull/116)

## 2.2.3 (2017-04-27)

### Bug fixes

* Fix regression where iOS headers are copied into an incorrect location
  [#98](https://github.com/bugsnag/bugsnag-react-native/issues/98)


## 2.2.2 (2017-04-26)

### Bug fixes

* Restore missing `android/src` directory to package
  [#96](https://github.com/bugsnag/bugsnag-react-native/issues/96)

## 2.2.1 (2017-04-25)

* Generates `lib/Bugsnag.js` to improve compatibility with tooling which does
  not transpile source files from `node_modules`, like haul and testing tools
* Adds a warning when using breadcrumb names which will be truncated

### Bug fixes

* Reorder the header files in the podspec, to work around skipped files
  [#92](https://github.com/bugsnag/bugsnag-react-native/issues/92)

## 2.2.0 (2017-03-15)

### Enhancements
* Add convenience interface to setting up native-only error handling

## 2.1.0 (2017-02-28)

### Enhancements
* Adds `codeBundleId` property as an alternative to appVersion to support CodePush
  [#74](https://github.com/bugsnag/bugsnag-react-native/pull/74)
* Add original error to report object
  [#61](https://github.com/bugsnag/bugsnag-react-native/pull/61)

### Bug fixes
* [android] Check each param before setting user
  [#73](https://github.com/bugsnag/bugsnag-react-native/issues/73)

## 2.0.3 (2017-02-14)

### Bug fixes
* Change react-native dependency to allow for versions past 0.40
  [#71](https://github.com/bugsnag/bugsnag-react-native/pull/71)
  [Michael Patricios](https://github.com/mpatric)
* Conventionalize to fix sneaky breadcrumb logging bugs
  [#56](https://github.com/bugsnag/bugsnag-react-native/pull/56)
  [Kevin Cooper](https://github.com/cooperka)

## 2.0.2 (2017-01-13)

### Bug fixes

* [ios] Fix regression where previous exception handler is not called

## 2.0.1 (2017-01-12)

### Bug fixes

* Upgrade bugsnag-android dependency to fix issue with network requests being
  sent on the main thread

## 2.0.0 (2017-01-11)

*  Updated to support react native 0.40.0
   [#60](https://github.com/bugsnag/bugsnag-react-native/pull/60)
   [Henrik Raitasola](https://github.com/henrikra)

## 1.2.2 (2017-01-06)

### Bug fixes

* [ios] Prevent discarding native exceptions invoked over JS bridge
  [fac66b9](https://github.com/bugsnag/bugsnag-react-native/commit/fac66b9e1675982f60049de8103933c975c69738)

## 1.2.1 (2016-12-30)

### Bug fixes

* [ios] Fix failed call to `notifyBlocking`
  [#54](https://github.com/bugsnag/bugsnag-react-native/pulls/54)
  [Libin Lu](https://github.com/evollu)

* [ios] Update spec installation to separate vendored files
  [#55](https://github.com/bugsnag/bugsnag-react-native/pulls/55)
  [Eugene Sokovikov](https://github.com/skv-headless)

## 1.2.0 (2016-12-23)

### Enhancements

* Add `clearUser` to the `Client`. Clear user removes any custom user data
  from the report and adds the default device identifier
  [#51](https://github.com/bugsnag/bugsnag-react-native/pulls/51)

### Bug fixes

* [ios] Fix stripping of source paths for release builds
  [#35](https://github.com/bugsnag/bugsnag-react-native/issues/35)
  [#52](https://github.com/bugsnag/bugsnag-react-native/pulls/52)

* [android] Ensure unhandled errors are sent as blocking requests
  [#46](https://github.com/bugsnag/bugsnag-react-native/issues/46)
  [#47](https://github.com/bugsnag/bugsnag-react-native/issues/47)

## 1.1.4 (2016-12-08)

### Bug fixes

* Fix breadcrumbs being discarded when metadata is unable to be used
  [#36](https://github.com/bugsnag/bugsnag-react-native/issues/36)
* Fix object metadata being discarded from reports
  [#36](https://github.com/bugsnag/bugsnag-react-native/issues/36)
* Fix non-String breadcrumb metadata being incorrectly parsed on Android
  [#33](https://github.com/bugsnag/bugsnag-react-native/pull/33)
  [Kevin Cooper](https://github.com/cooperka)
* Add promise as an explicit dependency
  [#40](https://github.com/bugsnag/bugsnag-react-native/pull/40)
  [Christian Schlensker](https://github.com/wordofchristian)
* Fix username and email fields of `setUser` being reversed on Android
  [#38](https://github.com/bugsnag/bugsnag-react-native/issues/38)


## 1.1.3 (2016-11-14)

### Enhancements

* ES6 Code cleanup
  [Shadi](https://github.com/TheSisb)
  [#23](https://github.com/bugsnag/bugsnag-react-native/pull/23)

### Bug fixes

* Fix default error handling fallback when initializing Bugsnag early in app
  cycle
  [Christian Schlensker](https://github.com/wordofchristian)
  [#26](https://github.com/bugsnag/bugsnag-react-native/pull/26)
* Fix double-reporting of unhandled JavaScript exceptions on iOS when in
  production

## 1.1.2 (2016-11-08)

### Bug fixes

* Adjust header copy phase and search paths for iOS dependencies to ensure no
  additional content is created in the root of archived projects
  [#18](https://github.com/bugsnag/bugsnag-react-native/issues/18)

## 1.1.1 (2016-11-07)

### Miscellaneous

* Lower deployment target of embedded BugsnagLib to iOS 8.0
* Update project settings to recommended configuration for Xcode 8
* Check in missing Xcode scheme for libBugsnag

## 1.1.0 (2016-11-07)

### Enhancements

* Reports unhandled promise rejections. By default, unhandled promise rejections
  are reported to Bugsnag when in a non-development environment. This is
  disabled in a development environment to preserve the existing behavior of
  showing a warning banner when a possible unhandled promise rejection is
  detected.To toggle this behavior, set `handlePromiseRejections` when creating
  a client.
* Allow setting `appVersion` from a configuration option. This will override the
  default of using the version specified in the app's Info.plist or android
  manifest.
* Update bugsnag-cocoa dependency to 5.6.4, which adds support for more robust
  native client-side report customization through callbacks

### Bug fixes

* Fix failure to invoke reporting callbacks
  [Sam Aryasa](https://github.com/sbycrosz)
  [#22](https://github.com/bugsnag/bugsnag-react-native/pull/22)
* Fix syntax error in release stage filtering
  [Sam Aryasa](https://github.com/sbycrosz)
  [#22](https://github.com/bugsnag/bugsnag-react-native/pull/22)


## 1.0.4

### Bug fixes

* Warn when discarding input to `Client.notify()` which is not an error
  [Duncan Hewett](https://github.com/duncanhewett)
* [ios] Update the linker configuration to reduce product candidates during
  `react-native link`
* [ios] Remove duplicate entries in payload notifier version

## 1.0.3

Fix the import path for Bugsnag on Android

## 1.0.2

Fix the minimum Android SDK version to be consistent with React Native

## 1.0.1

Vendor iOS dependencies. Current version is 5.6.3.

## 1.0.0

First public release
