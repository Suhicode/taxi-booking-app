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

-- Sample zones for Mumbai (inserted as sample data)
INSERT INTO zones (name, slug, geom, base_fare, per_km, per_min, minimum_fare, surge_enabled) VALUES
(
    'South Mumbai',
    'south-mumbai',
    ST_GeomFromGeoJSON('{"type":"Polygon","coordinates":[[[72.8197,19.0200],[72.8197,19.0300],[72.8297,19.0300],[72.8297,19.0200],[72.8197,19.0200]]}'),
    40.00,
    18.00,
    2.50,
    60.00,
    true
),
(
    'Bandra West',
    'bandra-west',
    ST_GeomFromGeoJSON('{"type":"Polygon","coordinates":[[[72.8300,19.0600],[72.8300,19.0700],[72.8400,19.0700],[72.8400,19.0600],[72.8300,19.0600]]}'),
    35.00,
    16.00,
    2.00,
    55.00,
    false
),
(
    'Andheri East',
    'andheri-east',
    ST_GeomFromGeoJSON('{"type":"Polygon","coordinates":[[[72.8700,19.1100],[72.8700,19.1200],[72.8800,19.1200],[72.8800,19.1100],[72.8700,19.1100]]}'),
    30.00,
    15.00,
    1.50,
    50.00,
    false
)
ON CONFLICT (slug) DO NOTHING;

-- Sample zone rates (special pricing between zones)
INSERT INTO zone_rates (from_zone_id, to_zone_id, base_fare, per_km, minimum_fare) VALUES
(1, 2, 45.00, 20.00, 70.00),
(2, 1, 45.00, 20.00, 70.00),
(1, 3, 50.00, 22.00, 80.00),
(3, 1, 50.00, 22.00, 80.00)
ON CONFLICT (from_zone_id, to_zone_id) DO NOTHING;
