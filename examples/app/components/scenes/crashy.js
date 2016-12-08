import React from 'react';
import { Text, View, StyleSheet, NativeModules, Platform } from 'react-native';
import { Button } from 'react-native-elements';

function triggerException() {
  bogusFunction(); // eslint-disable-line no-undef
}

function triggerNativeException() {
  NativeModules.CrashyCrashy.generateCrash();
}


const styles = StyleSheet.create({
  container: {
    flexDirection: 'column',
    alignItems: 'stretch',
    justifyContent: 'center',
  },
  group: {
    marginBottom: 20,
  },
  button: {
    marginBottom: 10,
  },
  info: {
    textAlign: 'center',
    color: '#666',
    fontSize: 11,
  }
});

const Crashy = () => (
  <View style={styles.container}>
    <View style={styles.group}>
      <Button
        backgroundColor="#e1727d"
        color="#ffffff"
        title="Trigger JS Exception"
        onPress={triggerException}
        icon={{name: 'alert', type: 'octicon'}}
        borderRadius={5}
        buttonStyle={styles.button}
      />
      <Text style={styles.info}>Tap this button to send a JS crash to Bugsnag</Text>
    </View>
    <View style={styles.group}>
      <Button
        backgroundColor="#e1727d"
        color="#ffffff"
        title="Trigger Native Exception"
        onPress={triggerNativeException}
        icon={{name: 'device-mobile', type: 'octicon'}}
        borderRadius={5}
        buttonStyle={styles.button}
      />
      <Text style={styles.info}>
        Tap this button to send a native {Platform.OS} crash to Bugsnag
      </Text>
    </View>
  </View>
)

export default Crashy;
