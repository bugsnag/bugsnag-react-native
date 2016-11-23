import React from 'react';
import { Text, Button, StyleSheet, View } from 'react-native';

const styles = StyleSheet.create({
  titleView: {
    justifyContent: 'center',
    flex: 1,
  },

  titleText: {
    color: '#ffffff',
    fontWeight: 'bold',
  }
});

const NavigationBarRouteMapper = {
  LeftButton(route, navigator, index) {
    if (index > 0) {
      return (
        <Button title="Back" color="#ffffff" onPress={navigator.pop} />
      );
    }

    return null;
  },

  RightButton() {
    return null;
  },

  Title(route) {
    return (
      <View style={styles.titleView}>
        <Text style={styles.titleText}>{route.title || route.id}</Text>
      </View>
    );
  },
}

export default NavigationBarRouteMapper;
