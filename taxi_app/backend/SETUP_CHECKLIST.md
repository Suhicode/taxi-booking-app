# ✅ Setup Checklist - Follow in Order

## Current Status Check

Run these commands to check what's already done:

```powershell
cd c:\Users\yousu\Desktop\taxi\taxi_app\backend

# Check if database exists
psql -U postgres -lqt | findstr "taxi_fare_db"

# Check if PostGIS is installed
psql -U postgres -d taxi_fare_db -c "SELECT PostGIS_version();" 2>$null

# Check if npm packages installed
if (Test-Path node_modules) { Write-Host "✓ Packages installed" } else { Write-Host "✗ Need: npm install" }
```

---

## Step-by-Step Setup

### ✅ Step 1: Install PostGIS (If Not Already Installed)

**Check if PostGIS is installed:**
```powershell
psql -U postgres -d postgres -c "SELECT PostGIS_version();"
```

**If error, install PostGIS:**
1. Open **Stack Builder** from Start Menu
2. Select PostgreSQL 17
3. Install **PostGIS Bundle**

**OR** download from: https://postgis.net/windows_downloads/

---

### ✅ Step 2: Create Database

**Option A: Use the automated script**
```powershell
cd c:\Users\yousu\Desktop\taxi\taxi_app\backend
.\setup_database.bat
```

**Option B: Manual commands**
```powershell
# Create database
psql -U postgres -c "CREATE DATABASE taxi_fare_db;"

# Enable PostGIS
psql -U postgres -d taxi_fare_db -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```

---

### ✅ Step 3: Run Database Schema

```powershell
cd c:\Users\yousu\Desktop\taxi\taxi_app\backend
psql -U postgres -d taxi_fare_db -f schema.sql
```

**Expected output:** Should see "CREATE TABLE", "CREATE INDEX" messages

---

### ✅ Step 4: Verify .env Configuration

Check your `.env` file has correct values:

```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=taxi_fare_db
DB_USER=postgres
DB_PASSWORD=YOUR_ACTUAL_PASSWORD  ← Make sure this is correct!
PORT=3000
```

**Important:** Replace `YOUR_ACTUAL_PASSWORD` with your PostgreSQL password!

---

### ✅ Step 5: Install Node Dependencies

```powershell
cd c:\Users\yousu\Desktop\taxi\taxi_app\backend
npm install
```

**Expected:** Should install all packages (may take 1-2 minutes)

---

### ✅ Step 6: Test Database Connection

```powershell
npm run dev
```

**Expected output:**
```
Server running on port 3000
```

**If you see database connection errors:**
- Check `.env` file has correct password
- Verify PostgreSQL service is running
- Check database exists: `psql -U postgres -lqt | findstr taxi_fare_db`

---

### ✅ Step 7: Test API Endpoint

Open browser: http://localhost:3000/api/v1/zones

**OR** in PowerShell:
```powershell
curl http://localhost:3000/api/v1/zones
```

**Expected:** JSON response with zones data

---

## 🎯 Success Indicators

✅ Database `taxi_fare_db` exists  
✅ PostGIS extension enabled  
✅ Schema tables created  
✅ `.env` file configured  
✅ npm packages installed  
✅ Server starts without errors  
✅ API endpoint responds  

---

## 🐛 Troubleshooting

### "Database connection error"
- Check PostgreSQL password in `.env`
- Verify PostgreSQL service is running
- Test connection: `psql -U postgres -d taxi_fare_db`

### "PostGIS extension not found"
- Install PostGIS (see Step 1)
- Verify: `psql -U postgres -d taxi_fare_db -c "SELECT PostGIS_version();"`

### "Port 3000 already in use"
- Change PORT in `.env` to 3001
- Or find and close process: `netstat -ano | findstr :3000`

### "npm install fails"
- Make sure Node.js is installed: `node --version`
- Try: `npm cache clean --force` then `npm install`

---

## 🚀 Next Steps After Backend is Running

1. ✅ Backend server running on port 3000
2. 📱 Update Flutter app API URL
3. 🧪 Test ride booking flow
4. 🎉 Start using your app!

---

**Ready to proceed?** Let me know which step you're on or if you encounter any errors!
