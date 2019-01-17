#!/usr/bin/env bash

API_KEY=YOUR_API_KEY_HERE # set your own API key here
APP_VERSION=1 # set your own app version here (using the Android versionCode)

# Generate source maps using react-native bundler
cd ..
react-native bundle \
    --platform android \
    --dev false \
    --entry-file index.js \
    --bundle-output android-release.bundle \
    --sourcemap-output android-release.bundle.map

# Upload source maps to Bugsnag, making sure to specify the correct app-version.
bugsnag-sourcemaps upload \
    --api-key $API_KEY \
    --app-version $APP_VERSION \
    --minified-file android-release.bundle \
    --source-map android-release.bundle.map \
    --minified-url index.android.bundle \
    --upload-sources
