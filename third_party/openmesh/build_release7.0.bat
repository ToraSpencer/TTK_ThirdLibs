@echo off
setlocal

rem Build and install OpenMesh 7.0 (x64, Release, static) into <repo>\install\openmesh

for %%I in ("%~dp0..\..") do set "ROOT=%%~fI"
for %%I in ("%~dp0openmesh7.0") do set "SRC=%%~fI"
set "BUILD=%ROOT%\build\openmesh-release"
set "PREFIX=%ROOT%\install\openmesh"
set "CONFIG=Release"

where cmake >nul 2>nul
if errorlevel 1 (
  echo [ERROR] cmake was not found in PATH.
  exit /b 1
)
if not exist "%SRC%\CMakeLists.txt" (
  echo [ERROR] OpenMesh source not found: "%SRC%"
  exit /b 1
)

if not exist "%PREFIX%\include" mkdir "%PREFIX%\include"
if not exist "%PREFIX%\libs" mkdir "%PREFIX%\libs"

echo [1/2] Configuring OpenMesh 7.0 (%CONFIG%, x64)...
cmake -S "%SRC%" -B "%BUILD%" -G "Visual Studio 17 2022" -A x64 ^
  -DCMAKE_INSTALL_PREFIX="%PREFIX%" ^
  -DBUILD_APPS=OFF ^
  -DOPENMESH_BUILD_SHARED=OFF
if errorlevel 1 exit /b 1

echo [2/2] Building and installing OpenMesh 7.0 (%CONFIG%)...
cmake --build "%BUILD%" --config %CONFIG% --parallel --target install
if errorlevel 1 exit /b 1

rem OpenMesh 7.0 hardcodes the library destination to "lib"; normalize to "libs".
if exist "%PREFIX%\lib" (
  xcopy /E /I /Y "%PREFIX%\lib" "%PREFIX%\libs" >nul
  rmdir /S /Q "%PREFIX%\lib"
)

echo [OK] OpenMesh 7.0 %CONFIG% installed to "%PREFIX%"
endlocal
