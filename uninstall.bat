@echo off
:: uninstall.bat - undoes setup.bat (Windows).
::
:: Removes proxy\ from your user PATH. Does NOT remove the installed emsdk
:: toolchain itself - use "emsdk.bat uninstall <version>" for that if you
:: want it gone too.

setlocal enabledelayedexpansion

set "ROOT_DIR=%~dp0"
if "%ROOT_DIR:~-1%"=="\" set "ROOT_DIR=%ROOT_DIR:~0,-1%"
set "PROXY_DIR=%ROOT_DIR%\proxy"

echo ==^> Removing %PROXY_DIR% from your user PATH...

set "CURRENT_USER_PATH="
for /f "usebackq tokens=2,*" %%A in (`reg query "HKCU\Environment" /v Path 2^>nul`) do set "CURRENT_USER_PATH=%%B"

if not defined CURRENT_USER_PATH (
    echo    - no user PATH found, nothing to do
    goto :done
)

echo !CURRENT_USER_PATH! | find /I "%PROXY_DIR%" >nul
if errorlevel 1 (
    echo    - %PROXY_DIR% not present in user PATH, skipping
    goto :done
)

set "NEWPATH=%CURRENT_USER_PATH%"
call set "NEWPATH=%%NEWPATH:%PROXY_DIR%;=%%"
call set "NEWPATH=%%NEWPATH:;%PROXY_DIR%=%%"
call set "NEWPATH=%%NEWPATH:%PROXY_DIR%=%%"

:: trim a stray leading/trailing semicolon left behind, if any
if "!NEWPATH:~0,1!"==";" set "NEWPATH=!NEWPATH:~1!"
if "!NEWPATH:~-1!"==";" set "NEWPATH=!NEWPATH:~0,-1!"

setx PATH "!NEWPATH!" >nul
echo    - removed. Close and reopen your terminal for this to take effect.

:done
echo.
echo ==^> Done.
echo     Note: this only undoes the PATH registration. It does not remove
echo     the installed emsdk toolchain itself.
endlocal
