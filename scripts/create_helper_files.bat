@echo off
chcp 65001 >nul

:: 接收参数：目标目录 和 版本号
set TARGET_DIR=%~1
set VERSION=%~2

if "%TARGET_DIR%"=="" (
    echo [ERROR] Usage: create_helper_files.bat ^<target_dir^> ^<version^>
    exit /b 1
)

:: ========================================
:: 1. 创建启动脚本（启动.bat）
:: ========================================
(
echo @echo off
echo chcp 65001 ^>nul
echo cd /d "%%~dp0"
echo.
echo :: ========================================
echo :: 鼠标自动控制器 - 启动脚本 v%VERSION%
echo :: ========================================
echo echo.
echo echo 正在启动鼠标自动控制器...
echo echo.
echo.
echo :: 检查必要文件
echo if not exist "mouse_control.exe" ^(
echo     echo [错误] 找不到 mouse_control.exe
echo     echo 请确保您在正确的目录中运行此脚本。
echo     pause
echo     exit /b 1
echo ^)
echo.
echo if not exist "flutter_windows.dll" ^(
echo     echo [错误] 找不到 flutter_windows.dll
echo     echo 请重新下载完整的安装包。
echo     pause
echo     exit /b 1
echo ^)
echo.
echo if not exist "window_manager_plugin.dll" ^(
echo     echo [错误] 找不到 window_manager_plugin.dll
echo     echo 请重新下载完整的安装包。
echo     pause
echo     exit /b 1
echo ^)
echo.
echo if not exist "screen_retriever_windows_plugin.dll" ^(
echo     echo [错误] 找不到 screen_retriever_windows_plugin.dll
echo     echo 请重新下载完整的安装包。
echo     pause
echo     exit /b 1
echo ^)
echo.
echo if not exist "mouse_controller.dll" ^(
echo     echo [错误] 找不到 mouse_controller.dll
echo     echo 请重新下载完整的安装包。
echo     pause
echo     exit /b 1
echo ^)
echo.
echo if not exist "data" ^(
echo     echo [错误] 找不到 data 文件夹
echo     echo 请重新下载完整的安装包。
echo     pause
echo     exit /b 1
echo ^)
echo.
echo :: 检查管理员权限
echo net session ^>nul 2^>^&1
echo if %%ERRORLEVEL%% NEQ 0 ^(
echo     echo ========================================
echo     echo   ⚠️  建议以管理员身份运行
echo     echo ========================================
echo     echo.
echo     echo 快捷键功能需要管理员权限才能正常工作。
echo     echo.
echo     echo 是否以管理员身份重新运行？
echo     echo.
echo     choice /C YN /M "请选择 [Y]是 [N]否"
echo     if %%ERRORLEVEL%% EQU 1 ^(
echo         powershell -Command "Start-Process '%%~f0' -Verb RunAs"
echo         exit
echo     ^) else ^(
echo         echo.
echo         echo 继续以普通权限运行...
echo         echo 注意：快捷键功能可能无法使用。
echo         echo.
echo         timeout /t 2 ^>nul
echo     ^)
echo ^)
echo.
echo :: 启动程序
echo echo [✓] 所有检查通过，正在启动...
echo echo.
echo start "" "%%~dp0mouse_control.exe"
echo.
echo :: 等待程序窗口出现
echo timeout /t 2 /nobreak ^>nul
echo.
echo echo ========================================
echo echo   程序已启动
echo echo ========================================
echo echo.
echo echo 提示：
echo echo - 默认快捷键：Ctrl+Shift+1 ^(开始/停止^)
echo echo - 捕获位置：Ctrl+Shift+2
echo echo - 如果快捷键无效，请以管理员身份运行此脚本
echo echo - 日志文件位置：%%USERPROFILE%%\Documents\MouseControl\logs
echo echo.
echo echo 如果程序窗口没有出现，可能的原因：
echo echo 1. 缺少 Visual C++ 运行库 ^(请安装 VC++ Redistributable^)
echo echo 2. 杀毒软件拦截 ^(请添加信任^)
echo echo 3. Windows 版本过低 ^(需要 Windows 10 或更高版本^)
echo echo.
echo echo 请查看日志获取详细错误信息：
echo echo %%USERPROFILE%%\Documents\MouseControl\logs\app_*.log
echo echo.
echo pause
) > "%TARGET_DIR%\启动.bat"

