/** @format */

import { Platform } from 'react-native'
import { Client, Configuration, StandardDelivery } from 'bugsnag-react-native'
const config = new Configuration('my API key!')
var endpoint = Platform.OS === 'ios' ? 'http://localhost:9339' : 'http://10.0.2.2:9339'
config.delivery = new StandardDelivery(endpoint, endpoint)
config.autoCaptureSessions = false
const bugsnag = new Client(config)

export default bugsnag;

import {AppRegistry} from 'react-native'
import App from './App'
import {name as appName} from './app.json'

AppRegistry.registerComponent(appName, () => App)
