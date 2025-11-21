@echo off
echo 正在编译C++鼠标控制库...

cd native
if not exist build mkdir build
cd build

cmake .. -G "MinGW Makefiles"
if %errorlevel% neq 0 (
    echo CMake配置失败！请确保已安装CMake和MinGW
    pause
    exit /b 1
)

cmake --build . --config Release
if %errorlevel% neq 0 (
    echo 编译失败！
    pause
    exit /b 1
)

echo.
echo 编译成功！正在复制DLL文件...

if not exist "..\..\build\windows\x64\runner\Release" mkdir "..\..\build\windows\x64\runner\Release"
copy /Y mouse_controller.dll "..\..\build\windows\x64\runner\Release\"

if not exist "..\..\build\windows\x64\runner\Debug" mkdir "..\..\build\windows\x64\runner\Debug"
copy /Y mouse_controller.dll "..\..\build\windows\x64\runner\Debug\"

echo.
echo 构建完成！DLL已复制到Flutter构建目录
pause
