import React, { Component } from 'react';
import { View, StatusBar, StyleSheet, Text, Button } from 'react-native';
import bugsnag from 'lib/bugsnag';

const styles = StyleSheet.create({
  container: {
    paddingTop: 20,
    flex: 1,
    flexDirection: 'column',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#eeeeee',
  },
})

export default class App extends Component {
  render() {
    return (
      <View style={styles.container}>
        <Text>
          Bugsnag and React Native using CocoaPods
        </Text>
        <Button
          onPress={this.triggerHandledException}
          title="Cause handled exception from JS"
          accessibilityLabel="Cause handled exception from JS"
          color="#841584"/>
        <Button
          onPress={this.triggerUnhandledException}
          title="Cause unhandled exception from JS"
          accessibilityLabel="Cause unhandled exception from JS"
          color="#841584"/>
      </View>
    );
  }

  triggerHandledException() {
    bugsnag.notify(new RangeError('A handled exception from JS'));
  }

  triggerUnhandledException() {
    throw new TypeError('An unhandled exception from JS');
  }
}
