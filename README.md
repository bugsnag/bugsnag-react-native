# Bugsnag exception reporter for React Native
[![Documentation](https://img.shields.io/badge/documentation-2.3.0-blue.svg)](http://docs.bugsnag.com/platforms/react-native/)

Automatic [React Native error reporting](https://www.bugsnag.com/platforms/react-native-error-reporting/) with Bugsnag helps you detect both native OS and JavaScript errors in your React Native apps.

## Features

* Automatically report unhandled exceptions and crashes
* Show full stacktraces with [source map integration](https://docs.bugsnag.com/platforms/react-native/showing-full-stacktraces)
* Report [handled exceptions](http://docs.bugsnag.com/platforms/react-native/#reporting-handled-exceptions)
* [Log breadcrumbs](http://docs.bugsnag.com/platforms/react-native/#logging-breadcrumbs) which are attached to crash reports and add insight to users' actions
* [Attach user information](http://docs.bugsnag.com/platforms/react-native/#identifying-users) to determine how many people are affected by a crash


## Getting started

1. [Create a Bugsnag account](https://bugsnag.com)
1. Complete the instructions in the [integration guide](https://docs.bugsnag.com/platforms/react-native) to report unhandled exceptions thrown from your app
1. Report handled exceptions using [`Client.notify()`](https://docs.bugsnag.com/platforms/react-native/#reporting-handled-errors)
1. Customize your integration using the [configuration options](http://docs.bugsnag.com/platforms/react-native/configuration-options/)


## Support

* [Read the integration guide](http://docs.bugsnag.com/platforms/react-native/) or [configuration options documentation](http://docs.bugsnag.com/platforms/react-native/configuration-options/)
* [Search open and closed issues](https://github.com/bugsnag/bugsnag-react-native/issues?utf8=✓&q=is%3Aissue) for similar problems
* [Report a bug or request a feature](https://github.com/bugsnag/bugsnag-react-native/issues/new)


## Contributing

All contributors are welcome! For information on how to build, test
and release `bugsnag-react-native`, see our
[contributing guide](https://github.com/bugsnag/bugsnag-react-native/blob/master/CONTRIBUTING.md).


## License

The Bugsnag React Native library is free software released under the MIT License.
See [LICENSE.txt](https://github.com/bugsnag/bugsnag-react-native/blob/master/LICENSE.txt)
for details.
