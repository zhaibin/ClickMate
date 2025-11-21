@echo off
chcp 65001 >nul
cd /d "%~dp0\.."

echo ========================================
echo   鼠标自动控制器 - 构建发布版
echo ========================================
echo.

:: 1. 检查DLL
echo [1/4] 检查DLL文件...
if not exist "native\src\mouse_controller.dll" (
    echo [!] 缺少 mouse_controller.dll
    pause
    exit /b 1
)
echo [OK] DLL文件存在
echo.

:: 2. Flutter构建
echo [2/4] 构建Release版本...
flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo [!] 构建失败
    pause
    exit /b 1
)
echo [OK] 构建完成
echo.

:: 3. 创建便携版
echo [3/4] 创建便携版...
set RELEASE_DIR=build\windows\x64\runner\Release
set VERSION=1.3.2
set OUTPUT_DIR=releases\v%VERSION%
set PORTABLE_DIR=%OUTPUT_DIR%\MouseControl_v%VERSION%_Portable

if not exist "releases" mkdir "releases"
if exist "%OUTPUT_DIR%" rmdir /s /q "%OUTPUT_DIR%"
mkdir "%OUTPUT_DIR%"
mkdir "%PORTABLE_DIR%"

:: 复制主程序和核心DLL
copy "%RELEASE_DIR%\mouse_control.exe" "%PORTABLE_DIR%\" >nul
copy "%RELEASE_DIR%\flutter_windows.dll" "%PORTABLE_DIR%\" >nul

:: 复制插件DLL
copy "%RELEASE_DIR%\window_manager_plugin.dll" "%PORTABLE_DIR%\" >nul
copy "%RELEASE_DIR%\screen_retriever_windows_plugin.dll" "%PORTABLE_DIR%\" >nul
copy "%RELEASE_DIR%\mouse_controller.dll" "%PORTABLE_DIR%\" >nul

:: 复制资源文件
xcopy "%RELEASE_DIR%\data" "%PORTABLE_DIR%\data\" /E /I /Y >nul

:: 创建使用说明
(
echo ========================================
echo   鼠标自动控制器 v%VERSION%
echo ========================================
echo.
echo 【重要】首次使用必读
echo --------------------
echo 1. 安装 Visual C++ 运行库^(如未安装^)
echo    下载：https://aka.ms/vs/17/release/vc_redist.x64.exe
echo.   
echo 2. 启动方式^(二选一^)：
echo    推荐：右键"启动.bat" - 以管理员身份运行
echo    或：右键"mouse_control.exe" - 以管理员身份运行
echo.
echo 3. 如果双击exe无反应，请查看"常见问题.txt"
echo.
echo.
echo 快捷键
echo --------------------
echo Ctrl + Shift + 1  开始/停止点击
echo Ctrl + Shift + 2  捕获鼠标位置
echo.
echo 注意：快捷键需要管理员权限
echo.
echo.
echo 功能说明
echo --------------------
echo - 自动跟踪模式^(默认^): 实时跟随鼠标位置
echo - 手动输入模式: 固定坐标点击
echo - 点击输入框可切换到手动模式
echo - 点击历史记录^(最近10次^)
echo - 毫秒级精度控制
echo.
echo.
echo 使用步骤
echo --------------------
echo 1. 右键"启动.bat"以管理员身份运行
echo 2. 设置点击间隔、随机范围等参数
echo 3. 移动鼠标到目标位置^(自动模式^)
echo    或手动输入坐标^(手动模式^)
echo 4. 按 Ctrl+Shift+1 开始点击
echo 5. 再按 Ctrl+Shift+1 停止点击
echo.
echo.
echo 文件说明
echo --------------------
echo mouse_control.exe              主程序
echo flutter_windows.dll            Flutter运行库
echo window_manager_plugin.dll      窗口管理插件
echo screen_retriever_windows_plugin.dll  屏幕信息插件
echo mouse_controller.dll           鼠标控制库
echo data/                          资源文件
echo 启动.bat                       启动脚本^(推荐使用^)
echo 使用说明.txt                   本文件
echo 常见问题.txt                   故障排查指南
echo.
echo.
echo 系统要求
echo --------------------
echo - Windows 10 或 Windows 11^(64位^)
echo - Visual C++ 2015-2022 运行库
echo - 管理员权限^(快捷键功能必需^)
echo.
echo.
echo 遇到问题？
echo --------------------
echo 请查看"常见问题.txt"获取详细帮助
) > "%PORTABLE_DIR%\使用说明.txt"

