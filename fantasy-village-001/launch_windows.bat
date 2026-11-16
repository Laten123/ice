@echo off
setlocal
cd /d "%~dp0"

if exist "builds\windows\FantasyVillage.exe" (
    start "Fantasy Village 001" "builds\windows\FantasyVillage.exe"
    exit /b 0
)

if defined GODOT_BIN goto run_godot
if exist "tools\Godot_v4.6.3-stable_win64.exe" (
    set "GODOT_BIN=%~dp0tools\Godot_v4.6.3-stable_win64.exe"
    goto run_godot
)
where godot.exe >nul 2>nul
if not errorlevel 1 (
    set "GODOT_BIN=godot.exe"
    goto run_godot
)
where godot4.exe >nul 2>nul
if not errorlevel 1 (
    set "GODOT_BIN=godot4.exe"
    goto run_godot
)
echo [001] No Windows build or Godot executable was found.
echo Extract the full release ZIP, or install Godot 4.6.3 and set GODOT_BIN.
echo Example: set "GODOT_BIN=C:\Godot\Godot_v4.6.3-stable_win64.exe"
pause
exit /b 1

:run_godot
set "FOUND_VERSION="
set "VERSION_FILE=%TEMP%\fantasy-village-001-version-%RANDOM%-%RANDOM%.txt"
"%GODOT_BIN%" --version >"%VERSION_FILE%" 2>nul
if errorlevel 1 (
    del "%VERSION_FILE%" >nul 2>nul
    echo [001] Could not run GODOT_BIN. Check its executable path.
    pause
    exit /b 1
)
set /p "FOUND_VERSION=" <"%VERSION_FILE%"
del "%VERSION_FILE%" >nul 2>nul
echo %FOUND_VERSION% | findstr /b /c:"4.6.3.stable." >nul
if errorlevel 1 (
    echo [001] Godot 4.6.3 stable is required. Check GODOT_BIN.
    pause
    exit /b 1
)
"%GODOT_BIN%" --path "%~dp0."
if errorlevel 1 (
    echo [001] Godot could not start the project. Check the message above.
    pause
    exit /b 1
)
exit /b 0

