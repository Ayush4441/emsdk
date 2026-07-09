@echo off
:: _proxy_core.bat
::
:: Shared logic used by every proxy\<tool>.bat wrapper (emcc.bat, em++.bat, ...).
:: NOT meant to be run directly - it is `call`ed by the thin per-tool .bat
:: files sitting next to it in this same proxy\ directory.
::
:: Usage from a wrapper:  call "%~dp0_proxy_core.bat" emcc %*
::
:: What it does:
::   1. ACTIVATE   - call the real emsdk_env.bat so PATH/EMSDK/EM_CONFIG etc.
::                   point at the real toolchain
::   2. RUN        - call the real tool (found via PATH after activation)
::                   with every argument forwarded untouched
::   3. DEACTIVATE - the wrapper .bat that called us wraps everything in
::                   setlocal/endlocal, so all PATH/env changes made here
::                   automatically vanish the moment it returns.

set "TOOL_NAME=%~1"
shift

set "PROXY_DIR=%~dp0"
for %%I in ("%PROXY_DIR%..") do set "EMSDK_ROOT=%%~fI"

if not exist "%EMSDK_ROOT%\emsdk_env.bat" (
    echo emsdk proxy: could not find emsdk_env.bat in "%EMSDK_ROOT%" 1>&2
    echo emsdk proxy: ^(expected proxy\ to be a sibling of the emsdk root^) 1>&2
    exit /b 127
)

:: ---- 1. ACTIVATE ----
call "%EMSDK_ROOT%\emsdk_env.bat" >nul 2>&1

:: collect the remaining forwarded arguments
set "ARGS="
:collect_args
if "%~1"=="" goto run_tool
set "ARGS=%ARGS% %1"
shift
goto collect_args

:run_tool
:: PATH now has emsdk's real tool directories prepended by emsdk_env.bat,
:: so this resolves to the *real* tool rather than this proxy again, as
:: long as PROXY_DIR is not earlier in PATH than the real emsdk dirs
:: (it isn't - emsdk_env.bat always prepends fresh at the front).
call %TOOL_NAME% %ARGS%
exit /b %ERRORLEVEL%
