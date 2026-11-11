@echo off
setlocal

rem Build and install all third-party libraries (Debug, x64) into <repo>\debug_install.

cd /d "%~dp0"
set "FAILED=0"

echo ========================================
echo Building all third-party libraries
echo Configuration: Debug, x64
echo ========================================
echo.

echo [1/4] Boost 1.89.0 ...
call third_party\boost\build_debug1.89.0.bat
set "RC=%errorlevel%"
if not "%RC%"=="0" (
  echo [WARN] Boost 1.89.0 failed with exit code %RC%
  set "FAILED=1"
)
echo.

echo [2/4] Eigen 3.4.0 ...
call third_party\eigen\build_debug3.4.0.bat
set "RC=%errorlevel%"
if not "%RC%"=="0" (
  echo [WARN] Eigen 3.4.0 failed with exit code %RC%
  set "FAILED=1"
)
echo.

echo [3/4] OpenMesh 7.0 ...
call third_party\openmesh\build_debug7.0.bat
set "RC=%errorlevel%"
if not "%RC%"=="0" (
  echo [WARN] OpenMesh 7.0 failed with exit code %RC%
  set "FAILED=1"
)
echo.

echo [4/4] Google Test 1.5.0 ...
call third_party\gtest\build_debug1.5.0.bat
set "RC=%errorlevel%"
if not "%RC%"=="0" (
  echo [WARN] Google Test 1.5.0 failed with exit code %RC%
  set "FAILED=1"
)
echo.

if "%FAILED%"=="1" (
  echo [FAILED] Some libraries failed to build. See the log above.
  exit /b 1
)

echo [OK] All libraries installed to "%~dp0debug_install"
endlocal