:: ========================================
:: 2. 创建使用说明（使用说明.txt）
:: ========================================
(
echo ========================================
echo   鼠标自动控制器 v%VERSION% - 使用说明
echo ========================================
echo.
echo 一、快速开始
echo ------------
echo 1. 双击"启动.bat"启动程序
echo 2. 建议以管理员身份运行^(快捷键功能需要^)
echo 3. 首次使用请先测试基本功能
echo.
echo.
echo 二、主要功能
echo ------------
echo ✓ 自动鼠标点击
echo ✓ 可选左键/右键/中键
echo ✓ 自定义点击间隔
echo ✓ 随机时间偏移
echo ✓ 随机位置偏移
echo ✓ 全局快捷键控制
echo ✓ 点击历史记录
echo.
echo.
echo 三、操作模式
echo ------------
echo 【自动跟踪模式】^(默认^)
echo - 实时跟随鼠标位置
echo - 绿色"自动"标签
echo - 适合需要随时调整位置的场景
echo.
echo 【手动输入模式】
echo - 点击X或Y输入框切换
echo - 或点击🔄按钮切换
echo - 灰色"手动"标签
echo - 适合固定位置重复点击
echo.
echo.
echo 四、快捷键
echo ----------
echo Ctrl+Shift+1  开始/停止自动点击
echo Ctrl+Shift+2  捕获当前鼠标位置
echo.
echo ⚠️ 注意：
echo - 快捷键需要管理员权限
echo - 如果无效请右键"启动.bat"选择"以管理员身份运行"
echo.
echo.
echo 五、参数说明
echo ------------
echo 【点击间隔】
echo - 两次点击之间的时间^(毫秒^)
echo - 最小值：100ms
echo - 建议值：1000ms
echo.
echo 【随机偏移±】
echo - 在间隔基础上随机增减
echo - 例如：间隔1000ms，偏移±200ms
echo - 实际间隔将在800-1200ms之间
echo.
echo 【位置偏移】
echo - 点击位置的随机偏移范围^(像素^)
echo - 例如：偏移10，实际点击位置在±10像素内
echo - 用于模拟人工点击
echo.
echo.
echo 六、常见问题
echo ------------
echo 【Q1】快捷键不工作？
echo A: 需要以管理员身份运行，右键"启动.bat"→"以管理员身份运行"
echo.
echo 【Q2】程序无法启动？
echo A: 确保已安装 Visual C++ Redistributable
echo    下载地址：https://aka.ms/vs/17/release/vc_redist.x64.exe
echo.
echo 【Q3】点击不准确？
echo A: 检查位置偏移设置，设为0可精确点击
echo.
echo 【Q4】如何查看日志？
echo A: 双击"查看日志.bat"，或手动打开
echo    %%USERPROFILE%%\Documents\MouseControl\logs\
echo.
echo 【Q5】如何卸载？
echo A: 直接删除整个文件夹即可，无残留
echo.
echo.
echo 七、技术支持
echo ------------
echo 版本：v%VERSION%
echo 系统要求：Windows 10/11
echo 日志位置：%%USERPROFILE%%\Documents\MouseControl\logs\
echo.
echo 如有问题请查看日志文件获取详细信息。
echo.
echo ========================================
echo   祝使用愉快！
echo ========================================
) > "%TARGET_DIR%\使用说明.txt"

