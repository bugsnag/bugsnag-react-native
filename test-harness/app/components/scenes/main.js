import React from 'react';
import { View, Navigator, StyleSheet } from 'react-native';
import { List } from 'react-native-elements';
import ListItem from '../list_item';
import PropTypes from 'prop-types';

const styles = StyleSheet.create({
  container: {
    flexDirection: 'column',
    justifyContent: 'space-between',
    flex: 1,
    alignSelf: 'stretch',
  },
});

const Main = ({ navigator }) =>
  <View style={styles.container}>
    <List>
      <ListItem
        title="Fetch Example"
        onPress={navigator.push.bind(null, {id: 'Repos', title: 'Repos'})}
        subtitle="Tracking network requests and errors"
        accessibilityLabel="Go to crashy page"
        leftIcon={{name: 'refresh', type: 'font-awesome'}}
      />
      <ListItem
        title="Identify User"
        onPress={navigator.push.bind(null, {id: 'Register', title: 'Simulate User Registration'})}
        subtitle="Simulate user registeration and identification"
        accessibilityLabel="Go to crashy page"
        leftIcon={{name: 'user', type: 'font-awesome'}}
      />
      <ListItem
        title="Trigger Exception"
        onPress={navigator.push.bind(null, {id: 'Crashy', title: 'Trigger Exception'})}
        subtitle="A simple screen that will crash"
        accessibilityLabel="Go to crashy page"
        leftIcon={{name: 'exclamation-circle', type: 'font-awesome'}}
      />
      { /* Add a button to a non existent route to trigger the manual bugsnag.notify() */ }
      <ListItem
        title="Broken Route"
        onPress={navigator.push.bind(null, {id: 'Bogus', title: 'Bogus'})}
        subtitle="This item is broken. This route doesn't exist!"
        accessibilityLabel="Go to crashy page"
        leftIcon={{name: 'chain-broken', type: 'font-awesome'}}
      />
    </List>
  </View>

Main.propTypes = {
  navigator: PropTypes.instanceOf(Navigator),
};

export default Main;