:: 创建启动脚本
(
echo @echo off
echo chcp 65001 ^>nul
echo cd /d "%%~dp0"
echo.
echo echo ========================================
echo echo   鼠标自动控制器 v%VERSION%
echo echo ========================================
echo echo.
echo.
echo :: 检查文件
echo echo [检查] 必需文件...
echo set MISSING=0
echo.
echo if not exist "mouse_control.exe" ^(
echo     echo [×] mouse_control.exe 缺失
echo     set MISSING=1
echo ^)
echo if not exist "flutter_windows.dll" ^(
echo     echo [×] flutter_windows.dll 缺失
echo     set MISSING=1
echo ^)
echo if not exist "window_manager_plugin.dll" ^(
echo     echo [×] window_manager_plugin.dll 缺失
echo     set MISSING=1
echo ^)
echo if not exist "screen_retriever_windows_plugin.dll" ^(
echo     echo [×] screen_retriever_windows_plugin.dll 缺失
echo     set MISSING=1
echo ^)
echo if not exist "mouse_controller.dll" ^(
echo     echo [×] mouse_controller.dll 缺失
echo     set MISSING=1
echo ^)
echo if not exist "data" ^(
echo     echo [×] data 文件夹缺失
echo     set MISSING=1
echo ^)
echo.
echo if %%MISSING%%==1 ^(
echo     echo.
echo     echo [!] 缺少必需文件，请重新解压完整的ZIP包
echo     pause
echo     exit /b 1
echo ^)
echo.
echo echo [✓] 所有文件完整
echo echo.
echo.
echo :: 检查管理员权限
echo echo [检查] 管理员权限...
echo net session ^>nul 2^>^&1
echo if %%errorlevel%% neq 0 ^(
echo     echo [!] 警告：未以管理员身份运行
echo     echo     快捷键功能可能无法使用
echo     echo.
echo     echo 建议：右键此文件 - 以管理员身份运行
echo     echo.
echo     choice /C YN /M "是否继续启动"
echo     if errorlevel 2 exit /b 0
echo ^) else ^(
echo     echo [✓] 已获得管理员权限
echo ^)
echo echo.
echo.
echo :: 启动应用
echo echo [启动] 鼠标自动控制器...
echo echo.
echo echo 如果程序无法启动，请查看错误信息：
echo echo ----------------------------------------
echo echo.
echo.
echo start "" "%%~dp0mouse_control.exe"
echo.
echo timeout /t 3 ^>nul
echo.
echo :: 检查进程
echo tasklist /FI "IMAGENAME eq mouse_control.exe" 2^>NUL ^| find /I /N "mouse_control.exe"^>NUL
echo if "%%ERRORLEVEL%%"=="0" ^(
echo     echo [✓] 程序已启动
echo ^) else ^(
echo     echo [×] 程序启动失败
echo     echo.
echo     echo 可能的原因：
echo     echo 1. 缺少 Visual C++ 运行库
echo     echo    下载地址: https://aka.ms/vs/17/release/vc_redist.x64.exe
echo     echo 2. 被杀毒软件拦截
echo     echo    请添加到白名单
echo     echo 3. Windows 版本不兼容
echo     echo    需要 Windows 10 或更高版本
echo     echo.
echo ^)
echo.
echo pause
) > "%PORTABLE_DIR%\启动.bat"

