#!/bin/bash
# ============================================================
# ClickMate DMG Build Script
# For self-distribution (non-App Store)
# ============================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory and project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Read version from VERSION file
VERSION=$(cat "$PROJECT_ROOT/VERSION" | tr -d '\n\r ')
APP_NAME="ClickMate"
DMG_NAME="${APP_NAME}_v${VERSION}_macOS"

# Directories
BUILD_DIR="$PROJECT_ROOT/build/macos/Build/Products/Release"
RELEASES_DIR="$PROJECT_ROOT/releases/v${VERSION}"
APP_PATH="$BUILD_DIR/${APP_NAME}.app"

echo -e "${BLUE}============================================${NC}"
echo -e "${BLUE}  ClickMate DMG Builder v${VERSION}${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""

# Step 1: Clean previous build
echo -e "${YELLOW}[1/5] Cleaning previous build...${NC}"
cd "$PROJECT_ROOT"
flutter clean
echo -e "${GREEN}✓ Clean completed${NC}"
echo ""

# Step 2: Get dependencies
echo -e "${YELLOW}[2/5] Getting dependencies...${NC}"
flutter pub get
echo -e "${GREEN}✓ Dependencies ready${NC}"
echo ""

# Step 3: Build release
echo -e "${YELLOW}[3/5] Building macOS release...${NC}"
flutter build macos --release
echo -e "${GREEN}✓ Build completed${NC}"
echo ""

# Check if app was built successfully
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}✗ Error: App not found at $APP_PATH${NC}"
    exit 1
fi

# Step 4: Create releases directory
echo -e "${YELLOW}[4/5] Preparing release directory...${NC}"
mkdir -p "$RELEASES_DIR"
echo -e "${GREEN}✓ Directory ready: $RELEASES_DIR${NC}"
echo ""

# Step 5: Create DMG
echo -e "${YELLOW}[5/5] Creating DMG...${NC}"

DMG_PATH="$RELEASES_DIR/${DMG_NAME}.dmg"
TEMP_DMG_PATH="$RELEASES_DIR/${DMG_NAME}_temp.dmg"

# Remove existing DMG if present
rm -f "$DMG_PATH" "$TEMP_DMG_PATH"

# Check if create-dmg is installed
if command -v create-dmg &> /dev/null; then
    echo "Using create-dmg for professional DMG..."
    
    create-dmg \
        --volname "$APP_NAME" \
        --volicon "$PROJECT_ROOT/assets/icons/icon.png" \
        --window-pos 200 120 \
        --window-size 600 400 \
        --icon-size 100 \
        --icon "$APP_NAME.app" 150 185 \
        --hide-extension "$APP_NAME.app" \
        --app-drop-link 450 185 \
        --no-internet-enable \
        "$DMG_PATH" \
        "$APP_PATH"
else
    echo "Using hdiutil for basic DMG (install create-dmg for better results)..."
    echo "  brew install create-dmg"
    echo ""
    
    # Create temporary directory for DMG contents
    TEMP_DIR=$(mktemp -d)
    cp -R "$APP_PATH" "$TEMP_DIR/"
    
    # Create symbolic link to Applications
    ln -s /Applications "$TEMP_DIR/Applications"
    
    # Create DMG using hdiutil
    hdiutil create -volname "$APP_NAME" \
        -srcfolder "$TEMP_DIR" \
        -ov -format UDZO \
        "$DMG_PATH"
    
    # Clean up
    rm -rf "$TEMP_DIR"
fi

echo -e "${GREEN}✓ DMG created${NC}"
echo ""

# Summary
echo -e "${BLUE}============================================${NC}"
echo -e "${GREEN}  Build Successful!${NC}"
echo -e "${BLUE}============================================${NC}"
echo ""
echo -e "App:     ${APP_PATH}"
echo -e "DMG:     ${DMG_PATH}"
echo -e "Version: ${VERSION}"
echo ""

# Get DMG file size
if [ -f "$DMG_PATH" ]; then
    DMG_SIZE=$(du -h "$DMG_PATH" | cut -f1)
    echo -e "DMG Size: ${DMG_SIZE}"
fi

echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Test the DMG by opening it and running the app"
echo "2. Verify mouse click functionality works"
echo "3. Check accessibility permission prompt appears"
echo ""
echo -e "${YELLOW}For code signing (optional but recommended):${NC}"
echo "  codesign --force --deep --sign \"Developer ID Application: YOUR_NAME\" \"$APP_PATH\""
echo "  codesign --force --sign \"Developer ID Application: YOUR_NAME\" \"$DMG_PATH\""
echo ""

