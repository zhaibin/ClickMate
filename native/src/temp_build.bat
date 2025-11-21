@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Auxiliary\Build\vcvars64.bat"
cl.exe /LD /O2 /DBUILDING_DLL mouse_controller.cpp /link user32.lib /OUT:mouse_controller.dll
