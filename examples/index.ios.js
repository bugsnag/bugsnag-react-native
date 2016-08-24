import React, { Component } from 'react';
import bugsnag, { Client } from 'bugsnag-react-native';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View
} from 'react-native';

class examples extends Component {

  constructor(opts) {
    super(opts);
    this.client = new Client('f35a2472bd230ac0ab0f52715bbdc65d');
    this.client.handleUncaughtErrors();
  }

  render() {
    this.client.leaveBreadcrumb('load main view',
        {type: 'navigation', firstLaunch: 'no'});
    this.client.notify(new Error('Hello Bugsnag from React Native'));
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>
          Welcome to the Sample Project!
        </Text>
        <Text style={styles.instructions}>
          To get started, edit index.ios.js
        </Text>
        <Text style={styles.instructions}>
          Press Cmd+R to reload,{'\n'}
          Cmd+D or shake for dev menu
        </Text>
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
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5,
  },
});

AppRegistry.registerComponent('examples', () => examples);
