@echo off
echo ========================================
echo Taxi App - Database Setup Script
echo ========================================
echo.

echo Step 1: Creating database...
psql -U postgres -c "CREATE DATABASE taxi_fare_db;" 2>nul
if %errorlevel% neq 0 (
    echo Database might already exist, continuing...
) else (
    echo Database created successfully!
)
echo.

echo Step 2: Enabling PostGIS extension...
psql -U postgres -d taxi_fare_db -c "CREATE EXTENSION IF NOT EXISTS postgis;"
if %errorlevel% equ 0 (
    echo PostGIS extension enabled!
) else (
    echo WARNING: PostGIS extension might not be installed.
    echo Please install PostGIS for PostgreSQL 17.
    echo You can download it from: https://postgis.net/install/
)
echo.

echo Step 3: Running database schema...
psql -U postgres -d taxi_fare_db -f schema.sql
if %errorlevel% equ 0 (
    echo Schema applied successfully!
) else (
    echo ERROR: Failed to apply schema. Please check the error above.
    pause
    exit /b 1
)
echo.

echo ========================================
echo Database setup complete!
echo ========================================
echo.
echo Next steps:
echo 1. Copy env.example to .env
echo 2. Edit .env with your database password
echo 3. Run: npm install
echo 4. Run: npm run dev
echo.
pause
