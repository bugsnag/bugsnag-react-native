import React from 'react';
import { Text, View, StyleSheet } from 'react-native';
import { Button } from 'react-native-elements';

function triggerException() {
  this.bogusFunction();
}

const styles = StyleSheet.create({
  container: {
    alignItems: 'center',
  },
  button: {
    marginBottom: 10,
  },
  info: {
    color: '#666',
    fontSize: 11,
  }
});

const Crashy = () =>
  <View style={styles.container}>
    <Button
      backgroundColor="#e1727d"
      color="#ffffff"
      title="Trigger Exception"
      onPress={triggerException}
      icon={{name: 'alert', type: 'octicon'}}
      borderRadius={5}
      buttonStyle={styles.button}
    />
    <Text style={styles.info}>Tap this button to send a crash to Bugsnag</Text>
  </View>

export default Crashy;
