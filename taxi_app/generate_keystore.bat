@echo off
echo Generating release keystore for RideNow Taxi App...
echo.

REM Check if keytool is available
keytool -help >nul 2>&1
if %errorlevel% neq 0 (
    echo ERROR: keytool not found. Please ensure Java JDK is installed and in your PATH.
    echo You can download JDK from: https://www.oracle.com/java/technologies/downloads/
    pause
    exit /b 1
)

REM Generate the keystore
echo Creating release keystore...
keytool -genkey -v -keystore android\app\release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release -storepass your_keystore_password -keypass your_key_password -dname "CN=RideNow Taxi, OU=Development, O=RideNow, L=City, ST=State, C=US"

if %errorlevel% equ 0 (
    echo.
    echo SUCCESS: Keystore generated successfully!
    echo.
    echo IMPORTANT: Update the key.properties file with your actual passwords:
    echo - storePassword=your_keystore_password
    echo - keyPassword=your_key_password
    echo.
    echo Then run: flutter build appbundle
) else (
    echo.
    echo ERROR: Failed to generate keystore.
    pause
    exit /b 1
)
