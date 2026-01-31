# 🚀 Quick Start - Windows (PostgreSQL Already Installed)

## ✅ What You Have
- ✅ PostgreSQL 17.5 installed
- ✅ Backend code ready

## 📋 What You Need to Do (5 Steps)

### Step 1: Install PostGIS Extension ⚠️ IMPORTANT

PostGIS is required for geospatial features. Install it:

**Option 1: Using Stack Builder (Easiest)**
1. Open **Stack Builder** from Start Menu
2. Select your PostgreSQL 17 installation
3. Expand **Spatial Extensions**
4. Check **PostGIS Bundle**
5. Install

**Option 2: Download Installer**
- Go to: https://postgis.net/windows_downloads/
- Download PostGIS 3.x for PostgreSQL 17
- Run installer

### Step 2: Create Database

Open **PowerShell** or **Command Prompt** and run:

```powershell
# You'll be asked for PostgreSQL password
psql -U postgres -c "CREATE DATABASE taxi_fare_db;"
psql -U postgres -d taxi_fare_db -c "CREATE EXTENSION IF NOT EXISTS postgis;"
```

**OR** use the automated script:
```powershell
cd c:\Users\yousu\Desktop\taxi\taxi_app\backend
.\setup_database.bat
```

### Step 3: Run Database Schema

```powershell
cd c:\Users\yousu\Desktop\taxi\taxi_app\backend
psql -U postgres -d taxi_fare_db -f schema.sql
```

### Step 4: Configure Environment

1. Copy environment file:
```powershell
copy env.example .env
```

2. Edit `.env` file (open with Notepad):
   - Change `DB_PASSWORD=your_password_here` to your actual PostgreSQL password
   - Keep other values as default

### Step 5: Install & Start

```powershell
npm install
npm run dev
```

Server should start on **http://localhost:3000** ✅

---

## 🧪 Test It

Open browser: http://localhost:3000/api/v1/zones

Should return JSON with zones data.

---

## ❓ Common Issues

**"psql not found"**
- Use full path: `"C:\Program Files\PostgreSQL\17\bin\psql.exe" -U postgres ...`

**"PostGIS extension not found"**
- Install PostGIS first (Step 1)

**"Password authentication failed"**
- Use the password you set during PostgreSQL installation

**"Database already exists"**
- That's fine! Just continue to Step 3

---

## 🎯 Next: Connect Flutter App

Once backend is running:
1. Update `lib/services/api_client.dart`:
   - Change baseUrl to: `http://10.0.2.2:3000/api/v1` (for Android emulator)
2. Run Flutter app: `flutter run`

---

**Need help?** Check `WINDOWS_SETUP.md` for detailed troubleshooting.
