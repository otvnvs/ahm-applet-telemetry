#!/bin/bash
if [ ! -f "app.json" ]; then
    echo "Error: app.json not found in the current directory."
    exit 1
fi
APP_NAME=$(jq -r '.name' app.json)
if [ -z "$APP_NAME" ] || [ "$APP_NAME" == "null" ]; then
    echo "Error: Could not parse a valid 'name' field from app.json."
    exit 1
fi
TARGET_DIR="$HOME/storage/shared/Documents/MyHybridMobile/www/src/apps/$APP_NAME"
echo "Preparing deployment target for app: [$APP_NAME]..."
if [ -d "$TARGET_DIR" ]; then
    echo "Clearing previous version directory at: $TARGET_DIR"
    rm -rf "$TARGET_DIR"
fi
mkdir -p "$TARGET_DIR"
cp -r ./* "$TARGET_DIR"
echo "Deployment completed successfully to: $TARGET_DIR"
