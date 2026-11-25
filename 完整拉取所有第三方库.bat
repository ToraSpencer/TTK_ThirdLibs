@echo off
rem ============================================================
rem Fetch all third-party submodules (double-click to run).
rem
rem - Directory: repository root (next to .gitmodules).
rem - Fetches the 5 top-level submodules plus Boost's 170 nested
rem   submodules (shallow clone of the pinned commits).
rem - Multi-round retry, then per-submodule retry with cleanup of
rem   half-cloned directories.
rem - Safe to re-run: a full state check runs first; when every
rem   submodule is ready the script exits without touching them.
rem
rem NOTE: keep this file ASCII-only. cmd.exe mis-parses non-ASCII
rem text in batch files (byte offsets desync), which breaks lines
rem after the first Chinese character.
rem ============================================================
setlocal EnableExtensions EnableDelayedExpansion
cd /d "%~dp0"
title Fetch all third-party submodules

set "JOBS=8"
set "MAX_ROUNDS=3"
set "PER_PATH_RETRIES=5"
set "WAIT_SECONDS=5"
set "EXIT_CODE=0"

echo ============================================================
echo   TTK_ThirdLibs - Fetch all third-party submodules
echo ============================================================
echo   Recursively fetching 5 submodules (Boost has 170 nested):
echo     - Boost 1.89.0
echo     - Eigen 3.4.0
echo     - OpenMesh 7.0
echo     - Google Test 1.5.0
echo     - Dear ImGui 1.93.0
echo ============================================================
echo.

rem ---------- Preflight checks ----------
where git >nul 2>nul
if errorlevel 1 (
  echo [FAILED] git was not found. Install Git for Windows and add it to PATH.
  set "EXIT_CODE=1"
  goto :done
)
if not exist ".gitmodules" (
  echo [FAILED] .gitmodules not found. Put this script in the repository root.
  set "EXIT_CODE=1"
  goto :done
)
if not exist ".git" (
  echo [FAILED] .git not found. Put this script in the repository root.
  set "EXIT_CODE=1"
  goto :done
)

rem ---------- Network timeouts (only fill in missing settings) ----------
call :ensure_config http.connectTimeout 30
call :ensure_config http.lowSpeedLimit 1000
call :ensure_config http.lowSpeedTime 60
call :ensure_config submodule.fetchJobs 4

rem ---------- Sync submodule URLs ----------
echo [1/3] Syncing submodule URLs ...
git submodule sync --recursive >nul
if errorlevel 1 echo [WARN] Sync failed, continuing anyway.
echo.

rem ---------- Fast path: skip all work when everything is ready ----------
echo [2/3] Checking whether all submodules are already fetched ...
call :check_status full
if "!CHECK_ERROR!"=="1" (
  echo [WARN] Cannot read submodule status, updating anyway.
) else if "!REMAIN_COUNT!"=="0" (
  echo     All !TOTAL_COUNT! submodules are already fetched; nothing to do.
  echo.
  goto :success
) else (
  echo     !REMAIN_COUNT! of !TOTAL_COUNT! submodules not ready.
)
echo.

rem ---------- Recursive fetch with retries ----------
echo [2/3] Initializing and fetching all submodules (shallow, jobs=%JOBS%) ...
echo.
set /a ROUND=0

:round_loop
set /a ROUND+=1
echo --- Round !ROUND!/%MAX_ROUNDS%: git submodule update --init --force --recursive --depth 1 ---
git submodule update --init --force --recursive --depth 1 --jobs %JOBS%
call :check_status quick
if "!CHECK_ERROR!"=="1" (
  echo [WARN] Cannot read submodule status, will retry.
) else (
  echo     Status: !TOTAL_COUNT! submodules total, !REMAIN_COUNT! not ready.
  if "!REMAIN_COUNT!"=="0" (
    call :check_status full
    if "!REMAIN_COUNT!"=="0" goto :success
    echo [WARN] Found empty-shell submodules - HEAD unreadable, repairing.
  )
)
if !ROUND! geq %MAX_ROUNDS% goto :per_path
echo [WARN] Some submodules are not ready, retrying in %WAIT_SECONDS% seconds ...
ping -n %WAIT_SECONDS% 127.0.0.1 >nul
echo.
goto :round_loop

rem ---------- Per-submodule retry ----------
:per_path
echo.
echo [3/3] Retrying !REMAIN_COUNT! remaining submodule(s), up to %PER_PATH_RETRIES% attempts each ...
echo.
for /f "usebackq delims=" %%P in ("%REMAIN_FILE%") do call :retry_one "%%P"
call :check_status full
if "!CHECK_ERROR!"=="0" if "!REMAIN_COUNT!"=="0" goto :success
goto :fail

rem ============================================================
rem Subroutines
rem ============================================================

