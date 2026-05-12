#!/usr/bin/env bash
# Build PPT Remote and assemble a runnable .app bundle in dist/.# Set the env variable $SIGN_ID if you want to sign the app with your dev id

set -euo pipefail

cd "$(dirname "$0")"

APP_NAME="PPT Remote"
EXEC_NAME="PPTRemote"
BUILD_DIR=".build/release"
DIST_DIR="dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"

echo "==> Building Swift package (release)…"
swift build -c release

if [[ ! -x "$BUILD_DIR/$EXEC_NAME" ]]; then
    echo "Build did not produce $BUILD_DIR/$EXEC_NAME" >&2
    exit 1
fi

echo "==> Assembling .app bundle…"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$EXEC_NAME" "$APP_BUNDLE/Contents/MacOS/$EXEC_NAME"
cp Info.plist "$APP_BUNDLE/Contents/Info.plist"
cp AppIcon.icns "$APP_BUNDLE/Contents/Resources/AppIcon.icns"

# SwiftPM emits resources into a <Package>_<Target>.bundle directory.
RESOURCE_BUNDLE="${EXEC_NAME}_${EXEC_NAME}.bundle"
if [[ -d "$BUILD_DIR/$RESOURCE_BUNDLE" ]]; then
    cp -R "$BUILD_DIR/$RESOURCE_BUNDLE" "$APP_BUNDLE/Contents/Resources/"
else
    echo "Warning: resource bundle $RESOURCE_BUNDLE not found in $BUILD_DIR" >&2
fi

echo "==> Signing…"
codesign --force --deep --sign "${SIGN_ID:--}" "$APP_BUNDLE"

echo
echo "Done. Run with:"
echo "    open \"$APP_BUNDLE\""