:: 创建常见问题文档
(
echo ========================================
echo   常见问题解答
echo ========================================
echo.
echo 问题1: 双击exe无反应
echo --------------------
echo 原因：
echo   - 缺少 Visual C++ 运行库
echo   - 被杀毒软件拦截
echo   - 文件损坏或不完整
echo.
echo 解决方法：
echo   1. 使用"启动.bat"脚本启动，查看详细错误信息
echo   2. 下载安装 Visual C++ 2015-2022 运行库
echo      https://aka.ms/vs/17/release/vc_redist.x64.exe
echo   3. 检查杀毒软件，将程序添加到白名单
echo   4. 确保完整解压了所有文件
echo   5. 右键exe - 属性 - 解除锁定
echo.
echo.
echo 问题2: 快捷键不工作
echo --------------------
echo 原因：
echo   - 未以管理员身份运行
echo.
echo 解决方法：
echo   1. 右键"启动.bat" - 以管理员身份运行
echo   2. 或右键"mouse_control.exe" - 以管理员身份运行
echo.
echo.
echo 问题3: 程序闪退或崩溃
echo --------------------
echo 原因：
echo   - 缺少DLL文件
echo   - 系统不兼容
echo.
echo 解决方法：
echo   1. 确保以下文件都在同一目录：
echo      - mouse_control.exe
echo      - flutter_windows.dll
echo      - window_manager_plugin.dll
echo      - screen_retriever_windows_plugin.dll
echo      - mouse_controller.dll
echo      - data文件夹
echo   2. 系统要求：Windows 10 或更高版本
echo   3. 尝试重新解压ZIP包
echo.
echo.
echo 问题4: 被杀毒软件报毒
echo --------------------
echo 说明：
echo   - 这是误报，程序是使用Flutter开发的正常应用
echo   - 因为使用了鼠标控制功能，可能被误判
echo.
echo 解决方法：
echo   1. 将整个文件夹添加到杀毒软件白名单
echo   2. 或暂时关闭杀毒软件
echo.
echo.
echo 问题5: 需要安装什么依赖吗
echo --------------------
echo 依赖：
echo   - Visual C++ 2015-2022 运行库^(x64^)
echo     下载：https://aka.ms/vs/17/release/vc_redist.x64.exe
echo   - Windows 10 或更高版本
echo.
echo 说明：
echo   - 无需安装.NET Framework
echo   - 无需安装Flutter SDK
echo   - 所有依赖已打包在程序中
echo.
echo.
echo 问题6: 如何正确启动
echo --------------------
echo 方法1^(推荐^)：
echo   右键"启动.bat" - 以管理员身份运行
echo.
echo 方法2：
echo   右键"mouse_control.exe" - 以管理员身份运行
echo.
echo 方法3^(如果不需要快捷键^)：
echo   直接双击"mouse_control.exe"
echo.
echo.
echo 系统要求
echo --------------------
echo - 操作系统：Windows 10 或 Windows 11
echo - 架构：64位^(x64^)
echo - 内存：至少 2GB RAM
echo - 磁盘空间：约 50MB
echo.
echo.
echo 联系支持
echo --------------------
echo 如果以上方法都无法解决问题，请提供：
echo 1. Windows 版本^(Win+R - winver^)
echo 2. "启动.bat"显示的错误信息
echo 3. 杀毒软件名称^(如果有^)
echo.
echo.
echo 版本：v%VERSION%
echo 更新日期：2024-11-21
) > "%PORTABLE_DIR%\常见问题.txt"

echo [OK] 便携版已创建
echo.

:: 4. 创建ZIP
echo [4/4] 打包ZIP...
powershell -Command "Compress-Archive -Path '%PORTABLE_DIR%\*' -DestinationPath '%OUTPUT_DIR%\鼠标自动控制器_v%VERSION%_便携版.zip' -Force"
echo [OK] ZIP已创建
echo.

echo ========================================
echo   发布文件已创建在: releases\v%VERSION%\
echo   - MouseControl_v%VERSION%_Portable\ (便携版文件夹)
echo   - 鼠标自动控制器_v%VERSION%_便携版.zip (分发文件)
echo ========================================
echo.
echo 发布路径: %CD%\%OUTPUT_DIR%
echo.
pause

