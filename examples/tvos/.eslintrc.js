module.exports = {
  extends: [
    'react-native',
  ],
  plugins: [
    'babel',

  ],
  rules: {
    'class-methods-use-this': 'off',
    'import/no-unresolved': [2, { ignore: ['^lib\/'] }],
    'import/no-extraneous-dependencies': 'off',
    'react/jsx-handler-names': 'off',
    'react-native/no-color-literals': 'off',
    'react-native/no-inline-styles': 'off',
    'no-invalid-this': 'off',
    'babel/no-invalid-this': 'error',
  }
};
