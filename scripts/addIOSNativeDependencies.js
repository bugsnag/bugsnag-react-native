#!/usr/bin/env node
/**
 * Post-installation script which vendors iOS native dependencies for
 * bugsnag-react-native and links them as needed.
 *
 * Depends on:
 * - child_process
 * - fs
 * - npmlog
 * - path
 * - react-native/local-cli/rnpm/link
 * - xcode
 */
'use strict';

const log = require('npmlog'),
      xcode = require('xcode'),
      PbxFile = require('xcode/lib/pbxFile'),
      fs = require('fs'),
      path = require('path'),
      spawn = require('child_process').spawn,

      rnpmLinkPath = path.resolve('node_modules/react-native/local-cli/rnpm/link'),
      addToHeaderSearchPaths = require(path.join(rnpmLinkPath, 'src/ios/addToHeaderSearchPaths')),
      createGroupWithMessage = require(path.join(rnpmLinkPath, 'src/ios/createGroupWithMessage')),
      getHeadersInFolder = require(path.join(rnpmLinkPath, 'src/ios/getHeadersInFolder')),
      getHeaderSearchPath = require(path.join(rnpmLinkPath, 'src/ios/getHeaderSearchPath'));


const main = function() {
  log.info("bugsnag", "installing native iOS dependencies");
  const vendorTargetPath = 'node_modules/bugsnag-react-native/cocoa/vendor',
        mainProjectPath = 'node_modules/bugsnag-react-native/cocoa/BugsnagReactNative.xcodeproj/project.pbxproj';

  cloneVendorProjects(vendorTargetPath, function(err) {
    if (err) {
      log.error(err);
      return;
    }

    log.info("bugsnag", "updating BugsnagReactNative project");
    var mainProject = xcode.project(mainProjectPath).parseSync();
    linkProject(mainProject, vendorTargetPath);
    addReactHeaderSearchPath(mainProject);

    fs.writeFileSync(mainProject.filepath, mainProject.writeSync());
  });
}

const parentIOSProjectPath = function() {
  const name = require(path.resolve('./package.json')).name;
  return path.join('ios', name + '.xcodeproj/project.pbxproj');
}

const registerProjectAsDependency = function(mainProject, dependency) {
  const dependencyProject = xcode.project(path.join(dependency.path, 'project.pbxproj')).parseSync(),
        productsGroup = dependencyProject.pbxGroupByName('Products'),
        libraries = createGroupWithMessage(mainProject, 'Libraries'),
        headers = getHeadersInFolder(path.normalize(path.join(dependency.path, dependency.sourceFolder))),
        relativePath = path.relative(path.dirname(path.dirname(mainProject.filepath)), dependency.path);

  if (!mainProject.hasFile(relativePath)) {
    const file = new PbxFile(relativePath);
    file.uuid = mainProject.generateUuid();
    file.fileRef = mainProject.generateUuid();
    mainProject.addToPbxFileReferenceSection(file);
    libraries.children.push({ value: file.fileRef, comment: file.basename });
  }

  for (var index in productsGroup.children) {
    var child = productsGroup.children[index];
    if (child.comment === dependency.framework) {
      mainProject.addFramework(child.value, {customFramework: true});
    } else {
      log.info("bugsnag", "skipping product " + child);
    }
  }

  if (headers && headers.length > 0) {
    addToHeaderSearchPaths(
      mainProject,
      getHeaderSearchPath(path.dirname(mainProject.filepath), headers));
  }
}

const linkProject = function(mainProject, vendorTargetPath) {
  const bugsnagProjectPath = path.join(vendorTargetPath, 'iOS/Bugsnag.xcodeproj'),
        kscrashProjectPath = path.join(vendorTargetPath, 'Carthage/Checkouts/KSCrash/iOS/KSCrash-ios.xcodeproj');

  registerProjectAsDependency(mainProject, {
    'path': bugsnagProjectPath,
    'sourceFolder': '../Source',
    'framework': 'Bugsnag.framework'
  });
  registerProjectAsDependency(mainProject, {
    'path': kscrashProjectPath,
    'sourceFolder': '../../Source',
    'framework': 'KSCrash.framework'
  });
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

    if (unquote(buildSettings['PRODUCT_NAME']) != mainProject.productName)
        continue;

    if (!buildSettings[searchPathKey] || buildSettings[searchPathKey] === inherited) {
      buildSettings[searchPathKey] = [inherited];
    }

    if (buildSettings[searchPathKey].indexOf(searchPath) >= 0)
      continue;

    buildSettings[searchPathKey].push(searchPath);
  }
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

  return null;
}

main();
