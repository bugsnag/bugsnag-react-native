Changelog
=========

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

