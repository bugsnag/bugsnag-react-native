# Bugsnag error monitoring & exception reporter for React Native
[![Documentation](https://img.shields.io/badge/documentation-2.23.1-blue.svg)](http://docs.bugsnag.com/platforms/react-native/)

Automatic [React Native crash reporting](https://www.bugsnag.com/platforms/react-native-error-reporting/) with Bugsnag helps you detect both native OS and JavaScript errors in your React Native apps.

## Features

* Automatically report unhandled exceptions and crashes
* Show full stacktraces with [source map integration](https://docs.bugsnag.com/platforms/react-native/showing-full-stacktraces)
* Report [handled exceptions](https://docs.bugsnag.com/platforms/react-native/#reporting-handled-exceptions)
* [Log breadcrumbs](https://docs.bugsnag.com/platforms/react-native/#logging-breadcrumbs) which are attached to crash reports and add insight to users' actions
* [Attach user information](https://docs.bugsnag.com/platforms/react-native/#identifying-users) to determine how many people are affected by a crash


## Getting started

1. [Create a Bugsnag account](https://www.bugsnag.com)
1. Complete the instructions in the [integration guide](https://docs.bugsnag.com/platforms/react-native) to report unhandled exceptions thrown from your app
1. Report handled exceptions using [`Client.notify()`](https://docs.bugsnag.com/platforms/react-native/#reporting-handled-errors)
1. Customize your integration using the [configuration options](https://docs.bugsnag.com/platforms/react-native/configuration-options/)


## Support

* [Read the integration guide](https://docs.bugsnag.com/platforms/react-native/) or [configuration options documentation](https://docs.bugsnag.com/platforms/react-native/configuration-options/)
* [Search open and closed issues](https://github.com/bugsnag/bugsnag-react-native/issues?utf8=✓&q=is%3Aissue) for similar problems
* Having trouble getting started? Please [contact support](mailto:support@bugsnag.com?subject=%5BGitHub%5D%20React%20Native%20-%20having%20trouble%20getting%20started%20with%20Bugsnag&body=Description%3A%0A%0A%28Add%20a%20description%20here%2C%20and%20fill%20in%20your%20environment%20below%3A%29%0A%0A%0AEnvironment%3A%0A%0A%0APaste%20the%20output%20of%20this%20command%20into%20the%20code%20block%20below%20%28use%20%60npm%20ls%60%20instead%0Aof%20%60yarn%20list%60%20if%20you%20are%20using%20npm%29%3A%0A%0A%60%60%60%0Ayarn%20list%20react-native%20bugsnag-react-native%20react-native-code-push%0A%60%60%60%0A%0A-%20cocoapods%20version%20%28if%20any%29%20%28%60pod%20-v%60%29%3A%0A-%20iOS/Android%20version%28s%29%3A%0A-%20simulator/emulator%20or%20physical%20device%3F%3A%0A-%20debug%20mode%20or%20production%3F%3A%0A%0A-%20%5B%20%5D%20%28iOS%20only%29%20%60%5BBugsnagReactNative%20start%5D%60%20is%20present%20in%20the%0A%20%20%60application%3AdidFinishLaunchingWithOptions%3A%60%20method%20in%20your%20%60AppDelegate%60%0A%20%20class%3F%0A-%20%5B%20%5D%20%28Android%20only%29%20%60BugsnagReactNative.start%28this%29%60%20is%20present%20in%20the%0A%20%20%60onCreate%60%20method%20of%20your%20%60MainApplication%60%20class%3F).
* [Report a bug or request a feature](https://github.com/bugsnag/bugsnag-react-native/issues/new/choose)


## Contributing

All contributors are welcome! For information on how to build, test
and release `bugsnag-react-native`, see our
[contributing guide](https://github.com/bugsnag/bugsnag-react-native/blob/master/CONTRIBUTING.md).


## License

The Bugsnag React Native library is free software released under the MIT License.
See [LICENSE.txt](https://github.com/bugsnag/bugsnag-react-native/blob/master/LICENSE.txt)
for details.
