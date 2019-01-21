#!/usr/bin/env bash
set -e
cd ios
bugsnag-dsym-upload build/Build/Products/Release-iphonesimulator/
