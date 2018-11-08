# Contributing

Thanks for stopping by! This document should cover most topics surrounding contributing to `bugsnag-react-native`.

* [How to contribute](#how-to-contribute)
  * [Reporting issues](#reporting-issues)
  * [Fixing issues](#fixing-issues)
  * [Adding features](#adding-features)
* [Building](#building)
* [Testing](#testing)


## Reporting issues

Are you having trouble getting started? Please [contact us directly](mailto:support@bugsnag.com?subject=%5BGitHub%5D%20React%20Native%20-%20having%20trouble%20getting%20started%20with%20Bugsnag&body=Description%3A%0A%0A%28Add%20a%20description%20here%2C%20and%20fill%20in%20your%20environment%20below%3A%29%0A%0A%0AEnvironment%3A%0A%0A%0APaste%20the%20output%20of%20this%20command%20into%20the%20code%20block%20below%20%28use%20%60npm%20ls%60%20instead%0Aof%20%60yarn%20list%60%20if%20you%20are%20using%20npm%29%3A%0A%0A%60%60%60%0Ayarn%20list%20react-native%20bugsnag-react-native%20react-native-code-push%0A%60%60%60%0A%0A-%20cocoapods%20version%20%28if%20any%29%20%28%60pod%20-v%60%29%3A%0A-%20iOS/Android%20version%28s%29%3A%0A-%20simulator/emulator%20or%20physical%20device%3F%3A%0A-%20debug%20mode%20or%20production%3F%3A%0A%0A-%20%5B%20%5D%20%28iOS%20only%29%20%60%5BBugsnagReactNative%20start%5D%60%20is%20present%20in%20the%0A%20%20%60application%3AdidFinishLaunchingWithOptions%3A%60%20method%20in%20your%20%60AppDelegate%60%0A%20%20class%3F%0A-%20%5B%20%5D%20%28Android%20only%29%20%60BugsnagReactNative.start%28this%29%60%20is%20present%20in%20the%0A%20%20%60onCreate%60%20method%20of%20your%20%60MainApplication%60%20class%3F) for assistance with integrating Bugsnag into your application.
If you have spotted a problem with this module, feel free to open a [new issue](https://github.com/bugsnag/bugsnag-react-native/issues/new?template=Bug_report.md). Here are a few things to check before doing so:

* Are you using the latest version of `bugsnag-react-native`? If not, does updating to the latest version fix your issue?
* Has somebody else [already reported](https://github.com/bugsnag/bugsnag-react-native/issues?utf8=%E2%9C%93&q=is%3Aissue%20is%3Aopen) your issue? Feel free to add additional context to or check-in on an existing issue that matches your own.
* Is your issue caused by this module? Only things related to the `bugsnag-react-native` module should be reported here. For anything else, please [contact us directly](mailto:support@bugsnag.com) and we'd be happy to help you out.

### Fixing issues

If you've identified a fix to a new or existing issue, we welcome contributions!
Here are some helpful suggestions on contributing that help us merge your PR quickly and smoothly:

* [Fork](https://help.github.com/articles/fork-a-repo) the
  [library on GitHub](https://github.com/bugsnag/bugsnag-react-native)
* Build and test your changes. We have automated tests for many scenarios but its also helpful to use `npm pack` to build the module locally and install it in a real app.
* Commit and push until you are happy with your contribution
* [Make a pull request](https://help.github.com/articles/using-pull-requests)
* Ensure the automated checks pass (and if it fails, please try to address the cause)

### Adding features

Unfortunately we’re unable to accept PRs that add features or refactor the library at this time.
However, we’re very eager and welcome to hearing feedback about the library so please contact us directly to discuss your idea, or open a
[feature request](https://github.com/bugsnag/bugsnag-react-native/issues/new?template=Feature_request.md) to help us improve the library.

Here’s a bit about our process designing and building the Bugsnag libraries:

* We have an internal roadmap to plan out the features we build, and sometimes we will already be planning your suggested feature!
* Our open source libraries span many languages and frameworks so we strive to ensure they are idiomatic on the given platform, but also consistent in terminology between platforms. That way the core concepts are familiar whether you adopt Bugsnag for one platform or many.
* Finally, one of our goals is to ensure our libraries work reliably, even in crashy, multi-threaded environments. Oftentimes, this requires an intensive engineering design and code review process that adheres to our style and linting guidelines.


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

If you wish to run in release mode, specify `--configuration Release` for iOS, or `--variant=release` for Android.

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
  - [ ] Install on Android/iOS in an app running the latest version of RN
  - [ ] Install on Android/iOS in an app < 0.56
  - [ ] Ensure the example app sends the correct error for each type on iOS and Android
  - [ ] Archive the iOS app and validate the bundle type
  - [ ] Generate a signed APK for Android
- [ ] On a throttled network, is the request timeout reasonable, and the main thread not blocked by any visible UI freeze? (Throttling can be achieved by setting both endpoints to "https://httpstat.us/200?sleep=5000")
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
- [ ] *If bugsnag-android has been updated,* update the exact version number of
      bugsnag-android-ndk to use in the "enhanced native integration" guide.
