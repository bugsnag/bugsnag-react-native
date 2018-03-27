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
make ANDROID_VERSION=X IOS_VERSION=X upgrade_vendor
```

- Upgrade TypeScript definitions if the JavaScript has changed.

### Release Checklist

#### Pre-release

- [ ] Does the build pass on the CI server?
- [ ] Have the changelog and README been updated?
- [ ] Have all the version numbers been incremented?
- [ ] Has all new functionality been manually tested on a release build? Use `npm pack` to generate an artifact to install in a new app.
  - [ ] Ensure the example app sends the correct error for each type on iOS and Android
  - [ ] Archive the iOS app and validate the bundle type
  - [ ] Generate a signed APK for Android
- [ ] Do the installation instructions work when creating an example app from scratch?
- [ ] Have the installation instructions been updated on the [dashboard](https://github.com/bugsnag/bugsnag-website/tree/master/app/views/dashboard/projects/install) as well as the [docs site](https://github.com/bugsnag/docs.bugsnag.com)?

Note: the manual installation instructions for React Native are in a [separate section of the Docs](https://docs.bugsnag.com/platforms/react-native/manual-linking-guide/) and should also be updated if necessary.

#### Making the release

1. Update the changelog with new features and fixes. Any changes to the native interface requires a minor version bump.
2. Run `make VERSION=[number] release`
3. Create a new release on GitHub, copying the changelog entry.

#### Post-release

- [ ] Have all Docs PRs been merged?
- [ ] Can the latest release be installed via npm?
- [ ] Do the installation instructions work using the released artefact?
- [ ] Can a freshly created example app send an error report from a release build, using the released artefact?
- [ ] Do the existing example apps send an error report using the released artefact?
