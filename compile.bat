@echo off
setlocal

REM 初始化 Visual Studio 环境
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat" >nul 2>&1

cd native\src

REM 编译 DLL
cl.exe /LD /O2 /DBUILDING_DLL mouse_controller.cpp /link user32.lib /OUT:mouse_controller.dll

if %errorlevel% neq 0 exit /b 1

REM 创建目标目录并复制 DLL
if not exist "..\..\build\windows\x64\runner\Release" mkdir "..\..\build\windows\x64\runner\Release"
if not exist "..\..\build\windows\x64\runner\Debug" mkdir "..\..\build\windows\x64\runner\Debug"

copy /Y mouse_controller.dll "..\..\build\windows\x64\runner\Release\" >nul
copy /Y mouse_controller.dll "..\..\build\windows\x64\runner\Debug\" >nul

REM 清理临时文件
del *.obj *.exp *.lib 2>nul

cd ..\..
echo Build completed successfully
