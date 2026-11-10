@echo off
setlocal

rem Build and install Boost 1.89.0 (x64, Debug, static) into <repo>\debug_install\boost

for %%I in ("%~dp0..\..") do set "ROOT=%%~fI"
for %%I in ("%~dp0boost1.89.0") do set "SRC=%%~fI"
set "BUILD=%ROOT%\build\boost-debug"
set "PREFIX=%ROOT%\debug_install\boost"
set "CONFIG=Debug"

where cmake >nul 2>nul
if errorlevel 1 (
  echo [ERROR] cmake was not found in PATH.
  exit /b 1
)
if not exist "%SRC%\CMakeLists.txt" (
  echo [ERROR] Boost source not found: "%SRC%"
  exit /b 1
)

if not exist "%PREFIX%\include" mkdir "%PREFIX%\include"
if not exist "%PREFIX%\libs" mkdir "%PREFIX%\libs"

echo [1/2] Configuring Boost 1.89.0 (%CONFIG%, x64)...
cmake -S "%SRC%" -B "%BUILD%" -G "Visual Studio 17 2022" -A x64 ^
  -DBOOST_INSTALL_LAYOUT=system ^
  -DCMAKE_INSTALL_INCLUDEDIR=include ^
  -DCMAKE_INSTALL_LIBDIR=libs ^
  -DCMAKE_INSTALL_PREFIX="%PREFIX%" ^
  -DBUILD_TESTING=OFF
if errorlevel 1 exit /b 1

echo [2/2] Building and installing Boost 1.89.0 (%CONFIG%)...
cmake --build "%BUILD%" --config %CONFIG% --parallel --target install
if errorlevel 1 exit /b 1

rem CMake install omits headers of some header-only libraries (e.g. Boost.DLL);
rem merge every library's public include directory for a complete header tree.
for /d %%L in ("%SRC%\libs\*") do (
  if exist "%%L\include\*" xcopy /E /I /Y "%%L\include\*" "%PREFIX%\include\" >nul
)
for /d %%L in ("%SRC%\libs\numeric\*") do (
  if exist "%%L\include\*" xcopy /E /I /Y "%%L\include\*" "%PREFIX%\include\" >nul
)

echo [OK] Boost 1.89.0 %CONFIG% installed to "%PREFIX%"
endlocal
