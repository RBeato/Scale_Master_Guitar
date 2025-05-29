#!/bin/sh

# This script ensures SF2 files are properly copied to the app bundle
# It's designed to fix issues with SF2 files not playing in TestFlight builds

echo "Ensuring SF2 files are properly copied to the bundle..."

# Find the target build directory
TARGET_BUILD_DIR="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app"
RESOURCE_PATH="${TARGET_BUILD_DIR}/Frameworks/App.framework/flutter_assets/assets/sounds/sf2"

# Create the destination directory if it doesn't exist
mkdir -p "${TARGET_BUILD_DIR}/sf2_files"

# Copy all SF2 files to the app bundle directly
if [ -d "$RESOURCE_PATH" ]; then
  echo "Copying SF2 files from $RESOURCE_PATH to ${TARGET_BUILD_DIR}/sf2_files"
  cp -R "$RESOURCE_PATH/"* "${TARGET_BUILD_DIR}/sf2_files/"
  echo "SF2 files copied successfully"
else
  echo "Warning: SF2 resource path not found: $RESOURCE_PATH"
fi

# Set proper permissions
chmod -R 755 "${TARGET_BUILD_DIR}/sf2_files"

exit 0
