@echo off
:: Proxy for 'emmake' - activates emsdk only for this one call, then deactivates
:: (via setlocal/endlocal below). See _proxy_core.bat next to this file for
:: the actual logic.
setlocal
call "%~dp0_proxy_core.bat" emmake %*
set "EMPROXY_EXITCODE=%ERRORLEVEL%"
endlocal & exit /b %EMPROXY_EXITCODE%
