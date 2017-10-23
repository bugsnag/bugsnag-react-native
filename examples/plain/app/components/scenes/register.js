import bugsnag from 'lib/bugsnag';
import React, { Component } from 'react';
import { View, StyleSheet, Alert } from 'react-native';
import { FormLabel, FormInput, Button } from 'react-native-elements'
import PropTypes from 'prop-types'

const styles = StyleSheet.create({
  container: { alignSelf: 'stretch', flex: 1, backgroundColor: '#fff',
    padding: 10,
    paddingBottom: 40,
  },

  button: {
    marginTop: 40,
  },
});

// -----------------------------------------------------------------------------------------------
// Register Screen
// -----------------------------------------------------------------------------------------------
//
// Demonstrates:
// - Identifying the user
// - Breadcrumbs from form interactions
// -----------------------------------------------------------------------------------------------
export default class Register extends Component {
  static propTypes = {
    onSuccess: PropTypes.func.isRequired
  };

  state = {
    name: '',
    email: '',
  };

  handleSubmit = async () => {
    const params = {...this.state};

    // leave a breadcrumb
    bugsnag.leaveBreadcrumb('Submit singup form', {
      type: 'user',
      ...params,
    });

    // do the registration
    const user = await mockRegistrationApi(params);

    // Identify the user with bugsnag
    // https://docs.bugsnag.com/platforms/react-native/#identifying-users
    const {id, name, email} = user;
    bugsnag.setUser(id, name, email);

    // Show a diagnostic message (you wouldn't do this in real life)'
    Alert.alert(
      'User Identified',
      'Whenever you trigger an exception your info will show up in the bugsnag error report',
      [
        {text: 'OK', onPress: () => this.props.onSuccess(user)},
      ]
    )
  };

  updateName = (text) => {
    this.setState(state => ({ ...state, name: text }));
  };

  updateEmail = (text) => {
    this.setState(state => ({ ...state, email: text }));
  };

  render() {
    return (
      <View style={styles.container}>
        <FormLabel>Name</FormLabel>
        <FormInput onChangeText={this.updateName} />
        <FormLabel>Email</FormLabel>
        <FormInput onChangeText={this.updateEmail} />
        <Button
          backgroundColor="#246dd5"
          color="#ffffff"
          title="Register"
          onPress={this.handleSubmit}
          buttonStyle={styles.button}
          disabled={!this.state.name.length || !this.state.email.length}
        />
      </View>
    );
  }
}


// fake registration api to simulate creating a user.
// Gets a user object, adds an ID to it, and returns a promise that resolves that same user object
function mockRegistrationApi(user) {
  return Promise.resolve({
    id: 'fakeID123',
    ...user
  })
}
