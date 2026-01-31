# Windows Setup Guide - Quick Start

Since you already have PostgreSQL installed, follow these steps:

## Step 1: Install PostGIS Extension

PostGIS is required for geospatial queries. You need to install it separately:

### Option A: Using Stack Builder (Recommended)
1. Open **Stack Builder** (comes with PostgreSQL installation)
2. Select your PostgreSQL installation
3. Expand **Spatial Extensions**
4. Check **PostGIS Bundle for PostgreSQL**
5. Click **Next** and install

### Option B: Download PostGIS Installer
1. Go to https://postgis.net/windows_downloads/
2. Download PostGIS for PostgreSQL 17
3. Run the installer
4. Select your PostgreSQL installation

### Option C: Using Package Manager (if you have Chocolatey)
```powershell
choco install postgis
```

## Step 2: Create Database

Run this in PowerShell or Command Prompt:

```powershell
# Create database
psql -U postgres -c "CREATE DATABASE taxi_fare_db;"

# Enable PostGIS
psql -U postgres -d taxi_fare_db -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```

**OR** use the automated script:
```powershell
cd backend
.\setup_database.bat
```

## Step 3: Run Database Schema

```powershell
cd backend
psql -U postgres -d taxi_fare_db -f schema.sql
```

**Note:** You'll be prompted for the PostgreSQL password (the one you set during installation).

## Step 4: Configure Environment

1. Copy the environment file:
```powershell
cd backend
copy env.example .env
```

2. Edit `.env` file with Notepad or any text editor:
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=taxi_fare_db
DB_USER=postgres
DB_PASSWORD=YOUR_POSTGRES_PASSWORD_HERE
REDIS_HOST=localhost
REDIS_PORT=6379
PORT=3000
```

Replace `YOUR_POSTGRES_PASSWORD_HERE` with the password you set during PostgreSQL installation.

## Step 5: Install Node Dependencies

```powershell
cd backend
npm install
```

## Step 6: Start the Server

```powershell
npm run dev
```

You should see:
```
Server running on port 3000
```

## Step 7: Test the API

Open a new PowerShell window and run:
```powershell
curl http://localhost:3000/api/v1/zones
```

Or open in browser: http://localhost:3000/api/v1/zones

---

## Troubleshooting

### "psql: command not found"
- Add PostgreSQL bin directory to PATH:
  - Usually: `C:\Program Files\PostgreSQL\17\bin`
  - Or use full path: `"C:\Program Files\PostgreSQL\17\bin\psql.exe"`

### "PostGIS extension not found"
- Install PostGIS (see Step 1 above)
- Or verify installation: `psql -U postgres -d taxi_fare_db -c "SELECT PostGIS_version();"`

### "Password authentication failed"
- Make sure you're using the correct PostgreSQL password
- If you forgot, you may need to reset it or check pg_hba.conf

### "Database already exists"
- That's fine! The database is already created. Continue with Step 3.

### "Port 3000 already in use"
- Change PORT in `.env` file to another port (e.g., 3001)
- Or find and close the process using port 3000

---

## Quick Test

Once everything is set up, test with:

```powershell
# Test database connection
psql -U postgres -d taxi_fare_db -c "SELECT version();"

# Test PostGIS
psql -U postgres -d taxi_fare_db -c "SELECT PostGIS_version();"

# Test API (after starting server)
curl http://localhost:3000/api/v1/zones
```

---

## Next Steps

1. ✅ Database setup complete
2. ✅ Backend server running
3. 📱 Update Flutter app API URL (see QUICK_INTEGRATION_GUIDE.md)
4. 🚀 Start testing your app!
