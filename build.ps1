# 编译 C++ 鼠标控制库
Write-Host "正在编译 C++ 鼠标控制库..." -ForegroundColor Green

# 设置 Visual Studio 环境
$vsPath = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
$vcvarsPath = Join-Path $vsPath "VC\Auxiliary\Build\vcvars64.bat"

# 进入源代码目录
Set-Location "native\src"

# 创建临时批处理文件来设置环境并编译
$buildScript = @"
@echo off
call "$vcvarsPath"
cl.exe /LD /O2 /DBUILDING_DLL mouse_controller.cpp /link user32.lib /OUT:mouse_controller.dll
"@

$buildScript | Out-File -FilePath "temp_build.bat" -Encoding ASCII

# 执行编译
$process = Start-Process -FilePath "cmd.exe" -ArgumentList "/c temp_build.bat" -Wait -PassThru -NoNewWindow

# 检查编译结果
if (Test-Path "mouse_controller.dll") {
    Write-Host "编译成功！" -ForegroundColor Green

    # 创建目标目录
    $releaseDir = "..\..\build\windows\x64\runner\Release"
    $debugDir = "..\..\build\windows\x64\runner\Debug"

    New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
    New-Item -ItemType Directory -Force -Path $debugDir | Out-Null

    # 复制 DLL
    Copy-Item "mouse_controller.dll" -Destination $releaseDir -Force
    Copy-Item "mouse_controller.dll" -Destination $debugDir -Force

    Write-Host "DLL 已复制到 Flutter 构建目录" -ForegroundColor Green

    # 清理临时文件
    Remove-Item "*.obj", "*.exp", "*.lib", "temp_build.bat" -ErrorAction SilentlyContinue

    Set-Location "..\..\"
    exit 0
} else {
    Write-Host "编译失败！" -ForegroundColor Red
    Remove-Item "temp_build.bat" -ErrorAction SilentlyContinue
    Set-Location "..\..\"
    exit 1
}
