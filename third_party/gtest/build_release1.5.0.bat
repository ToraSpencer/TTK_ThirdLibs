@echo off
setlocal

rem Build and install Google Test 1.5.0 (x64, Release, static) into <repo>\install\gtest

for %%I in ("%~dp0..\..") do set "ROOT=%%~fI"
for %%I in ("%~dp0gtest1.5.0") do set "SRC=%%~fI"
set "BUILD=%ROOT%\build\gtest-release"
set "PREFIX=%ROOT%\install\gtest"
set "CONFIG=Release"

where cmake >nul 2>nul
if errorlevel 1 (
  echo [ERROR] cmake was not found in PATH.
  exit /b 1
)
if not exist "%SRC%\src\gtest-all.cc" (
  echo [ERROR] Google Test source not found: "%SRC%"
  exit /b 1
)

if not exist "%PREFIX%\include" mkdir "%PREFIX%\include"
if not exist "%PREFIX%\libs" mkdir "%PREFIX%\libs"

echo [1/2] Configuring Google Test 1.5.0 (%CONFIG%, x64)...
cmake -S "%~dp0." -B "%BUILD%" -G "Visual Studio 17 2022" -A x64 ^
  -DGTEST_SRC="%SRC%" ^
  -DCMAKE_INSTALL_PREFIX="%PREFIX%"
if errorlevel 1 exit /b 1

echo [2/2] Building and installing Google Test 1.5.0 (%CONFIG%)...
cmake --build "%BUILD%" --config %CONFIG% --parallel --target install
if errorlevel 1 exit /b 1

echo [OK] Google Test 1.5.0 %CONFIG% installed to "%PREFIX%"
endlocal
