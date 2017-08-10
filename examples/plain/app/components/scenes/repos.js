import React, { Component } from 'react';
import { Picker, View, ListView, ActivityIndicator, StyleSheet, Alert  } from 'react-native';
import { List } from 'react-native-elements'
import ListItem from '../list_item';
import github from 'lib/github';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignSelf: 'flex-start',
  },

  list: {
    marginTop: 0,
  },
})

// List datasource
const ds = new ListView.DataSource({rowHasChanged: (r1, r2) => r1 !== r2});

// -----------------------------------------------------------------------------------------------
// Repos Screen
// -----------------------------------------------------------------------------------------------
//
// Uses the github api to fetch the repositories for a given organization.
// -----------------------------------------------------------------------------------------------
export default class Repos extends Component {
  state = {
    isLoading: true,
    repos: ds.cloneWithRows([]),
    org: 'bugsnag'
  };

  _fetchRepos = () => {
    github.getRepos(this.state.org).then(this._handleSuccess, this._handleError);
  };

  _handleSuccess = (repos) => {
    this.setState({
      isLoading: false,
      repos: this.state.repos.cloneWithRows(repos),
    });
  }

  _handleError = (error) => {
    Alert.alert('Network Error!', error, [ {text: 'OK'} ])
    this.setState({
      isLoading: false,
    });
  };

  _handleOrgSelect = (nextOrg) => {
    this.setState({
      org: nextOrg,
      isLoading: true,
      repos: ds.cloneWithRows([]),
    }, this._fetchRepos)
  }

  componentDidMount() {
    this._fetchRepos();
  }

  render() {
    if (this.state.isLoading) {
      return (
        <ActivityIndicator />
      );
    }
    return (
      <View style={styles.container}>
        <View>
          <Picker
            selectedValue={this.state.org}
            onValueChange={this._handleOrgSelect}>
            <Picker.Item label="Bugsnag" value="bugsnag" />
            <Picker.Item label="Github" value="github" />
            <Picker.Item label="404 Not Found" value="asdfsassdfasdfasdfasdfkjasdfjksdajfkjkasdfkjasdf" />
          </Picker>
        </View>
        <List containerStyle={styles.list}>
          <ListView
            dataSource={this.state.repos}
            renderRow={this._renderRow}
          />
        </List>
      </View>
    );
  }

  _renderRow(repo, sectionID) {
    return (
      <ListItem
        key={sectionID}
        title={repo.name}
        subtitle={repo.description}
      />
    );
  }
}
