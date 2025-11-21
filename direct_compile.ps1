# 直接编译 - 不依赖 vcvars
Write-Host "编译 C++ 鼠标控制库..." -ForegroundColor Cyan

$compilerPath = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64"
$msvcInclude = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\include"
$sdkInclude = "C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0"
$msvcLib = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\lib\x64"
$sdkLib = "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0"

# 设置环境变量
$env:INCLUDE = "$msvcInclude;$sdkInclude\ucrt;$sdkInclude\um;$sdkInclude\shared"
$env:LIB = "$msvcLib;$sdkLib\ucrt\x64;$sdkLib\um\x64"
$env:PATH = "$compilerPath;$env:PATH"

# 进入源代码目录
Push-Location "native\src"

try {
    # 编译命令
    $compileCmd = "cl.exe /LD /O2 /EHsc /std:c++17 /DBUILDING_DLL mouse_controller.cpp /link user32.lib /OUT:mouse_controller.dll"

    Write-Host "执行: $compileCmd" -ForegroundColor Gray
    Invoke-Expression $compileCmd

    if (Test-Path "mouse_controller.dll") {
        Write-Host "`n编译成功！" -ForegroundColor Green

        # 创建目标目录
        $releaseDir = "..\..\build\windows\x64\runner\Release"
        $debugDir = "..\..\build\windows\x64\runner\Debug"

        New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
        New-Item -ItemType Directory -Force -Path $debugDir | Out-Null

        # 复制 DLL
        Copy-Item "mouse_controller.dll" -Destination $releaseDir -Force
        Copy-Item "mouse_controller.dll" -Destination $debugDir -Force

        Write-Host "DLL 已复制到 Flutter 构建目录" -ForegroundColor Green

        # 列出文件
        Write-Host "`nDLL 位置:" -ForegroundColor Cyan
        Write-Host "  - $releaseDir\mouse_controller.dll"
        Write-Host "  - $debugDir\mouse_controller.dll"

        # 清理临时文件
        Remove-Item "*.obj", "*.exp", "*.lib" -ErrorAction SilentlyContinue

        return $true
    } else {
        Write-Host "`n编译失败！未找到 DLL 文件" -ForegroundColor Red
        return $false
    }
} finally {
    Pop-Location
}
