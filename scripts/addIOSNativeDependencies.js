#!/usr/bin/env node

'use strict';

const log = require('npmlog'),
      xcode = require('xcode'),
      fs = require('fs'),
      path = require('path'),
      spawn = require('child_process').spawn,

      rnpmLinkPath = path.resolve('node_modules/react-native/local-cli/rnpm/link'),
      registerNativeModule = require(path.join(rnpmLinkPath, 'src/ios/registerNativeModule'));


const main = function() {
  log.info("bugsnag", "installing native iOS dependencies");
  const vendorTargetPath = 'node_modules/bugsnag-react-native/cocoa/vendor',
        mainProjectPath = 'node_modules/bugsnag-react-native/cocoa/BugsnagReactNative.xcodeproj';

  cloneVendorProjects(vendorTargetPath, function(err) {
    if (err) {
      log.error(err);
      return;
    }

    log.info("bugsnag", "updating BugsnagReactNative project");
    linkProject(mainProjectPath, vendorTargetPath);
    addReactHeaderSearchPath(mainProjectPath);
  });
}

const parentIOSProjectPath = function() {
  const name = require(path.resolve('./package.json')).name;
  return path.join('ios', name + '.xcodeproj/project.pbxproj');
}

const registerProjectAsDependency = function(mainProjectPath, dependencyPath, dependencySourceFolder) {
  const dependencyData = {
    'pbxprojPath': path.join(dependencyPath, 'project.pbxproj'),
    'projectPath': dependencyPath,
    'folder': path.normalize(path.join(dependencyPath, dependencySourceFolder)),
    'sharedLibraries': []
  },
    mainProjectData = {
      'sourceDir': path.dirname(mainProjectPath),
      'libraryFolder': 'Libraries',
      'pbxprojPath': path.join(mainProjectPath, 'project.pbxproj')
  };

  registerNativeModule(dependencyData, mainProjectData);
}

const addFramework = function(projectPath, frameworkPath) {
  const pbxprojPath = path.join(projectPath, 'project.pbxproj'),
        project = xcode.project(pbxprojPath).parseSync();

  project.addFramework(frameworkPath);
}

const linkProject = function(mainProjectPath, vendorTargetPath) {
  const bugsnagProjectPath = path.join(vendorTargetPath, 'iOS/Bugsnag.xcodeproj'),
        kscrashProjectPath = path.join(vendorTargetPath, 'Carthage/Checkouts/KSCrash/iOS/KSCrash-ios.xcodeproj'),
        bugsnagFrameworkPath = 'System/Library/Frameworks/Bugsnag.framework';

  registerProjectAsDependency(mainProjectPath, bugsnagProjectPath, '../Source');
  registerProjectAsDependency(mainProjectPath, kscrashProjectPath, '../../Source');
  addFramework(mainProjectPath, bugsnagFrameworkPath);
}

const addReactHeaderSearchPath = function(mainProjectPath) {
  const searchPathKey = 'HEADER_SEARCH_PATHS',
        inherited = '"$(inherited)"',
        searchPath = '"$(SRCROOT)/../../react-native/React/**"',
        mainPbxproj = path.resolve(path.join(mainProjectPath, 'project.pbxproj')),
        mainProject = xcode.project(mainPbxproj).parseSync(),
        configurations = mainProject.pbxXCBuildConfigurationSection();

  for (var config in configurations) {
    var buildSettings = configurations[config].buildSettings;
    if (!buildSettings)
      continue;

    if (unquote(buildSettings['PRODUCT_NAME']) != mainProject.productName)
        continue;

    if (!buildSettings[searchPathKey] || buildSettings[searchPathKey] === inherited) {
      buildSettings[searchPathKey] = [inherited];
    }

    if (buildSettings[searchPathKey].indexOf(searchPath) >= 0)
      continue;

    buildSettings[searchPathKey].push(searchPath);
  }
  fs.writeFileSync(mainPbxproj, mainProject.writeSync());
}

const cloneVendorProjects = function(vendorTargetPath, cb) {
  var needClone = true;
  try {
    var stats = fs.lstatSync(vendorTargetPath);
    needClone = !stats.isDirectory();
  } catch (e) { }
  if (!needClone) {
    updateVendorSubmodules(vendorTargetPath, cb);
  } else {
    log.info("bugsnag", "cloning dependencies");
    const vendorURL = 'https://github.com/bugsnag/bugsnag-cocoa';

    var process = spawn('git', ['clone', '--recursive', vendorURL, vendorTargetPath]);
    process.on('close', function(exit_code) {
      if (exit_code != 0) {
        cb(new Error("Failed to clone dependencies with exit status " + exit_code));
        return;
      }
      updateVendorSubmodules(vendorTargetPath, cb);
    });
  }
}

const updateVendorSubmodules = function(vendorTargetPath, cb) {
  log.info("bugsnag", "initializing dependencies");
  var process = spawn('git', ['-C', vendorTargetPath, 'submodule', 'update', '--init']);
  process.on('close', function(exit_code) {
    if (exit_code == 0)
      cb();
    else
      cb(new Error("Failed to initialize dependencies"));
  });
}

function unquote(str) {
  if (str)
    return str.replace(/^"(.*)"$/, "$1");
}

main();
