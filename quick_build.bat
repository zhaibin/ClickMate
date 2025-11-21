@echo off
echo Compiling C++ library...

call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"

cd /d "%~dp0native\src"

cl.exe /LD /O2 /EHsc /std:c++17 /DBUILDING_DLL mouse_controller.cpp /link user32.lib /OUT:mouse_controller.dll

if not exist mouse_controller.dll (
    echo Compilation failed!
    exit /b 1
)

echo DLL compiled successfully!

if not exist "..\..\build\windows\x64\runner\Release" mkdir "..\..\build\windows\x64\runner\Release"
if not exist "..\..\build\windows\x64\runner\Debug" mkdir "..\..\build\windows\x64\runner\Debug"

copy /Y mouse_controller.dll "..\..\build\windows\x64\runner\Release\"
copy /Y mouse_controller.dll "..\..\build\windows\x64\runner\Debug\"

del *.obj *.exp *.lib 2>nul

echo Build completed!
cd /d "%~dp0"
