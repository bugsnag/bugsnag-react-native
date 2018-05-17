# Contributing

Thanks for stopping by! This document should cover most topics surrounding contributing to `bugsnag-react-native`.

* [How to contribute](#how-to-contribute)
  * [Reporting issues](#reporting-issues)
  * [Fixing issues](#fixing-issues)
  * [Adding features](#adding-features)
* [Building](#building)
* [Testing](#testing)


## Reporting issues

Are you having trouble getting started? Please [contact us directly](mailto:support@bugsnag.com) for assistance with integrating Bugsnag into your application.
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
