import React, {Component} from 'react'
import {StyleSheet, Text, View} from 'react-native'

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

type Props = {};
export default class App extends Component<Props> {
  render () {
    const scenario = require('./scenario.json')
    setTimeout(function () {
      switch (scenario.name) {
        case 'uncaughtException':
          longStackA(0);
        case 'unhandledRejection':
          Promise.reject(new SyntaxError('no'))
          break
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
