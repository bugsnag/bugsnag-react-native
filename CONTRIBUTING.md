# Contributing

* [Fork](https://help.github.com/articles/fork-a-repo) the
  [library on GitHub](https://github.com/bugsnag/bugsnag-react-native)
* Build and test your changes
* Commit and push until you are happy with your contribution
* [Make a pull request](https://help.github.com/articles/using-pull-requests)


## Building

bugsnag-react-native depends on
[bugsnag-android](https://github.com/bugsnag/bugsnag-android) and
[bugsnag-cocoa](https://github.com/bugsnag/bugsnag-cocoa) as well as React
Native itself for the headers and macros used in linking a native extension.
Because of these dependencies, it is easiest to hack on the library as a part of
an example project where all of these components are integrated.


## Running the examples app

Run `npm install`, then use `react-native run-android` or `react-native run-ios`
to run the example projects.

## Releasing

### Preflight testing

* Ensure the example app sends the correct error for each type on iOS and
  Android
* Archive the iOS app and validate the bundle

### Making a new release

1. Update the version number in package.json, android/build.gradle, and the
   README documentation badge.
2. Update the changelog with new features and fixes
3. Commit the changes and tag in the format `v[version]`. Push.
4. Publish the package to npm using `npm publish`.
5. Create a new release on GitHub, copying the changelog entry.
