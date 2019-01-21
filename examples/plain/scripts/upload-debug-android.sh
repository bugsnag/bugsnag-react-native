#!/usr/bin/env bash
set -e

if [ -z "$API_KEY" ]; then
    export API_KEY=YOUR-API-KEY-HERE # set your own API key here, or as an environment variable
fi

if [ -z "$APP_VERSION" ]; then
    export APP_VERSION=1 # set your own app version here (using the Android versionCode)
fi

# Download debug source maps from Metro bundler
curl "http://localhost:8081/index.bundle?platform=android&dev=true&minify=false" > android-debug.bundle
curl "http://localhost:8081/index.bundle.map?platform=android&dev=true&minify=false" > android-debug.bundle.map

# Upload source maps to Bugsnag, making sure to specify the correct app-version.
bugsnag-sourcemaps upload \
    --api-key $API_KEY \
    --app-version $APP_VERSION \
    --minified-file android-debug.bundle \
    --source-map android-debug.bundle.map \
    --minified-url "http://10.0.2.2:8081/index.bundle?platform=android&dev=true&minify=false" \
    --overwrite