:: ========================================
:: 3. 创建常见问题（常见问题.txt）
:: ========================================
(
echo ========================================
echo   常见问题解答 ^(FAQ^)
echo ========================================
echo.
echo 【1】程序双击后无反应？
echo.
echo   症状：双击mouse_control.exe后没有窗口弹出
echo.
echo   解决方法：
echo   √ 右键"启动.bat"→"以管理员身份运行"
echo   √ 检查是否缺少必要的DLL文件
echo   √ 查看任务管理器中是否已经在运行
echo   √ 查看日志：%%USERPROFILE%%\Documents\MouseControl\logs\
echo.
echo   如果仍无法启动：
echo   - 安装 Visual C++ Redistributable
echo     下载：https://aka.ms/vs/17/release/vc_redist.x64.exe
echo   - 检查杀毒软件是否拦截
echo   - 尝试在Windows 10/11上运行
echo.
echo.
echo 【2】快捷键按了没反应？
echo.
echo   症状：按Ctrl+Shift+1/2无效果
echo.
echo   解决方法：
echo   √ 必须以管理员身份运行
echo   √ 右键"启动.bat"→"以管理员身份运行"
echo   √ 或右键"mouse_control.exe"→"以管理员身份运行"
echo.
echo   检查方法：
echo   1. 打开程序
echo   2. 查看控制台输出
echo   3. 看是否有"热键注册成功"的提示
echo   4. 查看日志文件确认快捷键状态
echo.
echo.
echo 【3】找不到window_manager_plugin.dll？
echo.
echo   症状：启动时提示缺少DLL
echo.
echo   解决方法：
echo   √ 确认以下文件都在同一目录：
echo     - mouse_control.exe
echo     - flutter_windows.dll
echo     - window_manager_plugin.dll
echo     - screen_retriever_windows_plugin.dll
echo     - mouse_controller.dll
echo     - data\文件夹
echo.
echo   √ 如果文件不全，请重新下载完整安装包
echo   √ 解压时使用"解压到当前文件夹"
echo.
echo.
echo 【4】点击位置不准？
echo.
echo   症状：点击位置偏离目标
echo.
echo   解决方法：
echo   √ 将"位置偏移"设置为0
echo   √ 使用"手动输入模式"指定精确坐标
echo   √ 关闭"随机偏移±"
echo   √ 使用Ctrl+Shift+2捕获精确位置
echo.
echo.
echo 【5】如何查看详细日志？
echo.
echo   方法1：双击"查看日志.bat"
echo   方法2：手动打开
echo     - 按Win+R
echo     - 输入：%%USERPROFILE%%\Documents\MouseControl\logs
echo     - 打开最新的app_*.log文件
echo.
echo   日志包含：
echo   - 程序启动信息
echo   - 快捷键注册状态
echo   - 点击统计
echo   - 错误详细信息
echo.
echo.
echo 【6】程序占用CPU/内存太高？
echo.
echo   正常情况：
echo   - CPU: ^<1%%
echo   - 内存: 50-100MB
echo.
echo   如果异常：
echo   1. 停止自动点击
echo   2. 重启程序
echo   3. 检查点击间隔是否太小^(建议≥100ms^)
echo   4. 查看日志是否有错误循环
echo.
echo.
echo 【7】想要移动到其他电脑使用？
echo.
echo   解决方法：
echo   √ 这是便携版，直接复制整个文件夹即可
echo   √ 目标电脑需要：Windows 10/11
echo   √ 目标电脑需要：Visual C++ Redistributable
echo   √ 无需安装，无注册表残留
echo.
echo.
echo 【8】如何完全卸载？
echo.
echo   卸载步骤：
echo   1. 关闭程序
echo   2. 删除整个程序文件夹
echo   3. ^(可选^) 删除日志文件夹：
echo      %%USERPROFILE%%\Documents\MouseControl\
echo.
echo   注意：程序不写注册表，无其他残留。
echo.
echo.
echo 【9】支持哪些Windows版本？
echo.
echo   支持的版本：
echo   √ Windows 10 ^(1809及更高版本^)
echo   √ Windows 11 ^(所有版本^)
echo.
echo   不支持的版本：
echo   × Windows 7
echo   × Windows 8/8.1
echo.
echo.
echo 【10】程序安全吗？会不会有病毒？
echo.
echo   安全说明：
echo   √ 本程序是开源项目
echo   √ 仅使用Windows官方API
echo   √ 不联网，不上传数据
echo   √ 不修改系统文件
echo   √ 不写入注册表
echo   √ 源代码可供审查
echo.
echo   杀毒软件可能误报：
echo   - 因为使用了全局快捷键API
echo   - 因为使用了鼠标控制API
echo   - 请添加到白名单
echo.
echo.
echo ========================================
echo   仍有问题？请查看日志文件
echo   %%USERPROFILE%%\Documents\MouseControl\logs\
echo ========================================
) > "%TARGET_DIR%\常见问题.txt"

:: ========================================
:: 4. 创建查看日志脚本（查看日志.bat）
:: ========================================
(
echo @echo off
echo chcp 65001 ^>nul
echo.
echo 正在打开日志目录...
echo.
echo 日志位置：%%USERPROFILE%%\Documents\MouseControl\logs
echo.
echo 按任意键打开日志文件夹...
echo pause ^>nul
echo.
echo explorer "%%USERPROFILE%%\Documents\MouseControl\logs"
) > "%TARGET_DIR%\查看日志.bat"

:: ========================================
:: 5. 创建调试启动脚本（调试启动.bat）
:: ========================================
(
echo @echo off
echo chcp 65001 ^>nul
echo cd /d "%%~dp0"
echo.
echo ========================================
echo   调试模式 - 显示详细日志
echo ========================================
echo.
echo 此模式会显示所有调试信息，用于诊断问题。
echo 窗口不会自动关闭，可以查看完整输出。
echo.
echo ========================================
echo.
echo 正在启动...
echo.
echo.
echo "%%~dp0mouse_control.exe"
echo.
echo.
echo ========================================
echo   程序已关闭
echo ========================================
echo.
echo 如果程序立即关闭，可能是：
echo 1. 缺少必要的DLL文件
echo 2. Visual C++ 运行库未安装
echo 3. 权限不足
echo.
echo 请查看上方的错误信息。
echo.
echo pause
) > "%TARGET_DIR%\调试启动.bat"

echo [OK] All helper files created in: %TARGET_DIR%
exit /b 0
