# Direct compile without vcvars
Write-Host "Compiling C++ mouse controller library..." -ForegroundColor Cyan

$compilerPath = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\bin\Hostx64\x64"
$msvcInclude = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\include"
$sdkInclude = "C:\Program Files (x86)\Windows Kits\10\Include\10.0.26100.0"
$msvcLib = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\VC\Tools\MSVC\14.44.35207\lib\x64"
$sdkLib = "C:\Program Files (x86)\Windows Kits\10\Lib\10.0.26100.0"

# Set environment variables
$env:INCLUDE = "$msvcInclude;$sdkInclude\ucrt;$sdkInclude\um;$sdkInclude\shared"
$env:LIB = "$msvcLib;$sdkLib\ucrt\x64;$sdkLib\um\x64"
$env:PATH = "$compilerPath;$env:PATH"

# Go to source directory
Push-Location "native\src"

try {
    # Compile command
    $compileCmd = "cl.exe /LD /O2 /EHsc /std:c++17 /DBUILDING_DLL mouse_controller.cpp /link user32.lib /OUT:mouse_controller.dll"

    Write-Host "Running: $compileCmd" -ForegroundColor Gray
    Invoke-Expression $compileCmd

    if (Test-Path "mouse_controller.dll") {
        Write-Host "`nCompilation successful!" -ForegroundColor Green

        # Create target directories
        $releaseDir = "..\..\build\windows\x64\runner\Release"
        $debugDir = "..\..\build\windows\x64\runner\Debug"

        New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null
        New-Item -ItemType Directory -Force -Path $debugDir | Out-Null

        # Copy DLL
        Copy-Item "mouse_controller.dll" -Destination $releaseDir -Force
        Copy-Item "mouse_controller.dll" -Destination $debugDir -Force

        Write-Host "DLL copied to Flutter build directories" -ForegroundColor Green

        # List files
        Write-Host "`nDLL locations:" -ForegroundColor Cyan
        Write-Host "  - $releaseDir\mouse_controller.dll"
        Write-Host "  - $debugDir\mouse_controller.dll"

        # Clean up
        Remove-Item "*.obj", "*.exp", "*.lib" -ErrorAction SilentlyContinue

        return $true
    } else {
        Write-Host "`nCompilation failed - DLL not found" -ForegroundColor Red
        return $false
    }
} finally {
    Pop-Location
}
