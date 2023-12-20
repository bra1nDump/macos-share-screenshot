#!/bin/bash

# Change YOUR_SCHEME_NAME to your actual scheme name
SCHEME=CaptureSample

# Create a desired build output path using current directory /build folder
BUILD_OUTPUT_PATH="$PWD/build/debug/"

# Build macos application
xcodebuild -scheme $SCHEME -configuration Debug CONFIGURATION_BUILD_DIR=$BUILD_OUTPUT_PATH

# Get the path to the built application
APP_PATH="$BUILD_OUTPUT_PATH/$SCHEME.app"

echo "Built application path: $APP_PATH, provide this in the launch config"
