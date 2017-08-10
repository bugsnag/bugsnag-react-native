import React from 'react';
import { StyleSheet } from 'react-native';
import { ListItem } from 'react-native-elements';

const styles = StyleSheet.create({

  subtitle: {
    color: '#ccc',
    fontWeight: 'normal',
  },
});

const CustomListItem = (props) => <ListItem subtitleStyle={styles.subtitle} {...props} />
export default CustomListItem;
