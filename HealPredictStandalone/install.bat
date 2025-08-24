@echo off
echo HealPredictStandalone Installation Helper
echo =======================================
echo.

REM Check if WoW directory exists
set "WOWDIR=C:\Program Files (x86)\World of Warcraft"
set "WOWDIR2=C:\Program Files\World of Warcraft" 
set "ADDONSDIR="

if exist "%WOWDIR%\Interface\AddOns" (
    set "ADDONSDIR=%WOWDIR%\Interface\AddOns"
) else if exist "%WOWDIR2%\Interface\AddOns" (
    set "ADDONSDIR=%WOWDIR2%\Interface\AddOns"
) else (
    echo Could not find World of Warcraft installation directory.
    echo Please manually copy HealPredictStandalone folder to:
    echo   ^<WoW Directory^>\Interface\AddOns\
    pause
    exit /b 1
)

echo Found WoW AddOns directory: %ADDONSDIR%
echo.

REM Copy addon
if exist "HealPredictStandalone" (
    echo Copying HealPredictStandalone to AddOns directory...
    xcopy "HealPredictStandalone" "%ADDONSDIR%\HealPredictStandalone\" /E /I /Y
    if %ERRORLEVEL% EQU 0 (
        echo.
        echo ✓ Installation completed successfully!
        echo.
        echo Next steps:
        echo 1. Start World of Warcraft
        echo 2. Enable HealPredictStandalone in the AddOns list
        echo 3. Use /healpredict config to configure settings
        echo.
    ) else (
        echo ✗ Installation failed. Please install manually.
    )
) else (
    echo ✗ HealPredictStandalone folder not found in current directory.
    echo Please run this script from the directory containing the addon.
)

pause