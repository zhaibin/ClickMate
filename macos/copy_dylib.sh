#!/bin/bash
# Copy native library to app bundle

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DYLIB_SOURCE="$PROJECT_ROOT/native/src/libmouse_controller.dylib"

# For Debug build
DEBUG_FRAMEWORKS="$PROJECT_ROOT/build/macos/Build/Products/Debug/ClickMate.app/Contents/Frameworks"
if [ -d "$DEBUG_FRAMEWORKS" ] && [ -f "$DYLIB_SOURCE" ]; then
    cp "$DYLIB_SOURCE" "$DEBUG_FRAMEWORKS/"
    echo "Copied dylib to Debug Frameworks"
fi

# For Release build
RELEASE_FRAMEWORKS="$PROJECT_ROOT/build/macos/Build/Products/Release/ClickMate.app/Contents/Frameworks"
if [ -d "$RELEASE_FRAMEWORKS" ] && [ -f "$DYLIB_SOURCE" ]; then
    cp "$DYLIB_SOURCE" "$RELEASE_FRAMEWORKS/"
    echo "Copied dylib to Release Frameworks"
fi
