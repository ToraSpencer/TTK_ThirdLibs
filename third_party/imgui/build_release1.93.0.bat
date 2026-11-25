@echo off
setlocal

rem Build and install Dear ImGui 1.93.0 (x64, Release, static) into <repo>\install\imgui

for %%I in ("%~dp0..\..") do set "ROOT=%%~fI"
for %%I in ("%~dp0imgui1.93.0") do set "SRC=%%~fI"
set "BUILD=%ROOT%\build\imgui-release"
set "PREFIX=%ROOT%\install\imgui"
set "CONFIG=Release"

where cmake >nul 2>nul
if errorlevel 1 (
  echo [ERROR] cmake was not found in PATH.
  exit /b 1
)
if not exist "%SRC%\imgui.h" (
  echo [ERROR] Dear ImGui source not found: "%SRC%"
  exit /b 1
)

rem The install step creates include/ and libs/ on success; do not pre-create them,
rem so a failed build leaves no misleading empty install directory.

echo [1/2] Configuring Dear ImGui 1.93.0 (%CONFIG%, x64)...
cmake -S "%~dp0." -B "%BUILD%" -G "Visual Studio 17 2022" -A x64 ^
  -DIMGUI_SRC="%SRC%" ^
  -DCMAKE_INSTALL_PREFIX="%PREFIX%"
if errorlevel 1 exit /b 1

echo [2/2] Building and installing Dear ImGui 1.93.0 (%CONFIG%)...
cmake --build "%BUILD%" --config %CONFIG% --parallel --target install
if errorlevel 1 exit /b 1

echo [OK] Dear ImGui 1.93.0 %CONFIG% installed to "%PREFIX%"
endlocal
