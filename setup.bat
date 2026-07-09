@echo off
:: setup.bat - one-shot installer for this emsdk fork and its on-demand
:: "proxy" command wrappers (Windows).
::
:: What it does:
::   1. Installs & activates the latest emsdk toolchain (once, on this machine)
::   2. Adds this repo's proxy\ directory to your USER PATH
::
:: After this, running e.g.:
::     emcc foo.c -o foo.wasm
:: will silently activate the emsdk environment, run the real emcc, then
:: silently deactivate again - you never need to run emsdk_env.bat yourself
:: or leave emsdk permanently active in your shell.

setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0"
if "%ROOT_DIR:~-1%"=="\" set "ROOT_DIR=%ROOT_DIR:~0,-1%"
set "PROXY_DIR=%ROOT_DIR%\proxy"

echo ==^> emsdk fork located at: %ROOT_DIR%

if not exist "%ROOT_DIR%\emsdk.bat" (
    echo !! Could not find emsdk.bat in %ROOT_DIR%.
    echo !! Is this script sitting at the root of an emsdk checkout?
    exit /b 1
)

cd /d "%ROOT_DIR%"

echo ==^> Installing latest emsdk ^(this can take a while the first time^)...
call emsdk.bat install latest
if errorlevel 1 goto :error

echo ==^> Activating latest emsdk...
call emsdk.bat activate latest
if errorlevel 1 goto :error

echo ==^> Registering proxy\ on your user PATH...

set "CURRENT_USER_PATH="
for /f "usebackq tokens=2,*" %%A in (`reg query "HKCU\Environment" /v Path 2^>nul`) do set "CURRENT_USER_PATH=%%B"

if defined CURRENT_USER_PATH (
    echo !CURRENT_USER_PATH! | find /I "%PROXY_DIR%" >nul
    if not errorlevel 1 (
        echo    - already present in user PATH, skipping
        goto :done
    )
    setx PATH "%PROXY_DIR%;!CURRENT_USER_PATH!" >nul
) else (
    setx PATH "%PROXY_DIR%;%PATH%" >nul
)

echo    - added %PROXY_DIR% to your user PATH
echo    - close and reopen your terminal for this to take effect

:done
echo.
echo ==^> Done. Open a NEW terminal and try:
echo        emcc --version
echo.
echo     emcc, em++, emar, etc. will now activate emsdk on demand for each
echo     call and deactivate again right after - nothing stays active in
echo     your shell in between.
goto :eof

:error
echo !! setup failed - see errors above.
exit /b 1
