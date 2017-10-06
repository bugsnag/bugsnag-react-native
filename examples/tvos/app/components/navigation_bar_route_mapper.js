import React from 'react';
import { Text, StyleSheet, View, TouchableHighlight } from 'react-native';
import { Icon } from 'react-native-elements';

const TEXT_COLOR = '#ffffff';

const styles = StyleSheet.create({
  titleView: {
    justifyContent: 'center',
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },

  titleText: {
    color: TEXT_COLOR,
    fontWeight: 'bold',
    textAlign: 'center',
    flex: 1,
  },

  backButton: {
    flex: 1,
    justifyContent: 'center',
    paddingLeft: 5,
    paddingRight: 5,
  },

  backButtonInner: {
    alignItems: 'center',
    flexDirection: 'row',
  },

  backIcon: {
    width: 20,
  },

  backText: {
    color: TEXT_COLOR,
  }
});

const NavigationBarRouteMapper = {
  LeftButton(route, navigator, index) {
    // android doesn't need a back button, and it looks bad :\
    if (index > 0) {
      return (
        <TouchableHighlight style={styles.backButton} onPress={navigator.pop}>
          <View style={styles.backButtonInner}>
            <Icon
              iconStyle={styles.backIcon}
              name='chevron-left'
              type='octicon'
              color={TEXT_COLOR}
            />
            <Text style={styles.backText}>Back</Text>
          </View>
        </TouchableHighlight>
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
