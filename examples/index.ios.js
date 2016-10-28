import React, { Component } from 'react';
import { Client } from 'bugsnag-react-native';
import {
  AppRegistry,
  StyleSheet,
  Text,
  View
} from 'react-native';

const client = new Client('API key');

class examples extends Component {

  render() {
    client.leaveBreadcrumb('load main view',
        {type: 'navigation', firstLaunch: 'no'});
    client.setUser('123', 'John Jones');
    client.notify(new Error('foo'));

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
