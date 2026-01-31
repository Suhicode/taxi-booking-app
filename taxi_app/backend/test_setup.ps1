# Test Database Setup Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Taxi App - Setup Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check if database exists
Write-Host "Test 1: Checking if database exists..." -ForegroundColor Yellow
$dbExists = psql -U postgres -lqt 2>$null | Select-String "taxi_fare_db"
if ($dbExists) {
    Write-Host "[OK] Database 'taxi_fare_db' exists" -ForegroundColor Green
} else {
    Write-Host "[X] Database 'taxi_fare_db' does NOT exist" -ForegroundColor Red
    Write-Host "  Run: .\setup_database.bat" -ForegroundColor Yellow
}
Write-Host ""

# Test 2: Check PostGIS
Write-Host "Test 2: Checking PostGIS extension..." -ForegroundColor Yellow
try {
    $postgis = psql -U postgres -d taxi_fare_db -t -c "SELECT PostGIS_version();" 2>$null
    if ($postgis -and $postgis.Trim() -ne "") {
        Write-Host "[OK] PostGIS is installed: $($postgis.Trim())" -ForegroundColor Green
    } else {
        Write-Host "[X] PostGIS extension not found" -ForegroundColor Red
        Write-Host "  Install PostGIS from: https://postgis.net/windows_downloads/" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[X] Cannot check PostGIS (database might not exist)" -ForegroundColor Red
}
Write-Host ""

# Test 3: Check if tables exist
Write-Host "Test 3: Checking database tables..." -ForegroundColor Yellow
try {
    $tables = psql -U postgres -d taxi_fare_db -t -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public';" 2>$null
    if ($tables -and [int]$tables.Trim() -gt 0) {
        Write-Host "[OK] Found $($tables.Trim()) tables in database" -ForegroundColor Green
    } else {
        Write-Host "[X] No tables found - need to run schema.sql" -ForegroundColor Red
        Write-Host "  Run: psql -U postgres -d taxi_fare_db -f schema.sql" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[X] Cannot check tables" -ForegroundColor Red
}
Write-Host ""

# Test 4: Check .env file
Write-Host "Test 4: Checking .env file..." -ForegroundColor Yellow
if (Test-Path .env) {
    Write-Host "[OK] .env file exists" -ForegroundColor Green
    $envContent = Get-Content .env -Raw
    if ($envContent -match "DB_PASSWORD\s*=") {
        Write-Host "[OK] DB_PASSWORD is configured" -ForegroundColor Green
    } else {
        Write-Host "[!] DB_PASSWORD might not be set" -ForegroundColor Yellow
    }
} else {
    Write-Host "[X] .env file not found" -ForegroundColor Red
    Write-Host "  Run: copy env.example .env" -ForegroundColor Yellow
}
Write-Host ""

# Test 5: Check npm packages
Write-Host "Test 5: Checking npm packages..." -ForegroundColor Yellow
if (Test-Path node_modules) {
    Write-Host "[OK] npm packages installed" -ForegroundColor Green
} else {
    Write-Host "[X] npm packages not installed" -ForegroundColor Red
    Write-Host "  Run: npm install" -ForegroundColor Yellow
}
Write-Host ""

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Test Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Fix any issues marked with ✗" -ForegroundColor White
Write-Host "2. Run: npm run dev" -ForegroundColor White
Write-Host "3. Test: http://localhost:3000/api/v1/zones" -ForegroundColor White
