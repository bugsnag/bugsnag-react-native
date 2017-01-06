# Bugsnag React Native Example
A robust example of how to make best use of the Bugsnag React Native notifier.

## Demonstrates

- [Extracting common configuration for multiple files and environments](app/lib)
- [Identifying users](app/components/scenes/register.js#L47-50)
- [Handling rejected promises](app/lib/github.js#L26)
- [Logging Handled exceptions](app/index.js#L52)
- Using breadcrumbs
  - [Navigation](app/index.js#L77)
  - [Submitting forms](app/components/scenes/register.js#L38-L42)
  - [Network requests](app/lib/github.js#L34)

## Setup

1. Clone the repository
  ```
  git clone https://github.com/bugsnag/BugsnagReactNativeExample
  ```

1. install dependencies

  with npm

  ```
  npm install
  ```

  or with [yarn](https://yarnpkg.com)

  ```
  yarn
  ```

1. [Create a bugsnag account](https://app.bugsnag.com/user/new) and create
   a react native project.

1. Add your project api key to [app/lib/bugsnag.js](app/lib/bugsnag.js#L7). The
   API key can be found in the the bugsnag settings for your project.

  ```javascript
  const client = new Client('API_KEY_GOES_HERE');
  ```

1. Run the app
  ```
  react-native run-ios
  ```

