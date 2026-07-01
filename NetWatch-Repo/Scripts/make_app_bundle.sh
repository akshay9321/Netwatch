#!/bin/bash
set -e
APP_NAME="NetWatch"

BIN_PATH=""
for candidate in ".build/apple/Products/Release/$APP_NAME" ".build/release/$APP_NAME" ".build/x86_64-apple-macosx/release/$APP_NAME" ".build/arm64-apple-macosx/release/$APP_NAME"; do
  if [ -f "$candidate" ]; then
    BIN_PATH="$candidate"
    break
  fi
done

if [ -z "$BIN_PATH" ]; then
  echo "ERROR: could not find built binary. Searched .build for executables:" >&2
  find .build -maxdepth 5 -type f -perm +111 2>/dev/null
  exit 1
fi

echo "Using binary at: $BIN_PATH"
file "$BIN_PATH" || true

APP_BUNDLE="dist/$APP_NAME.app"
rm -rf dist
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BIN_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp Resources/Info.plist "$APP_BUNDLE/Contents/Info.plist"

cd dist
zip -r "$APP_NAME.app.zip" "$APP_NAME.app"
echo "Bundle ready: dist/$APP_NAME.app.zip"
