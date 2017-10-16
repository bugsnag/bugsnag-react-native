#!/usr/bin/env bash

if [[ ! "$CONFIGURATION" == Debug ]]; then
DEST=$CONFIGURATION_BUILD_DIR/$UNLOCALIZED_RESOURCES_FOLDER_PATH
APP_VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "${PROJECT_DIR}/${INFOPLIST_FILE}")
BUGSNAG_API_KEY=$(/usr/libexec/PlistBuddy -c "Print BugsnagAPIKey" "${PROJECT_DIR}/${INFOPLIST_FILE}")

npm run bundle -- \
  --entry-file index.ios.js \
  --platform ios \
  --dev false \
  --bundle-output "$DEST/main.jsbundle" \
  --sourcemap-output ios.bundle.map \
  --assets-dest "$DEST"
bugsnag-sourcemaps upload \
  --api-key "$BUGSNAG_API_KEY" \
  --app-version "$APP_VERSION" \
  --minified-file "$DEST/main.jsbundle" \
  --source-map ios.bundle.map \
  --minified-url "main.jsbundle" \
  --upload-sources
fi
