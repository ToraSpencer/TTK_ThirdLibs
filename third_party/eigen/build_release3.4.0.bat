@echo off
setlocal

rem Install Eigen 3.4.0 headers into <repo>\install\eigen (header-only, libs is empty)

for %%I in ("%~dp0..\..") do set "ROOT=%%~fI"
for %%I in ("%~dp0eigen3.4.0") do set "SRC=%%~fI"
set "BUILD=%ROOT%\build\eigen-release"
set "PREFIX=%ROOT%\install\eigen"
set "CONFIG=Release"

where cmake >nul 2>nul
if errorlevel 1 (
  echo [ERROR] cmake was not found in PATH.
  exit /b 1
)
if not exist "%SRC%\CMakeLists.txt" (
  echo [ERROR] Eigen source not found: "%SRC%"
  exit /b 1
)

if not exist "%PREFIX%\include" mkdir "%PREFIX%\include"
if not exist "%PREFIX%\libs" mkdir "%PREFIX%\libs"

echo [1/2] Configuring Eigen 3.4.0 (%CONFIG%)...
cmake -S "%SRC%" -B "%BUILD%" -G "Visual Studio 17 2022" -A x64 ^
  -DINCLUDE_INSTALL_DIR="%PREFIX%\include" ^
  -DCMAKE_INSTALL_PREFIX="%PREFIX%" ^
  -DBUILD_TESTING=OFF ^
  -DEIGEN_BUILD_DOC=OFF
if errorlevel 1 exit /b 1

echo [2/2] Installing Eigen 3.4.0 headers (%CONFIG%)...
cmake --build "%BUILD%" --config %CONFIG% --target install
if errorlevel 1 exit /b 1

if not exist "%PREFIX%\libs" mkdir "%PREFIX%\libs"

echo [OK] Eigen 3.4.0 %CONFIG% installed to "%PREFIX%"
endlocal
