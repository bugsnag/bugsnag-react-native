#!/usr/bin/env bash
# Usage: ./release.sh [version number]

RELEASE_ID=$1
BUILD_DIR=build
if [ -z "$BUGSNAG_API_KEY" ]; then
    echo "Please set the BUGSNAG_API_KEY environment variable to continue."
    exit 1
fi
if [ -z "$RELEASE_ID" ]; then
    echo "No version number specified"
    echo "Usage: $0 [version number]"
    exit 1
fi
# Insert release identifier into the Bugsnag configuration
# (using macOS-specific sed arguments)
sed -e "2s/.*/const codeBundleId = \"$RELEASE_ID\"/" -i '' app/lib/bugsnag.js

# Release iOS App
## Release JS bundle via Code Push
code-push release-react BugsnagCodePushExample ios \
    --outputDir $BUILD_DIR

## Upload source map and sources to Bugsnag
bugsnag-sourcemaps upload \
    --api-key $BUGSNAG_API_KEY \
    --code-bundle-id $RELEASE_ID \
    --source-map $BUILD_DIR/main.jsbundle.map \
    --minified-file $BUILD_DIR/main.jsbundle \
    --minified-url main.jsbundle \
    --upload-sources \
    --add-wildcard-prefix

# Release Android App
## Release JS bundle via Code Push
code-push release-react BugsnagCodePushExample android \
    --outputDir $BUILD_DIR

## Upload source map and sources to Bugsnag
bugsnag-sourcemaps upload \
    --api-key $BUGSNAG_API_KEY \
    --code-bundle-id $RELEASE_ID \
    --source-map $BUILD_DIR/index.android.bundle.map \
    --minified-file $BUILD_DIR/index.android.bundle \
    --minified-url index.android.bundle \
    --upload-sources \
    --add-wildcard-prefix
