import { Client, Configuration } from 'bugsnag-react-native';
const config = new Configuration();
config.notifyReleaseStages = ['beta', 'production', 'development'];
const bugsnag = new Client(config);

import { AppRegistry } from 'react-native';
import App from './App';

AppRegistry.registerComponent('Example', () => App);
