-- Postgres + PostGIS Schema for Zone-based Fare Estimation
-- Run: CREATE EXTENSION IF NOT EXISTS postgis;

-- Zones table with pricing information
CREATE TABLE IF NOT EXISTS zones (
    id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    slug VARCHAR(100) UNIQUE NOT NULL,
    geom GEOMETRY(POLYGON, 4326) NOT NULL,
    base_fare DECIMAL(10,2) NOT NULL DEFAULT 30.00,
    per_km DECIMAL(10,2) NOT NULL DEFAULT 15.00,
    per_min DECIMAL(10,2) NOT NULL DEFAULT 2.00,
    minimum_fare DECIMAL(10,2) NOT NULL DEFAULT 50.00,
    surge_enabled BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Zone rates for specific from_zone -> to_zone overrides
CREATE TABLE IF NOT EXISTS zone_rates (
    id SERIAL PRIMARY KEY,
    from_zone_id INTEGER NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
    to_zone_id INTEGER NOT NULL REFERENCES zones(id) ON DELETE CASCADE,
    base_fare DECIMAL(10,2),
    per_km DECIMAL(10,2),
    per_min DECIMAL(10,2),
    minimum_fare DECIMAL(10,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(from_zone_id, to_zone_id)
);

-- Trips table
CREATE TABLE IF NOT EXISTS trips (
    id SERIAL PRIMARY KEY,
    pickup_point GEOMETRY(POINT, 4326) NOT NULL,
    pickup_zone_id INTEGER REFERENCES zones(id),
    drop_point GEOMETRY(POINT, 4326) NOT NULL,
    drop_zone_id INTEGER REFERENCES zones(id),
    distance_km DECIMAL(8,3),
    duration_min INTEGER,
    fare DECIMAL(10,2),
    surge_multiplier DECIMAL(5,2) DEFAULT 1.00,
    status VARCHAR(50) DEFAULT 'pending',
    vehicle_type VARCHAR(50) DEFAULT 'standard',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Drivers table for location tracking
CREATE TABLE IF NOT EXISTS drivers (
    id SERIAL PRIMARY KEY,
    driver_id VARCHAR(100) UNIQUE NOT NULL,
    name VARCHAR(255),
    vehicle_type VARCHAR(50) DEFAULT 'standard',
    current_location GEOMETRY(POINT, 4326),
    is_online BOOLEAN DEFAULT false,
    last_location_update TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create spatial indexes for performance
CREATE INDEX IF NOT EXISTS idx_zones_geom ON zones USING GIST (geom);
CREATE INDEX IF NOT EXISTS idx_trips_pickup_point ON trips USING GIST (pickup_point);
CREATE INDEX IF NOT EXISTS idx_trips_drop_point ON trips USING GIST (drop_point);
CREATE INDEX IF NOT EXISTS idx_drivers_current_location ON drivers USING GIST (current_location);

-- Update trigger for timestamps
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_zones_updated_at BEFORE UPDATE ON zones FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_trips_updated_at BEFORE UPDATE ON trips FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
