module.exports = {
  dependency: {
    platforms: {
      ios: {
        sharedLibraries: [ 'libz' ]
      },
      android: {
        packageInstance: 'BugsnagReactNative.getPackage()',
        packageImportPath: 'import com.bugsnag.BugsnagReactNative;'
      }
    },
    assets: [],
    hooks: {}
  }
}
