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

# Step 3: Build native library
echo -e "${YELLOW}[3/6] Building native library...${NC}"
cd "$PROJECT_ROOT/native/src"

# Check if dylib already exists and is recent
if [ -f "libmouse_controller.dylib" ]; then
    echo "Found existing libmouse_controller.dylib"
else
    echo "Compiling libmouse_controller.dylib..."
    clang++ -shared -fPIC \
        -framework Cocoa \
        -framework Carbon \
        -framework CoreGraphics \
        -o libmouse_controller.dylib \
        mouse_controller_macos.mm
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Error: Failed to compile native library${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ Native library ready${NC}"
echo ""

# Step 4: Build release
echo -e "${YELLOW}[4/6] Building macOS release...${NC}"
cd "$PROJECT_ROOT"
flutter build macos --release
echo -e "${GREEN}✓ Build completed${NC}"
echo ""

# Check if app was built successfully
if [ ! -d "$APP_PATH" ]; then
    echo -e "${RED}✗ Error: App not found at $APP_PATH${NC}"
    exit 1
fi

# Step 4.5: Copy dylib into app bundle
echo -e "${YELLOW}[4.5/6] Copying native library into app bundle...${NC}"
FRAMEWORKS_DIR="$APP_PATH/Contents/Frameworks"
mkdir -p "$FRAMEWORKS_DIR"

# Copy the dylib
cp "$PROJECT_ROOT/native/src/libmouse_controller.dylib" "$FRAMEWORKS_DIR/"

# Update dylib install name to use @executable_path
install_name_tool -id "@executable_path/../Frameworks/libmouse_controller.dylib" \
    "$FRAMEWORKS_DIR/libmouse_controller.dylib"

echo -e "${GREEN}✓ Native library copied to app bundle${NC}"
echo ""

# Step 5: Create releases directory
echo -e "${YELLOW}[5/6] Preparing release directory...${NC}"
mkdir -p "$RELEASES_DIR"
echo -e "${GREEN}✓ Directory ready: $RELEASES_DIR${NC}"
echo ""

# Step 6: Create DMG
echo -e "${YELLOW}[6/6] Creating DMG...${NC}"

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

# Create installation guide
GUIDE_FILE="$RELEASES_DIR/macOS_安装说明.txt"
cat > "$GUIDE_FILE" << 'EOF'
# ClickMate macOS 安装指南

## 安装步骤

1. 打开 DMG 文件
2. 将 ClickMate.app 拖入「应用程序」文件夹
3. 打开「应用程序」文件夹，找到 ClickMate

## ⚠️ 如果显示"已损坏"或"无法打开"

这是 macOS 安全机制导致的，请按以下步骤解决：

### 方法1：终端命令（推荐，最简单）

打开「终端」（在启动台或应用程序/实用工具中），复制粘贴以下命令：

    xattr -cr /Applications/ClickMate.app

然后按回车键执行。

### 方法2：右键打开

1. 右键点击（或按住 Control 点击）ClickMate.app
2. 选择「打开」
3. 在弹出对话框中点击「打开」

### 方法3：系统设置允许

1. 尝试打开 ClickMate（会显示错误）
2. 打开「系统偏好设置」→「安全性与隐私」
3. 点击「仍要打开」按钮

## 辅助功能权限

ClickMate 需要辅助功能权限才能控制鼠标：

1. 打开「系统偏好设置」→「安全性与隐私」→「隐私」
2. 选择左侧的「辅助功能」
3. 点击锁图标解锁（需要输入密码）
4. 点击「+」按钮，添加 ClickMate
5. 勾选 ClickMate 旁边的复选框
6. 重启 ClickMate

## 为什么会出现"已损坏"？

这是因为应用未经过 Apple 代码签名。这是正常的，上述解决方案是安全的。

## 详细文档

更多信息请访问：
https://github.com/zhaibin/ClickMate/blob/master/docs/macOS_INSTALL_GUIDE.md

---

如有问题，请在 GitHub 提交 issue。
EOF

echo -e "${GREEN}✓ Installation guide created: $GUIDE_FILE${NC}"
echo ""

echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Test the DMG by opening it and running the app"
echo "2. Verify mouse click functionality works"
echo "3. Check accessibility permission prompt appears"
echo "4. Read the installation guide: macOS_安装说明.txt"
echo ""
echo -e "${YELLOW}For users who see 'damaged' error:${NC}"
echo "  Run: xattr -cr /Applications/ClickMate.app"
echo ""
echo -e "${YELLOW}For code signing (optional but recommended):${NC}"
echo "  codesign --force --deep --sign \"Developer ID Application: YOUR_NAME\" \"$APP_PATH\""
echo "  codesign --force --sign \"Developer ID Application: YOUR_NAME\" \"$DMG_PATH\""
echo ""

