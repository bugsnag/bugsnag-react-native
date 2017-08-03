Changelog
=========

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
