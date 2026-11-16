@echo off
setlocal
cd /d "%~dp0"
if not exist "builds\web\index.html" (
    echo [001] Missing Web build. Extract the full release ZIP first.
    pause
    exit /b 1
)
where py.exe >nul 2>nul
if not errorlevel 1 (
    set "PYTHON_COMMAND=py -3"
    goto serve
)
where python.exe >nul 2>nul
if not errorlevel 1 (
    set "PYTHON_COMMAND=python"
    goto serve
)
echo [001] Python 3 is required for the local Web server.
echo Install Python 3, or upload builds\web to an HTTP or HTTPS static host.
pause
exit /b 1

:serve
%PYTHON_COMMAND% -c "import sys; sys.exit(0 if sys.version_info.major == 3 else 1)" >nul 2>nul
if errorlevel 1 (
    echo [001] Python 3 is required; check the Python installation.
    pause
    exit /b 1
)
echo Android: connect to the same Wi-Fi and open http://YOUR_PC_IPV4:8060/
echo Use ipconfig to find the computer's IPv4 address. Keep this window open.
%PYTHON_COMMAND% tools\serve_web.py --open-browser
if errorlevel 1 (
    echo [001] Web server failed to start. Check the error above.
    pause
    exit /b 1
)
exit /b 0
