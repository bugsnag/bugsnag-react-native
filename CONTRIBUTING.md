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

## Testing

Unit tests for the JavaScript client are run with [Jest](https://facebook.github.io/jest/).

```sh
npm i
npm run test:unit:js
```

Code coverage is reported in the `./coverage` directory. On a Mac, the following command
will open the coverage report in your default browser:

```sh
open coverage/lcov-report/index.html
```

## Running the examples app

Run `npm install`, then use `react-native run-android` or `react-native run-ios`
to run the example projects.

## Releasing

### Upgrading the vendored libraries

To upgrade bugsnag-cocoa, prepare an updated version of bugsnag-cocoa, then copy
the Source and iOS directories. Assuming bugsnag-cocoa is located in the same
directory as bugsnag-react-native:

```
cp -r ../bugsnag-cocoa/Source/* cocoa/vendor/bugsnag-cocoa/Source
cp -r ../bugsnag-cocoa/iOS/* cocoa/vendor/bugsnag-cocoa/iOS
```

### Release Checklist
Please follow the testing instructions in [the platforms release checklist](https://github.com/bugsnag/platforms-release-checklist/blob/master/README.md), and any additional steps directly below.

* Ensure the example app sends the correct error for each type on iOS and
  Android
* Archive the iOS app and validate the bundle
* Generate a signed APK for Android

### Making a new release

1. Update the version number by running `make VERSION=[number] bump`
2. Update the changelog with new features and fixes
3. Commit the changes and tag in the format `v[version]`. Push.
4. Publish the package to npm using `npm publish`.
5. Create a new release on GitHub, copying the changelog entry.
