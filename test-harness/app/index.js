import React, { Component } from 'react';
import { Platform, Navigator, View } from 'react-native';
import { Client, Configuration, StandardDelivery } from "bugsnag-react-native";
import { bugsnag } from 'lib/bugsnag';
import Main from './components/scenes/main';
import Repos from './components/scenes/repos';
import Crashy from './components/scenes/crashy';
import Register from './components/scenes/register';


export default class App extends Component {

  constructor(props) {
    super(props);
    const config = new Configuration();
    config.apiKey = "123";

    // Android emulator uses 10.0.2.2 by default
    const endpoint = Platform.OS === 'android' ? "http://10.0.2.2:9999" : "http://localhost:9999";
    config.delivery = new StandardDelivery(endpoint);
    const client = new Client(config);
    client.notify(new Error(`Whoops!`));
  }

  render() {
    return (
      <View/>
    );
  }
}
