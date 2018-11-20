#!/usr/bin/env bash

cd features/fixtures/sampler

function launch_app() {
react-native run-android \
    --variant=Release \
    --no-packager
}

echo "{\"name\": \"$EVENT_TYPE\"}" > scenario.json
launch_app

sleep 2s

echo "{\"name\": \"none\"}" > scenario.json
launch_app

sleep 2s
