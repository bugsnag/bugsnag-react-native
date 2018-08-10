import React, { Component } from 'react';
// import CodePush from 'react-native-code-push';
import bugsnag from 'lib/bugsnag';
import NativeCrash from 'lib/native_crash';
import {
  StyleSheet,
  Text,
  Button,
  View
} from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F7A6C6',
  },
  welcome: {
    fontSize: 28,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 60,
  },
});

class BugsnagReactNativeExample extends Component {
  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          Bugsnag + React Native
        </Text>
        <Text style={styles.instructions}>
          To get started, click one of the options below:
        </Text>
        <Button onPress={this.identifyUser}
          title="Sign in a user"
          accessibilityLabel="Sign in a user" />
        <Button onPress={this.triggerHandledError}
          title="Trigger handled error"
          accessibilityLabel="Trigger a handled error which is sent to Bugsnag" />
        <Button onPress={this.triggerReferenceError}
          title="Trigger reference error"
          accessibilityLabel="Trigger a reference error with an invalid reference" />
        <Button onPress={this.triggerNativeException}
          title="Trigger native crash"
          accessibilityLabel="Trigger a native crash" />
        <Button onPress={this.triggerThrowException}
          title="Throw JavaScript error"
          accessibilityLabel="Throw a JavaScript error" />
      </View>
    );
  }
  triggerNativeException() {
    NativeCrash.generateCrash();
  }
  triggerReferenceError() {
    bugsnag.leaveBreadcrumb("Starting root computation");
    100 / y();
  }
  triggerThrowException() {
    throw new Error("The proposed value has been computed - and was wrong");
  }
  triggerHandledError() {
    try {
      decodeURIComponent("%")
    } catch (e) {
      bugsnag.notify(e)
    }
  }
  identifyUser() {
    bugsnag.setUser("123", "John Leguizamo", "john@example.com");
    console.warn("Added user information for any future error reports.");
    bugsnag.leaveBreadcrumb("Signed in", { type: "user" });
  }
};

// let codePushOptions = { checkFrequency: CodePush.CheckFrequency.ON_APP_RESUME };
// BugsnagReactNativeExample = CodePush(codePushOptions)(BugsnagReactNativeExample);

export default BugsnagReactNativeExample;
