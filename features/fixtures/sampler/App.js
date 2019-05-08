import React, {Component} from 'react'
import {StyleSheet, Text, View, NativeModules, Platform} from 'react-native'
import bugsnag from './index.js';

function longStackB(index) {
  if (index < 1200) {
    return longStackA(index)
  }
  throw new TypeError('Forever and a day')
}
function longStackA(index) {
  if (index < 1200) {
    return longStackB(index + 1)
  }
  throw new TypeError('Forever and a day')
}

function stoppedSession() {
  bugsnag.startSession()
  bugsnag.stopSession()
  bugsnag.notify(new Error("Stopped session error"))
}

function resumedSession() {
  bugsnag.startSession()
  bugsnag.notify(new Error("First error"))
  bugsnag.stopSession()
  bugsnag.notify(new Error("Second error"))
  bugsnag.resumeSession()
  bugsnag.notify(new Error("Third error"))
}

function testANR6000Timeout() {
  NativeModules.ANRTimeout.triggerANR(6000);
}

function testANR3000Timeout() {
  NativeModules.ANRTimeout.triggerANR(3000);
}

function triggerNativeError() {
  NativeModules.NativeError.triggerNativeError();
}

type Props = {};
export default class App extends Component<Props> {
  render () {
    const scenario = require('./scenario.json')
    setTimeout(function () {
      console.log('Performing scenario: ' + scenario.name)
      switch (scenario.name) {
        case 'uncaughtException':
          longStackA(0);
          break;
        case 'unhandledRejection':
          Promise.reject(new SyntaxError('no'))
          break
        case 'StoppedSessionScenario':
          stoppedSession();
          break;
        case 'ResumedSessionScenario':
          resumedSession();
          break;
        case 'TestANRLong':
          testANR6000Timeout();
          break;
        case 'TestANRShort':
          testANR3000Timeout();
          break;
        case 'TriggerNativeError':
          triggerNativeError();
          break;
      }
    }, 10)
    return (
      <View style={styles.container}>
        <Text style={styles.welcome}>Welcome to the</Text>
        <Text style={styles.welcome}>T H U N D E R D O M E</Text>
      </View>
    )
  }
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF'
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10
  },
  instructions: {
    textAlign: 'center',
    color: '#333333',
    marginBottom: 5
  }
})
