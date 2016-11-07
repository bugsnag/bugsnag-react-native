Changelog
=========

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

* Fix double-reporting of unhandled JavaScript exceptions on iOS when in
  production
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

