#!/usr/bin/env bash
set -e

if [ -z "$API_KEY" ]; then
    export API_KEY=YOUR-API-KEY-HERE # set your own API key here, or as an environment variable
fi

if [ -z "$APP_VERSION" ]; then
    export APP_VERSION=1 # set your own app version here (using the iOS build number)
fi

# Generate source maps using react-native bundler
cd ..
react-native bundle \
    --platform ios \
    --dev false \
    --entry-file index.js \
    --bundle-output ios-release.bundle \
    --sourcemap-output ios-release.bundle.map

# Upload source maps to Bugsnag, making sure to specify the correct app-version.
bugsnag-sourcemaps upload \
    --api-key $API_KEY \
    --app-version $APP_VERSION \
    --minified-file ios-release.bundle \
    --source-map ios-release.bundle.map \
    --minified-url main.jsbundle \
    --upload-sources \
    --overwrite
