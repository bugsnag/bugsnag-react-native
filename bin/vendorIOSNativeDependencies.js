#!/usr/bin/env node
/**
 * Post-installation script which vendors iOS native dependencies for
 * bugsnag-react-native and links them as needed.
 *
 * Depends on:
 * - git (in $PATH)
 * - child_process
 * - fs
 * - npmlog
 * - path
 * - readline
 * - xcode
 */
'use strict';

const log = require('npmlog'),
      xcode = require('xcode'),
      util = require('util'),
      readline = require('readline'),
      PbxFile = require('xcode/lib/pbxFile'),
      fs = require('fs'),
      path = require('path'),
      spawnSync = require('child_process').spawnSync;

const main = function() {
  promptVendorTargetPath(function(text, err) {
    if (err) {
      log.error(err);
      return;
    }
    if (!text || text.length === 0)
      text = vendorTargetPath;

    cloneVendorProjects(text, function(err) {
      if (err) {
        log.error(err);
        return;
      }
      linkProjectDeps(text);
    });
  });
}

const linkProjectDeps = function(vendorTargetPath) {
    const projectPath = 'node_modules/bugsnag-react-native/cocoa/BugsnagReactNative.xcodeproj/project.pbxproj',
          bugsnagProjectPath = path.join(vendorTargetPath, 'iOS/Bugsnag.xcodeproj'),
          kscrashProjectPath = path.join(vendorTargetPath, 'Carthage/Checkouts/KSCrash/iOS/KSCrash-ios.xcodeproj');

    log.info("bugsnag", "linking BugsnagReactNative project with vendored deps");
    var project = xcode.project(projectPath).parseSync();

    addFileReference(project, bugsnagProjectPath);
    addFileReference(project, kscrashProjectPath);

    fs.writeFileSync(project.filepath, project.writeSync());
}

const addFileReference = function(project, dependencyPath) {
  const relativePath = path.relative(path.dirname(path.dirname(project.filepath)), dependencyPath);

  if (!project.hasFile(relativePath)) {
    const file = new PbxFile(relativePath),
          libraries = project.pbxGroupByName('Libraries');

    file.uuid = project.generateUuid();
    file.fileRef = project.generateUuid();
    project.addToPbxFileReferenceSection(file);
    libraries.children.push({ value: file.fileRef, comment: file.basename });
  }
}

const promptVendorTargetPath = function(cb) {
  const defaultVendorTargetPath = 'vendor/bugsnag-cocoa',
        rl = readline.createInterface({
          input: process.stdin,
          output: process.stdout
        });

  rl.question("Select vendor directory (./vendor/bugsnag-cocoa):", function(answer) {
    rl.close();
    if (!answer || answer.length === 0)
      answer = defaultVendorTargetPath;

    cb(answer);
  });
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
    const vendorURL = 'https://github.com/bugsnag/bugsnag-cocoa';

    log.info("bugsnag", "vendoring native iOS dependencies into " + vendorTargetPath);
    makeDirSync(path.dirname(vendorTargetPath));

    var process = spawnSync('git', ['clone', '--recursive', vendorURL, vendorTargetPath]);
    if (process.status != 0) {
      cb(new Error("Failed to clone dependencies with exit status " + process.status));
    } else {
      checkoutLatestTag(vendorTargetPath);
      updateVendorSubmodules(vendorTargetPath, cb);
    }
  }
}

const makeDirSync = function(dir) {
  spawnSync('mkdir', ['-p', dir]);
}

const gitSync = function(repo, args) {
  return spawnSync('git', ['-C', repo].concat(args));
}

const checkoutLatestTag = function(vendorTargetPath) {
  gitSync(vendorTargetPath, ['fetch', '--tags']);
  const process = gitSync(vendorTargetPath, ['describe', '--abbrev=0', '--match', 'v*.*.*', '--tags']);
  const tagName = process.output.join("").replace(/\n$/, "");

  log.info("bugsnag", "checking out the " + tagName + " release");
  gitSync(vendorTargetPath, ['checkout', tagName]);
}

const updateVendorSubmodules = function(vendorTargetPath, cb) {
  log.info("bugsnag", "validating dependency repository");
  const process = gitSync(vendorTargetPath, ['submodule', 'update', '--init']);
  if (process.status != 0)
    cb(new Error("Failed to initialize dependencies"));
  else
    cb();
}

main();
