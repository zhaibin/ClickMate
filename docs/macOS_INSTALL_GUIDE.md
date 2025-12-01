# macOS Installation Guide / macOS 安装指南

## 🍎 Installation Steps / 安装步骤

### Method 1: From DMG / 从 DMG 安装

1. **Download** the DMG file
   - 下载 `ClickMate_vX.X.X_macOS.dmg` 文件

2. **Open** the DMG file
   - 双击打开 DMG 文件

3. **Drag** ClickMate.app to Applications folder
   - 将 ClickMate.app 拖入「应用程序」文件夹

4. **Launch** the application
   - 从「启动台」或「应用程序」文件夹打开 ClickMate

---

## ⚠️ Troubleshooting / 故障排除

### Problem 1: "ClickMate is damaged and can't be opened" / "ClickMate 已损坏，无法打开"

**原因 / Cause:**
macOS Gatekeeper blocks unsigned applications downloaded from the internet.

macOS 安全机制阻止了从互联网下载的未签名应用。

**Solution / 解决方案:**

#### Option A: Remove Quarantine Attribute (Recommended) / 移除隔离属性（推荐）

Open Terminal and run:
打开「终端」并执行：

```bash
xattr -cr /Applications/ClickMate.app
```

Or if the app is in another location:
如果应用在其他位置：

```bash
xattr -cr ~/Downloads/ClickMate.app
```

**What this does:** Removes the quarantine attribute that macOS adds to downloaded files.
**作用：** 移除 macOS 添加到下载文件的隔离属性。

#### Option B: Allow in System Preferences / 在系统偏好设置中允许

1. Try to open ClickMate (it will show the error)
   尝试打开 ClickMate（会显示错误）

2. Open **System Preferences** → **Security & Privacy**
   打开 **系统偏好设置** → **安全性与隐私**

3. Click **"Open Anyway"** button
   点击 **"仍要打开"** 按钮

4. Confirm by clicking **"Open"**
   确认点击 **"打开"**

---

### Problem 2: "Cannot open because it is from an unidentified developer" / "无法打开，因为来自身份不明的开发者"

**Solution / 解决方案:**

#### Method 1: Right-click to Open / 右键点击打开

1. **Right-click** (or Control-click) on ClickMate.app
   **右键点击**（或按住 Control 点击）ClickMate.app

2. Select **"Open"** from the menu
   从菜单中选择 **"打开"**

3. Click **"Open"** in the dialog
   在对话框中点击 **"打开"**

#### Method 2: Terminal Command / 终端命令

```bash
# Remove quarantine attribute
xattr -cr /Applications/ClickMate.app

# Open the app
open /Applications/ClickMate.app
```

---

### Problem 3: Accessibility Permission Required / 需要辅助功能权限

ClickMate requires **Accessibility** permission to control mouse and register hotkeys.
ClickMate 需要 **辅助功能** 权限来控制鼠标和注册快捷键。

**Steps / 步骤:**

1. Open **System Preferences** → **Security & Privacy** → **Privacy**
   打开 **系统偏好设置** → **安全性与隐私** → **隐私**

2. Select **Accessibility** in the left panel
   在左侧面板选择 **辅助功能**

3. Click the **lock icon** 🔒 and enter password to unlock
   点击 **锁图标** 🔒 并输入密码解锁

4. Click **"+"** button and add ClickMate.app
   点击 **"+"** 按钮并添加 ClickMate.app

5. Check the box next to ClickMate
   勾选 ClickMate 旁边的复选框

6. **Restart** ClickMate for changes to take effect
   **重启** ClickMate 使更改生效

---

## 🔐 Why These Steps Are Needed / 为什么需要这些步骤

### Code Signing / 代码签名

- ClickMate is currently **not code-signed** with an Apple Developer certificate
  ClickMate 目前 **未使用** Apple 开发者证书进行代码签名

- macOS Gatekeeper blocks unsigned apps by default for security
  macOS Gatekeeper 默认阻止未签名应用以保护安全

- The `xattr` command removes the quarantine flag safely
  `xattr` 命令可以安全地移除隔离标记

### Accessibility Permission / 辅助功能权限

- Required for:
  需要用于：
  - Mouse control and clicking / 鼠标控制和点击
  - Global hotkey registration / 全局快捷键注册
  - Screen coordinate access / 屏幕坐标访问

---

## 📝 One-Line Installation / 一键安装

For advanced users, you can use this one-liner:
高级用户可以使用此一键命令：

```bash
# Download, install, and allow ClickMate
cd /Applications && xattr -cr ClickMate.app && open ClickMate.app
```

---

## 🛡️ Is This Safe? / 这样做安全吗？

**Yes, removing the quarantine attribute is safe** when you trust the source.
**是的，移除隔离属性是安全的**，前提是你信任下载来源。

- You can verify the app contents before removing the attribute
  在移除属性前，你可以验证应用内容

- This is a standard solution for distributing unsigned macOS apps
  这是分发未签名 macOS 应用的标准解决方案

- Future versions may include code signing to avoid this step
  未来版本可能会包含代码签名以避免此步骤

---

## 🔄 Alternative: Build from Source / 替代方案：从源代码构建

If you prefer to build from source:
如果你更喜欢从源代码构建：

```bash
# Clone the repository
git clone https://github.com/zhaibin/ClickMate.git
cd ClickMate

# Build DMG
bash scripts/build_dmg.sh

# Install
open releases/v*/ClickMate_v*_macOS.dmg
```

---

## 📞 Support / 技术支持

If you encounter other issues:
如果遇到其他问题：

1. Check the [README.md](../README.md) for general information
   查看 [README.md](../README.md) 了解基本信息

2. Review the [Build Guide](BUILD_GUIDE.md) for technical details
   查看[构建指南](BUILD_GUIDE.md)了解技术细节

3. Submit an issue on GitHub
   在 GitHub 上提交 issue

---

**Last Updated**: 2025-12-01  
**Version**: 2.1.0

