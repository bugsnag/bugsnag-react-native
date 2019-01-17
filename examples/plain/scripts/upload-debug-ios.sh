#!/usr/bin/env bash

API_KEY=YOUR_API_KEY_HERE # set your own API key here
APP_VERSION=1 # set your own app version here (using the iOS build number)

# Download debug source maps from Metro bundler
curl "http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false" > ios-debug.bundle
curl "http://localhost:8081/index.bundle.map?platform=ios&dev=true&minify=false" > ios-debug.bundle.map

# Upload source maps to Bugsnag, making sure to specify the correct app-version.
bugsnag-sourcemaps upload \
    --api-key $API_KEY \
    --app-version $APP_VERSION \
    --minified-file ios-debug.bundle \
    --source-map ios-debug.bundle.map \
    --minified-url "http://localhost:8081/index.bundle?platform=ios&dev=true&minify=false"
