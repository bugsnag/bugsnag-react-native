/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 * @flow
 */

import React, { Component } from 'react';
import bugsnag, { Client } from 'bugsnag-react-native';
import {
  AppRegistry,
  NativeModules,
  StyleSheet,
  Text,
  View
} from 'react-native';
import Button from 'react-native-button';

class examples extends Component {

  constructor(opts) {
    super(opts);
    this.client = new Client('f35a2472bd230ac0ab0f52715bbdc65d');
    this.client.handleUncaughtErrors();
  }

  _raiseJavaError() {
    NativeModules.CrashyCrashy.generateCrash();
  }

  render() {
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          BUGSNAG TEST APP!
        </Text>
        <Button
          containerStyle={styles.crashy}
          style={styles.crash}
          onPress={() => this._handlePress()}>
          JS CRASH!
        </Button>
        <Button
          containerStyle={styles.crashy}
          style={styles.crash}
          onPress={() => this._raiseJavaError ()}>
          JAVA CRASH!
        </Button>
      </View>
    );
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 24,
    textAlign: 'center',
    margin: 10,
  },
  crashy: {
    padding:10,
    height:64,
    overflow:'hidden',
    borderRadius:4,
  },
  crash: {
    textAlign: 'center',
    fontSize: 32,
    color: 'red',
  },
});

AppRegistry.registerComponent('examples', () => examples);
