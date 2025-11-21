@echo off
echo ========================================
echo 使用 MSVC 编译 C++ 鼠标控制库
echo ========================================
echo.

REM 设置Visual Studio环境变量
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

if %errorlevel% neq 0 (
    echo 无法初始化 Visual Studio 环境
    pause
    exit /b 1
)

echo.
echo 正在编译 mouse_controller.dll...
echo.

cd native\src

REM 编译为DLL
cl.exe /LD /O2 /DBUILDING_DLL ^
    mouse_controller.cpp ^
    /link user32.lib ^
    /OUT:mouse_controller.dll

if %errorlevel% neq 0 (
    echo 编译失败！
    cd ..\..
    pause
    exit /b 1
)

echo.
echo 编译成功！正在复制DLL文件...

REM 创建目标目录
if not exist "..\..\build\windows\x64\runner\Release" mkdir "..\..\build\windows\x64\runner\Release"
if not exist "..\..\build\windows\x64\runner\Debug" mkdir "..\..\build\windows\x64\runner\Debug"

REM 复制DLL
copy /Y mouse_controller.dll "..\..\build\windows\x64\runner\Release\"
copy /Y mouse_controller.dll "..\..\build\windows\x64\runner\Debug\"

REM 清理临时文件
del *.obj *.exp *.lib 2>nul

cd ..\..

echo.
echo ========================================
echo 构建完成！DLL 已复制到 Flutter 构建目录
echo ========================================
pause
