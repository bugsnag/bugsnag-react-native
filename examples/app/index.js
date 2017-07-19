import React, { Component } from 'react';
import { View, StatusBar, StyleSheet } from 'react-native';
import { Navigator } from 'react-native-deprecated-custom-components';
import bugsnag from 'lib/bugsnag';
import NavigationBarRouteMapper from './components/navigation_bar_route_mapper';
import Main from './components/scenes/main';
import Repos from './components/scenes/repos';
import Crashy from './components/scenes/crashy';
import Register from './components/scenes/register';

// -----------------------------------------------------------------------------------------------
// App component. (root)
//
// Simple Navigator based app that will notify Bugsnag if an invalid route is used.
// Will also leave breadcrumbs for each navigation change.
// -----------------------------------------------------------------------------------------------
const styles = StyleSheet.create({
  container: {
    paddingTop: Navigator.NavigationBar.Styles.General.TotalNavHeight,
    flex: 1,
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#eeeeee',
  },

  navBar: {
    backgroundColor: '#212129',
    alignItems: 'center',
  },
})

export default class App extends Component {
  render() {
    return (
      <Navigator
        initialRoute={{id: 'Main', title: 'Bugsnag React Native Example'}}
        renderScene={this._renderScene}
        onWillFocus={leaveNavigationBreadcrumb}
        navigationBar={
          <Navigator.NavigationBar style={styles.navBar}
            routeMapper={NavigationBarRouteMapper} />
        }
      />
    );
  }

  _renderScene(route, navigator) {
    // pick the scene based on the route.id
    const scene = (() => {
      switch (route.id) {
        case 'Main':   return <Main navigator={navigator} />;
        case 'Repos':  return <Repos navigator={navigator} />;
        case 'Crashy': return <Crashy navigator={navigator} />;
        case 'Register': return <Register onSuccess={navigator.pop} />;
        default:
          // With missing route we can just log the error and go back to the main page
          bugsnag.notify(new Error(`invalid route used: ${route.id}`));
          // Render the main page I guess, maybe we should have some sort of reassuring
          // error screen? ¯\_(ツ)_/¯
          return <Main navigator={navigator} />;
      }
    })();

    return (
      <View style={styles.container}>
        <StatusBar
          barStyle="light-content"
        />
        {scene}
      </View>
    );
  }
}


//-------------------------------------------------------------------------------------------------
// Navigation handler that logs a bugsnag breadcrumb of type 'navigation'
//-------------------------------------------------------------------------------------------------
//
// hooks into the onWillFocus callback of the react native Navigator
// https://facebook.github.io/react-native/docs/navigator.html#onwillfocus
function leaveNavigationBreadcrumb(route) {
  // We want the breadcrumb message to say "Navigation [Main]" or "Navigation [Repo Screen]" etc...
  const message = `Navigation [${route.id}]`
  const metadata = {
    type: 'navigation', // this really just gives us the nice navigation icon in the UI.
    ...route, // Include all route information in the metadata.
  };

  bugsnag.leaveBreadcrumb(message, metadata);
}
