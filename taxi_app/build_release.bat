@echo off
echo Building RideNow Taxi App for Google Play Store...
echo.

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found. Please install Flutter and add it to your PATH.
    pause
    exit /b 1
)

REM Clean previous builds
echo Cleaning previous builds...
flutter clean
if %errorlevel% neq 0 (
    echo ERROR: Failed to clean Flutter project.
    pause
    exit /b 1
)

REM Get dependencies
echo Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies.
    pause
    exit /b 1
)

REM Check for keystore
if not exist "android\app\release-key.jks" (
    echo WARNING: Release keystore not found.
    echo Please run generate_keystore.bat first to create the keystore.
    echo.
    echo Continuing with debug keystore (not suitable for Play Store)...
    pause
)

REM Build release AAB
echo Building Android App Bundle (AAB)...
flutter build appbundle --release
if %errorlevel% neq 0 (
    echo ERROR: Failed to build release AAB.
    pause
    exit /b 1
)

echo.
echo SUCCESS: Release AAB built successfully!
echo Location: build\app\outputs\bundle\release\app-release.aab
echo.
echo Next steps:
echo 1. Upload the AAB file to Google Play Console
echo 2. Complete the store listing information
echo 3. Submit for review
echo.
pause
