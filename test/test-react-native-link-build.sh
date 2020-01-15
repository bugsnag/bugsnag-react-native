#!/usr/bin/env bash

set -e pipefail

if [ -z "$REACT_NATIVE_VERSION" ]; then
    export REACT_NATIVE_VERSION=0.59.10
fi

export PROJ_DIR=MyProject_${REACT_NATIVE_VERSION//./}

mkdir -p tmp-projects
cd tmp-projects
echo '{}' > package.json
npm install react-native-cli@2.0.1 --save
./node_modules/.bin/react-native init --version="react-native@$REACT_NATIVE_VERSION" "$PROJ_DIR"
cd "$PROJ_DIR"
npm install ../../bugsnag-react-native-*.tgz --save
./node_modules/.bin/react-native link
cd ios
xcodebuild -project "$PROJ_DIR.xcodeproj" \
           -scheme "$PROJ_DIR" build \
           -sdk iphonesimulator -quiet \
           -UseModernBuildSystem=NO # https://github.com/facebook/react-native/issues/20492

