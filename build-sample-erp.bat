@echo off
setlocal enabledelayedexpansion

REM ------------------------------------------------------------------
REM Configuration
REM ------------------------------------------------------------------
set "PROJECT_NAME=ApexERP.dproj"
set "BUILD_CONFIG=Debug"
set "BUILD_PLATFORM=Win32"
set "VERBOSITY=minimal"

echo ==================================================================
echo  ApexERP Build Script
echo ==================================================================

REM ------------------------------------------------------------------
REM 1. Check if RAD Studio Environment is already loaded
REM ------------------------------------------------------------------
if defined BDS (
    echo Environment variables already set.
    goto :Build
)

REM ------------------------------------------------------------------
REM 2. Attempt to find rsvars.bat automatically
REM    Checks standard installation paths for recent Delphi versions.
REM ------------------------------------------------------------------
echo Searching for RAD Studio installation...

REM List of common versions to check (Newest to Oldest)
REM 23.0 = Delphi 12 Athens
REM 22.0 = Delphi 11 Alexandria
REM 21.0 = Delphi 10.4 Sydney
REM 20.0 = Delphi 10.3 Rio
set "VERSIONS=23.0 22.0 21.0 20.0 19.0 18.0"

for %%v in (%VERSIONS%) do (
    set "RSVARS=C:\Program Files (x86)\Embarcadero\Studio\%%v\bin\rsvars.bat"
    if exist "!RSVARS!" (
        echo Found installation at: !RSVARS!
        call "!RSVARS!"
        goto :Build
    )
)

REM If we get here, we couldn't find rsvars.bat
echo.
echo [ERROR] Could not locate rsvars.bat automatically.
echo Please run this script from the "RAD Studio Command Prompt"
echo available in your Windows Start Menu.
echo.
pause
exit /b 1

REM ------------------------------------------------------------------
REM 3. Execute MSBuild
REM ------------------------------------------------------------------
:Build
echo.
echo Building %PROJECT_NAME% [%BUILD_PLATFORM% / %BUILD_CONFIG%]...
echo.

msbuild "%PROJECT_NAME%" /t:Build /p:Config=%BUILD_CONFIG% /p:Platform=%BUILD_PLATFORM% /v:%VERBOSITY%

if %errorlevel% neq 0 (
    echo.
    echo ==================================================================
    echo  BUILD FAILED
    echo ==================================================================
    pause
    exit /b %errorlevel%
)

echo.
echo ==================================================================
echo  BUILD SUCCESSFUL
echo ==================================================================
echo Output located in .\%BUILD_PLATFORM%\%BUILD_CONFIG%\
pause