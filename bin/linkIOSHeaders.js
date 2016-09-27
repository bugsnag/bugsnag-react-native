#!/usr/bin/env node
/**
 * Add the React Native header search path to the BugsnagReactNative project
 *
 * Depends on:
 * - xcode
 * - fs
 */

const xcode = require('xcode'),
      fs = require('fs'),
      mainProjectPath = 'node_modules/bugsnag-react-native/cocoa/BugsnagReactNative.xcodeproj/project.pbxproj';

const main = function() {
    var mainProject = xcode.project(mainProjectPath).parseSync();
    addReactHeaderSearchPath(mainProject);

    fs.writeFileSync(mainProject.filepath, mainProject.writeSync());
}

const addReactHeaderSearchPath = function(mainProject) {
  const searchPathKey = 'HEADER_SEARCH_PATHS',
        inherited = '"$(inherited)"',
        searchPath = '"$(SRCROOT)/../../react-native/React/**"',
        configurations = mainProject.pbxXCBuildConfigurationSection();

  for (var config in configurations) {
    var buildSettings = configurations[config].buildSettings;
    if (!buildSettings)
      continue;

    var productName = buildSettings['PRODUCT_NAME'];
    if (!productName)
      continue;

    productName = productName.replace(/^"(.*)"$/, "$1");
    if (productName != mainProject.productName)
        continue;

    if (!buildSettings[searchPathKey] || buildSettings[searchPathKey] === inherited) {
      buildSettings[searchPathKey] = [inherited];
    }

    if (buildSettings[searchPathKey].indexOf(searchPath) >= 0)
      continue;

    buildSettings[searchPathKey].push(searchPath);
  }
}

main();
