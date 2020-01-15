#!/usr/bin/env bash

set -e pipefail

mkdir -p tmp-projects
cd tmp-projects
echo '{}' > package.json
npm install react-native-cli@2.0.1 --save
./node_modules/.bin/react-native init --version="react-native@0.61.5" MyProject61
cd MyProject61
npm install ../../bugsnag-react-native-*.tgz --save
cd ios
pod install

xcodebuild -workspace MyProject61.xcworkspace \
           -scheme MyProject61 build \
           -sdk iphonesimulator -quiet

