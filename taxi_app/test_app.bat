@echo off
echo ========================================
echo RideNow Taxi - Testing Script
echo ========================================
echo.

echo Step 1: Checking Flutter environment...
flutter doctor
if %errorlevel% neq 0 (
    echo ERROR: Flutter environment issues detected.
    echo Please install Flutter and Android Studio.
    pause
    exit /b 1
)

echo.
echo Step 2: Checking connected devices...
flutter devices
if %errorlevel% neq 0 (
    echo WARNING: No devices found.
    echo Please connect a device or start an emulator.
    echo.
    echo To start emulator:
    echo 1. Open Android Studio
    echo 2. Tools ^> AVD Manager
    echo 3. Click "Play" on your emulator
    pause
)

echo.
echo Step 3: Getting dependencies...
flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to get dependencies.
    pause
    exit /b 1
)

echo.
echo Step 4: Running tests...
flutter test
if %errorlevel% neq 0 (
    echo WARNING: Some tests failed.
    echo Check the test output above.
)

echo.
echo Step 5: Analyzing code...
flutter analyze
if %errorlevel% neq 0 (
    echo WARNING: Code analysis found issues.
    echo Please review and fix critical issues.
)

echo.
echo Step 6: Building debug version...
flutter build apk --debug
if %errorlevel% neq 0 (
    echo ERROR: Debug build failed.
    pause
    exit /b 1
)

echo.
echo ========================================
echo Testing Complete!
echo ========================================
echo.
echo Next steps:
echo 1. Run 'flutter run' to test on device/emulator
echo 2. Test all features manually
echo 3. Run 'flutter build appbundle --release' for production
echo 4. Upload to Google Play Console
echo.
echo For detailed testing guide, see README_DEPLOYMENT.md
pause
