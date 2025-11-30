# ClickMate

跨平台智能鼠标自动点击工具，支持 Windows 和 macOS，具备全局快捷键、自动跟踪和点击历史记录功能。

## ✨ 主要功能

- 🖱️ 自动鼠标点击（左键/右键/中键）
- 🎯 自动跟踪模式/手动输入模式
- ⌨️ 全局快捷键（Ctrl+Shift+1/2）
- 📊 点击历史记录（最近10次，毫秒精度）
- 🎲 随机间隔和位置偏移
- 💾 配置管理（保存/加载/重命名/删除多个配置）
- 🔄 智能鼠标移动（手动移动按钮 + 加载配置自动移动）
- ⚡ 恢复默认设置按钮
- 🌍 多语言支持（11种语言：英语/简中/繁中/法语/西语/葡语/德语/俄语/意语/日语/韩语）
- 🎯 系统语言自动检测

## 🚀 快速开始

### 方式1：直接启动（推荐）
```bash
START.bat
```
自动检查DLL、提示管理员权限、启动应用

### 方式2：调试模式
```bash
scripts\run_debug.bat
```
显示详细日志，适合开发调试

### 方式3：管理员模式
```bash
scripts\run_as_admin.bat
```
以管理员身份运行（快捷键必需）

## 📦 打包发布

```bash
scripts\build_release.bat
```

自动完成：
1. 检查DLL文件
2. 构建Release版本
3. 创建便携版文件夹
4. 打包ZIP压缩包

输出文件：
- Windows 安装包: `ClickMate-Installer\Output\ClickMate_v2.0.0_Setup.exe`
- macOS DMG: `ClickMate_v2.0.0.dmg`

## 📖 使用说明

### 自动跟踪模式（默认）
1. 启动应用后自动开启
2. 实时跟随鼠标位置
3. 按 `Ctrl+Shift+1` 开始点击
4. 再按 `Ctrl+Shift+1` 停止

### 手动输入模式
1. 点击X或Y输入框切换到手动模式
2. 输入固定坐标
3. 点击"移动"按钮测试鼠标位置（可选）
4. 或点击🔄按钮切换模式

### 配置管理
1. 点击标题栏菜单 → "管理配置"
2. 点击"开始点击"时自动保存当前配置
3. 加载配置时自动恢复所有参数
4. 加载配置后鼠标自动移到目标位置
5. 支持重命名和删除配置
6. 重启应用自动加载上次使用的配置

### 快捷键
- **Ctrl+Shift+1** - 开始/停止点击
- **Ctrl+Shift+2** - 捕获当前鼠标位置

### 点击历史

窗口底部显示最近10次点击记录：
- **序号** - 1-10
- **时间** - HH:MM:SS.mmm（精确到毫秒）
- **位置** - (X, Y)
- **按键** - 左键(蓝)/右键(橙)/中键(紫)

## 🔧 技术栈

- Flutter 3.10+ / C++ / Windows API
- window_manager 0.5.1
- FFI (Foreign Function Interface)

## 📁 项目结构

```
mouse_control/
├── START.bat                    # 快捷启动入口
├── README.md                    # 项目说明
├── CHANGELOG.md                 # 更新日志
├── scripts/                     # 所有脚本
│   ├── START.bat               # 主启动脚本
│   ├── run_debug.bat           # 调试模式
│   ├── run_as_admin.bat        # 管理员模式
│   ├── build_release.bat       # 发布打包
│   ├── diagnose.bat            # 诊断工具
│   └── test_hotkey.bat         # 快捷键测试
├── docs/                        # 详细文档
│   ├── BUILD_GUIDE.md          # 构建指南
│   └── 打包发布指南.md          # 打包说明
├── logs/                        # 日志文件
├── lib/                         # Flutter代码
│   ├── main.dart
│   ├── mouse_controller_service.dart
│   └── mouse_controller_bindings.dart
└── native/src/                  # C++ DLL
    ├── mouse_controller.cpp
    ├── mouse_controller.h
    └── mouse_controller.dll
```

## 🛠️ 开发调试

### 诊断工具
```bash
scripts\diagnose.bat
```
检查：DLL文件、Flutter环境、Windows版本、管理员权限

### 快捷键测试
```bash
scripts\test_hotkey.bat
```
专门测试快捷键功能，显示详细日志

## ⚠️ 注意事项

1. **管理员权限** - 快捷键功能必须以管理员身份运行
2. **DLL文件** - 确保`mouse_controller.dll`在`native/src/`目录
3. **快捷键冲突** - 如果冲突可在应用内更改
4. **合法使用** - 请勿在禁止脚本的游戏中使用

## 🐛 常见问题

**Q: 快捷键不工作？**
- 右键以管理员身份运行 `scripts\run_as_admin.bat`
- 或运行 `scripts\diagnose.bat` 检查问题
- 查看控制台是否显示"热键注册: 成功"

**Q: 找不到DLL文件？**
- 运行 `scripts\diagnose.bat` 检查DLL位置
- 确保 `native/src/mouse_controller.dll` 存在

**Q: 打包后无法运行？**
- 使用 `scripts\build_release.bat` 自动打包
- 确保所有文件在同一目录

**Q: 界面显示不完整？**
- 窗口固定为520x680
- 重启应用恢复

## 📊 版本信息

**当前版本**: v2.0.0  
**发布日期**: 2025-11-30  
**支持系统**: Windows 10/11, macOS 10.15+

### v2.0.0 新功能 🎉
- 🍎 **macOS 支持** - 完整的 macOS 原生集成
- 🎨 **统一设计语言** - 跨平台一致的视觉体验
- 🔐 **Windows 自签名** - 减少 SmartScreen 警告
- 📦 **安装包分发** - Windows 使用安装程序，macOS 使用 DMG
- 🌍 **简化语言选择** - 直接选择语言，无"跟随系统"选项

### v1.1.0 功能
- 💾 配置管理系统（保存/加载/重命名/删除配置）
- 🔄 智能鼠标移动功能
- ⚡ 恢复默认设置按钮
- 🌍 11种语言支持

## 📄 许可证

本项目仅供学习和个人使用。

---

🎉 **开始使用**: `START.bat`  
📖 **详细说明**: [docs/BUILD_GUIDE.md](docs/BUILD_GUIDE.md)  
📦 **打包指南**: [docs/打包发布指南.md](docs/打包发布指南.md)
