/** @format */
import { Client, Configuration } from 'bugsnag-react-native';
const config = new Configuration();
config.releaseStage = 'delta';
const bugsnag = new Client(config);

import {AppRegistry} from 'react-native';
import App from './App';
import {name as appName} from './app.json';

AppRegistry.registerComponent(appName, () => App);
