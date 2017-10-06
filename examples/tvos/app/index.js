import React, { Component } from 'react';
import { Text } from 'react-native';
import bugsnag from 'lib/bugsnag';

export default class App extends Component {
  render() {
    bugsnag.notify(new Error(`invalid route used:`));
    return (
      <Text>Hello world!</Text>
    );
  }
}