rem Collect submodule status and write the not-ready list.
rem Arg: quick = status only; full = also verify HEAD is readable.
:check_status
set "FULL_CHECK=%~1"
set "STATUS_FILE=%TEMP%\ttk_thirdlibs_status.txt"
set "REMAIN_FILE=%TEMP%\ttk_thirdlibs_remaining.txt"
set "CHECK_ERROR=0"
set "TOTAL_COUNT=0"
set "REMAIN_COUNT=0"
> "%REMAIN_FILE%" type nul
git submodule status --recursive > "%STATUS_FILE%" 2>nul
if errorlevel 1 (
  set "CHECK_ERROR=1"
  exit /b 1
)
for /f "usebackq tokens=1,2" %%A in ("%STATUS_FILE%") do (
  set /a TOTAL_COUNT+=1
  set "STATE=%%A"
  set "SUB=%%B"
  set "BAD=0"
  if "!STATE:~0,1!"=="-" set "BAD=1"
  if "!STATE:~0,1!"=="+" set "BAD=1"
  if "!BAD!"=="0" if /i "%FULL_CHECK%"=="full" (
    git -C "!SUB!" rev-parse --verify HEAD >nul 2>nul
    if errorlevel 1 set "BAD=1"
  )
  if "!BAD!"=="1" (
    set /a REMAIN_COUNT+=1
    >> "%REMAIN_FILE%" echo !SUB!
  )
)
exit /b 0

rem Retry one submodule; clean up the half-cloned directory after 3 failures.
rem Nested submodules (Boost's 170) must be updated from their owning
rem top-level submodule: the root repo does not know nested paths.
:retry_one
set "SUB=%~1"
set "OWNER="
for /f "tokens=1,*" %%M in ('git config -f .gitmodules --get-regexp "\.path$"') do (
  if not defined OWNER (
    call :is_under "!SUB!" "%%N"
    if not errorlevel 1 set "OWNER=%%N"
  )
)
if defined OWNER set "REL=!SUB:%OWNER%/=!"
rem Top-level modules cloned before the version-dir rename keep an old
rem git dir (e.g. .git/modules/third_party/eigen). Remember its link so
rem the cleanup below does not make the module impossible to re-clone.
set "GITLINK="
if not defined OWNER if exist "%SUB%\.git" (
  for /f "usebackq tokens=1,*" %%A in ("%SUB%\.git") do (
    if /i "%%A"=="gitdir:" set "GITLINK=%%B"
  )
)
set /a TRY=0

:retry_one_loop
set /a TRY+=1
echo   - [!TRY!/%PER_PATH_RETRIES%] %SUB%
if defined OWNER (
  git -C "%OWNER%" submodule update --init --force --depth 1 "!REL!" >nul 2>nul
) else (
  git submodule update --init --force --depth 1 "%SUB%" >nul 2>nul
)
if not errorlevel 1 (
  git -C "%SUB%" rev-parse --verify HEAD >nul 2>nul
  if not errorlevel 1 (
    echo     [OK] done
    exit /b 0
  )
)
if !TRY! geq 3 (
  echo     [FIX] removing half-cloned directory and retrying
  if defined OWNER (
    git -C "%OWNER%" submodule deinit -f "!REL!" >nul 2>nul
  ) else (
    git submodule deinit -f "%SUB%" >nul 2>nul
  )
  if exist "%SUB%" rmdir /s /q "%SUB%"
  if defined GITLINK if not exist "%SUB%\.git" (
    mkdir "%SUB%" 2>nul
    >"%SUB%\.git" echo gitdir: !GITLINK!
  )
)
if !TRY! geq %PER_PATH_RETRIES% (
  echo     [FAILED] still failing after %PER_PATH_RETRIES% attempts
  exit /b 1
)
ping -n %WAIT_SECONDS% 127.0.0.1 >nul
goto :retry_one_loop

rem Errorlevel 0 when %1 lies strictly under %2 (not equal).
rem Used to map a nested submodule path to its top-level owner.
:is_under
set "P=%~1"
set "O=%~2"
if /i "!P!"=="!O!" exit /b 1
if not "!P!"=="!P:%O%/=!" exit /b 0
exit /b 1

rem Write a local config key only when it is not set yet.
:ensure_config
git config --local --get "%~1" >nul 2>nul
if errorlevel 1 git config --local "%~1" "%~2" >nul 2>nul
exit /b 0

rem ============================================================
rem Exit
rem ============================================================

:success
echo.
echo ============================================================
echo [OK] All !TOTAL_COUNT! submodules are fully fetched.
echo ============================================================
echo   Next steps (optional):
echo     - Release install: double-click build_all_release.bat
echo     - Debug install:   double-click build_all_debug.bat
echo ============================================================
goto :done

:fail
set "EXIT_CODE=1"
echo.
echo ============================================================
echo [FAILED] Some submodules are still not ready.
echo ============================================================
if "!CHECK_ERROR!"=="1" echo Cannot read submodule status. Check the repository with: git status
if exist "%REMAIN_FILE%" if not "!CHECK_ERROR!"=="1" type "%REMAIN_FILE%"
echo.
echo Common causes: network timeout, connection reset, or a stale
echo index.lock left by another git tool. Close other git clients,
echo delete any .git\**\index.lock, then run this script again.
echo Already fetched submodules are skipped, not downloaded twice.
echo Manual troubleshooting: see README.md and the operation guide
echo (repository root), section 5 "network instability".
echo ============================================================
goto :done

:done
echo.
echo Press any key to close this window ...
pause >nul
endlocal & exit /b %EXIT_CODE%
