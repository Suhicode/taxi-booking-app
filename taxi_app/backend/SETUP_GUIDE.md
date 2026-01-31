 # Backend Setup Guide

## Prerequisites

1. **Node.js** (v16 or higher)
2. **PostgreSQL** (v12 or higher) with **PostGIS** extension
3. **Redis** (v6 or higher) - Optional but recommended

## Step 1: Install PostgreSQL with PostGIS

### Windows:
1. Download PostgreSQL from https://www.postgresql.org/download/windows/
2. During installation, select "PostGIS" extension
3. Or install PostGIS separately after PostgreSQL installation

### Linux (Ubuntu/Debian):
```bash
sudo apt-get update
sudo apt-get install postgresql postgresql-contrib
sudo apt-get install postgis postgresql-12-postgis-3
```

### macOS:
```bash
brew install postgresql
brew install postgis
```

## Step 2: Create Database

1. Open PostgreSQL command line or pgAdmin
2. Run the following commands:

```sql
-- Create database
CREATE DATABASE taxi_fare_db;

-- Connect to database
\c taxi_fare_db

-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
```

## Step 3: Run Database Schema

```bash
cd backend
psql -U postgres -d taxi_fare_db -f schema.sql
```

Or using pgAdmin:
1. Right-click on `taxi_fare_db` → Query Tool
2. Open `schema.sql` file
3. Execute the script

## Step 4: Install Redis (Optional)

### Windows:
Download from https://redis.io/download or use WSL

### Linux:
```bash
sudo apt-get install redis-server
sudo systemctl start redis
```

### macOS:
```bash
brew install redis
brew services start redis
```

## Step 5: Configure Environment Variables

1. Copy `.env.example` to `.env`:
```bash
cd backend
cp .env.example .env
```

2. Edit `.env` file with your actual values:
```env
DB_HOST=localhost
DB_PORT=5432
DB_NAME=taxi_fare_db
DB_USER=postgres
DB_PASSWORD=your_actual_password

REDIS_HOST=localhost
REDIS_PORT=6379

PORT=3000
```

## Step 6: Install Node Dependencies

```bash
cd backend
npm install
```

## Step 7: Start the Server

### Development mode (with auto-reload):
```bash
npm run dev
```

### Production mode:
```bash
npm start
```

## Step 8: Verify Setup

1. Server should start on `http://localhost:3000`
2. Test the API:
```bash
curl http://localhost:3000/api/v1/zones
```

## Troubleshooting

### Database Connection Error:
- Check PostgreSQL is running: `pg_isready`
- Verify credentials in `.env` file
- Check PostgreSQL is listening on correct port (default: 5432)

### PostGIS Extension Error:
- Make sure PostGIS is installed: `SELECT PostGIS_version();`
- If not installed, run: `CREATE EXTENSION postgis;`

### Redis Connection Error:
- Check Redis is running: `redis-cli ping` (should return PONG)
- If Redis is not available, the app will work without it (using database fallback)

### Port Already in Use:
- Change `PORT` in `.env` file
- Or kill the process using port 3000

## Next Steps

1. Seed sample data (optional):
```bash
psql -U postgres -d taxi_fare_db -f sample_data.sql
```

2. Test API endpoints using Postman or curl

3. Connect Flutter app to backend (update API base URL in `lib/services/api_client.dart`)

## API Base URL

- **Local development**: `http://localhost:3000`
- **Android Emulator**: `http://10.0.2.2:3000`
- **Physical Device**: `http://YOUR_COMPUTER_IP:3000` (e.g., `http://192.168.1.100:3000`)

## Production Deployment

1. Use environment variables for all sensitive data
2. Enable SSL/HTTPS
3. Set up proper database backups
4. Configure Redis for production
5. Set up monitoring and logging
6. Use process manager (PM2) for Node.js
