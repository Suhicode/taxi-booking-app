const express = require('express');
const cors = require('cors');
const http = require('http');
const { Pool } = require('pg');
const Redis = require('ioredis');
const dotenv = require('dotenv');
const { Server } = require('socket.io');
dotenv.config();

const fareRoutes = require('./fare.routes');
const Joi = require('joi');
require('dotenv').config();

// Initialize Express app
const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use('/api/v1', fareRoutes);

// Database connection
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: process.env.DB_PORT || 5432,
  database: process.env.DB_NAME || 'taxi_fare_db',
  user: process.env.DB_USER || 'postgres',
  password: process.env.DB_PASSWORD || 'password',
});

// Redis connection (optional)
let redisClient = null;
try {
  redisClient = redis.createClient({
    host: process.env.REDIS_HOST || 'localhost',
    port: process.env.REDIS_PORT || 6379,
    password: process.env.REDIS_PASSWORD,
  });

  redisClient.on('error', (err) => {
    console.error('Redis Client Error:', err);
    redisClient = null; // Disable Redis on error
  });
  
  redisClient.connect();
} catch (err) {
  console.warn('Redis not available, running without Redis:', err.message);
}

// Validation schemas
const pointSchema = Joi.object({
  lat: Joi.number().min(-90).max(90).required(),
  lon: Joi.number().min(-180).max(180).required()
});

const estimateFareSchema = Joi.object({
  pickup: pointSchema.required(),
  drop: pointSchema.required(),
  usePickupZoneRates: Joi.boolean().default(true),
  vehicleType: Joi.string().valid('bike', 'scooty', 'standard', 'comfort', 'premium', 'xl').default('standard')
});

// Mock Directions API (replace with Google Maps or Mapbox)
async function getDirections(pickup, drop) {
  // This is a stub implementation
  const distance = calculateDistance(pickup.lat, pickup.lon, drop.lat, drop.lon);
  const duration = Math.round(distance * 3); // Rough estimate: 3 minutes per km
  
  return {
    distance_km: distance,
    duration_min: duration,
    geometry: null // Would contain route geometry from real API
  };
}

// Calculate distance between two points (Haversine formula)
function calculateDistance(lat1, lon1, lat2, lon2) {
  const R = 6371; // Earth's radius in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLon = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLon/2) * Math.sin(dLon/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
}

// Calculate dynamic surge multiplier based on demand and supply
async function getSurgeMultiplier(zoneId) {
  if (!zoneId) return 1.0; // No surge if no zone specified
  
  try {
    // 1. Check if surge is enabled for this zone
    const zoneCheck = await pool.query(
      'SELECT surge_enabled FROM zones WHERE id = $1', 
      [zoneId]
    );
    
    if (zoneCheck.rows.length === 0 || !zoneCheck.rows[0].surge_enabled) {
      return 1.0; // No surge if zone not found or surge not enabled
    }

    // 2. Get number of active ride requests in last 15 minutes
    const activeRides = await pool.query(
      `SELECT COUNT(*) as count FROM trips 
       WHERE pickup_zone_id = $1 
       AND status = 'accepted' 
       AND created_at > NOW() - INTERVAL '15 minutes'`,
      [zoneId]
    );

    // 3. Get number of available drivers in zone
    const availableDrivers = await pool.query(
      `SELECT COUNT(*) as count FROM drivers 
       WHERE is_online = true 
       AND current_zone_id = $1`,
      [zoneId]
    );

    const rideCount = parseInt(activeRides.rows[0].count) || 0;
    const driverCount = parseInt(availableDrivers.rows[0].count) || 1; // Avoid division by zero
    
    // 4. Calculate demand ratio (rides per available driver)
    const demandRatio = rideCount / driverCount;
    
    // 5. Apply surge based on demand (example: 1.2x to 3.0x)
    let surgeMultiplier = 1.0;
    if (demandRatio > 2) {
      surgeMultiplier = 3.0; // High demand
    } else if (demandRatio > 1) {
      surgeMultiplier = 1.5 + (demandRatio - 1); // Scale between 1.5x and 3.0x
    } else if (demandRatio > 0.5) {
      surgeMultiplier = 1.0 + ((demandRatio - 0.5) * 1.0); // Scale between 1.0x and 1.5x
    }

    // 6. Apply time-based surge (evening rush hour example)
    const now = new Date();
    const hour = now.getHours();
    if ((hour >= 17 && hour < 20) || (hour >= 8 && hour < 10)) {
      // Rush hour - add 20% to surge
      surgeMultiplier = Math.min(surgeMultiplier * 1.2, 3.0);
    }

    // Round to nearest 0.1
    return Math.min(Math.round(surgeMultiplier * 10) / 10, 3.0);
    
  } catch (error) {
    console.error('Error calculating surge multiplier:', error);
    return 1.0; // Default to no surge on error
  }
}

// Get zone for a point
async function getZoneForPoint(lat, lon) {
  const query = `
    SELECT id, name, slug, base_fare, per_km, per_min, minimum_fare, surge_enabled
    FROM zones 
    WHERE ST_Contains(geom, ST_SetSRID(ST_MakePoint($1, $2), 4326))
    LIMIT 1
  `;
  
  const result = await pool.query(query, [lon, lat]);
  
  if (result.rows.length === 0) {
    // Return default zone if no zone found
    return {
      id: null,
      name: 'Default Zone',
      slug: 'default',
      base_fare: 30.00,
      per_km: 15.00,
      per_min: 2.00,
      minimum_fare: 50.00,
      surge_enabled: false
    };
  }
  
  return result.rows[0];
}

// Get zone rates for specific from_zone -> to_zone
async function getZoneRates(fromZoneId, toZoneId) {
  const query = `
    SELECT base_fare, per_km, per_min, minimum_fare
    FROM zone_rates 
    WHERE from_zone_id = $1 AND to_zone_id = $2
    LIMIT 1
  `;
  
  const result = await pool.query(query, [fromZoneId, toZoneId]);
  return result.rows[0] || null;
}

// Calculate fare based on zones and distance
async function calculateFare(pickupZone, dropZone, distanceKm, durationMin, usePickupZoneRates, vehicleType) {
  let rates;
  
  // Check for specific zone rates first
  if (pickupZone.id && dropZone.id) {
    const zoneRates = await getZoneRates(pickupZone.id, dropZone.id);
    if (zoneRates) {
      rates = zoneRates;
    }
  }
  
  // If no specific rates, use zone-based or average
  if (!rates) {
    if (usePickupZoneRates) {
      rates = pickupZone;
    } else {
      // Average of pickup and drop zones
      rates = {
        base_fare: (pickupZone.base_fare + dropZone.base_fare) / 2,
        per_km: (pickupZone.per_km + dropZone.per_km) / 2,
        per_min: (pickupZone.per_min + dropZone.per_min) / 2,
        minimum_fare: Math.max(pickupZone.minimum_fare, dropZone.minimum_fare)
      };
    }
  }
  
  // Apply vehicle type multipliers
  const vehicleMultipliers = {
    'bike': 0.6,
    'scooty': 0.7,
    'standard': 1.0,
    'comfort': 1.3,
    'premium': 1.8,
    'xl': 1.5
  };
  
  const multiplier = vehicleMultipliers[vehicleType] || 1.0;
  
  // Calculate fare components
  const baseFare = rates.base_fare * multiplier;
  const distanceFare = rates.per_km * distanceKm * multiplier;
  const timeFare = rates.per_min * durationMin * multiplier;
  const surgeMultiplier = await getSurgeMultiplier(pickupZone.id);
  
  let totalFare = baseFare + distanceFare + timeFare;
  totalFare = Math.max(totalFare, rates.minimum_fare * multiplier);
  totalFare = totalFare * surgeMultiplier;
  
  // Round to nearest rupee
  totalFare = Math.round(totalFare);
  
  return {
    fare: totalFare,
    breakdown: {
      base_fare: Math.round(baseFare),
      distance_km: Math.round(distanceKm * 10) / 10,
      per_km: rates.per_km,
      duration_min: durationMin,
      per_min: rates.per_min,
      minimum_fare: Math.round(rates.minimum_fare * multiplier),
      surge_multiplier: surgeMultiplier,
      vehicle_multiplier: multiplier,
      total_before_rounding: Math.round((baseFare + distanceFare + timeFare) * surgeMultiplier * 10) / 10
    }
  };
}

// API Routes

// POST /api/v1/zone-for-point
app.post('/api/v1/zone-for-point', async (req, res) => {
  try {
    const { error, value } = pointSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    
    const zone = await getZoneForPoint(value.lat, value.lon);
    
    res.json({
      zone: zone,
      method: 'postgis'
    });
  } catch (err) {
    console.error('Error in zone-for-point:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/v1/estimate-fare
app.post('/api/v1/estimate-fare', async (req, res) => {
  try {
    const { error, value } = estimateFareSchema.validate(req.body);
    if (error) {
      return res.status(400).json({ error: error.details[0].message });
    }
    
    const { pickup, drop, usePickupZoneRates, vehicleType } = value;
    
    // Get directions (distance and duration)
    const directions = await getDirections(pickup, drop);
    
    // Get zones for pickup and drop
    const pickupZone = await getZoneForPoint(pickup.lat, pickup.lon);
    const dropZone = await getZoneForPoint(drop.lat, drop.lon);
    
    // Calculate fare
    const fareResult = await calculateFare(
      pickupZone, 
      dropZone, 
      directions.distance_km, 
      directions.duration_min, 
      usePickupZoneRates,
      vehicleType
    );
    
    res.json({
      fare: fareResult.fare,
      breakdown: fareResult.breakdown,
      pickup_zone: pickupZone,
      drop_zone: dropZone,
      directions: {
        distance_km: directions.distance_km,
        duration_min: directions.duration_min
      }
    });
  } catch (err) {
    console.error('Error in estimate-fare:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/v1/driver-location
app.post('/api/v1/driver-location', async (req, res) => {
  try {
    const { driverId, lat, lon } = req.body;
    
    if (!driverId || !lat || !lon) {
      return res.status(400).json({ error: 'driverId, lat, and lon are required' });
    }
    
    // Store in Redis for geospatial queries (if available)
    if (redisClient) {
      await redisClient.geoAdd('drivers', {
        member: driverId,
        longitude: lon,
        latitude: lat
      });
    }
    
    // Update database
    await pool.query(
      `INSERT INTO drivers (driver_id, current_location, last_location_update, is_online)
       VALUES ($1, ST_SetSRID(ST_MakePoint($2, $3), 4326), CURRENT_TIMESTAMP, true)
       ON CONFLICT (driver_id) 
       DO UPDATE SET 
         current_location = ST_SetSRID(ST_MakePoint($2, $3), 4326),
         last_location_update = CURRENT_TIMESTAMP,
         is_online = true`,
      [driverId, lon, lat]
    );
    
    res.json({ success: true });
  } catch (err) {
    console.error('Error in driver-location:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/v1/nearby-drivers
app.get('/api/v1/nearby-drivers', async (req, res) => {
  try {
    const { lat, lon, radius = 5 } = req.query;
    
    if (!lat || !lon) {
      return res.status(400).json({ error: 'lat and lon are required' });
    }
    
    // Find nearby drivers using Redis GEORADIUS (if available)
    let nearbyDrivers = [];
    if (redisClient) {
      nearbyDrivers = await redisClient.geoRadiusWithCoordinates(
        'drivers',
        {
          longitude: parseFloat(lon),
          latitude: parseFloat(lat)
        },
        parseFloat(radius),
        'km'
      );
    } else {
      // Fallback to database query if Redis is not available
      const result = await pool.query(
        `SELECT driver_id, 
                ST_Distance(current_location, ST_SetSRID(ST_MakePoint($2, $1), 4326)) as distance
         FROM drivers 
         WHERE is_online = true
           AND ST_DWithin(current_location, ST_SetSRID(ST_MakePoint($2, $1), 4326), $3)
         ORDER BY distance`,
        [parseFloat(lat), parseFloat(lon), parseFloat(radius) * 1000] // radius in meters
      );
      
      nearbyDrivers = result.rows.map(row => ({
        member: row.driver_id,
        distance: row.distance / 1000 // convert to km
      }));
    }
    
    res.json({
      drivers: nearbyDrivers.map(driver => ({
        driverId: driver.member,
        distance: driver.distance,
        location: {
          lat: driver.coordinates.latitude,
          lon: driver.coordinates.longitude
        }
      }))
    });
  } catch (err) {
    console.error('Error in nearby-drivers:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// POST /api/v1/zones (for admin zone creation)
app.post('/api/v1/zones', async (req, res) => {
  try {
    const { name, slug, geom, base_fare, per_km, per_min, minimum_fare, surge_enabled } = req.body;
    
    if (!name || !slug || !geom) {
      return res.status(400).json({ error: 'name, slug, and geom are required' });
    }
    
    const query = `
      INSERT INTO zones (name, slug, geom, base_fare, per_km, per_min, minimum_fare, surge_enabled)
      VALUES ($1, $2, ST_SetSRID(ST_GeomFromGeoJSON($3), 4326), $4, $5, $6, $7, $8)
      RETURNING id, name, slug, base_fare, per_km, per_min, minimum_fare, surge_enabled
    `;
    
    const result = await pool.query(query, [
      name, slug, JSON.stringify(geom), 
      base_fare || 30.00, per_km || 15.00, per_min || 2.00, 
      minimum_fare || 50.00, surge_enabled || false
    ]);
    
    res.json(result.rows[0]);
  } catch (err) {
    console.error('Error creating zone:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/v1/zones (list all zones)
app.get('/api/v1/zones', async (req, res) => {
  try {
    const query = `
      SELECT id, name, slug, base_fare, per_km, per_min, minimum_fare, surge_enabled,
             ST_AsGeoJSON(geom) as geom
      FROM zones
      ORDER BY name
    `;
    
    const result = await pool.query(query);
    
    res.json(result.rows.map(row => ({
      ...row,
      geom: JSON.parse(row.geom)
    })));
  } catch (err) {
    console.error('Error fetching zones:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// ========== RIDE ENDPOINTS ==========

// POST /api/v1/rides - Create a new ride request
app.post('/api/v1/rides', async (req, res) => {
  try {
    const { 
      customerId, 
      customerName, 
      customerPhone,
      pickupLat, 
      pickupLon, 
      pickupAddress,
      dropLat, 
      dropLon, 
      dropAddress,
      vehicleType,
      estimatedFare,
      distanceKm
    } = req.body;
    
    if (!customerId || !pickupLat || !pickupLon || !dropLat || !dropLon) {
      return res.status(400).json({ error: 'Missing required fields' });
    }
    
    // Get zones for pickup and drop
    const pickupZone = await getZoneForPoint(parseFloat(pickupLat), parseFloat(pickupLon));
    const dropZone = await getZoneForPoint(parseFloat(dropLat), parseFloat(dropLon));
    
    // Get directions
    const directions = await getDirections(
      { lat: parseFloat(pickupLat), lon: parseFloat(pickupLon) },
      { lat: parseFloat(dropLat), lon: parseFloat(dropLon) }
    );
    
    // Calculate fare if not provided
    let finalFare = estimatedFare;
    if (!finalFare) {
      const fareResult = await calculateFare(
        pickupZone,
        dropZone,
        distanceKm || directions.distance_km,
        directions.duration_min,
        true,
        vehicleType || 'standard'
      );
      finalFare = fareResult.fare;
    }
    
    // Insert ride into database
    const query = `
      INSERT INTO trips (
        pickup_point, pickup_zone_id, drop_point, drop_zone_id,
        distance_km, duration_min, fare, vehicle_type, status
      ) VALUES (
        ST_SetSRID(ST_MakePoint($1, $2), 4326), $3,
        ST_SetSRID(ST_MakePoint($4, $5), 4326), $6,
        $7, $8, $9, $10, 'pending'
      )
      RETURNING id, status, created_at
    `;
    
    const result = await pool.query(query, [
      parseFloat(pickupLon), parseFloat(pickupLat), pickupZone.id,
      parseFloat(dropLon), parseFloat(dropLat), dropZone.id,
      distanceKm || directions.distance_km,
      directions.duration_min,
      finalFare,
      vehicleType || 'standard'
    ]);
    
    const rideId = result.rows[0].id;
    
    // Store additional ride metadata (customer info, addresses) in a separate table or JSON
    // For now, we'll add a rides_metadata table or use trips table with JSON column
    // This is a simplified version - you may want to expand this
    
    // Broadcast ride request to nearby drivers via Socket.IO
    io.emit('new-ride-request', {
      rideId,
      pickup: { lat: parseFloat(pickupLat), lon: parseFloat(pickupLon) },
      drop: { lat: parseFloat(dropLat), lon: parseFloat(dropLon) },
      vehicleType: vehicleType || 'standard',
      fare: finalFare,
      customerName: customerName || 'Customer',
      customerPhone: customerPhone || ''
    });
    
    res.json({
      success: true,
      rideId,
      fare: finalFare,
      estimatedDuration: directions.duration_min,
      distance: distanceKm || directions.distance_km,
      status: 'pending'
    });
  } catch (err) {
    console.error('Error creating ride:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/v1/rides/:id - Get ride details
app.get('/api/v1/rides/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const query = `
      SELECT 
        t.id, t.status, t.fare, t.vehicle_type, t.distance_km, t.duration_min,
        t.created_at, t.updated_at,
        ST_Y(t.pickup_point) as pickup_lat, ST_X(t.pickup_point) as pickup_lon,
        ST_Y(t.drop_point) as drop_lat, ST_X(t.drop_point) as drop_lon,
        t.pickup_zone_id, t.drop_zone_id,
        z1.name as pickup_zone_name, z2.name as drop_zone_name
      FROM trips t
      LEFT JOIN zones z1 ON t.pickup_zone_id = z1.id
      LEFT JOIN zones z2 ON t.drop_zone_id = z2.id
      WHERE t.id = $1
    `;
    
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Ride not found' });
    }
    
    const ride = result.rows[0];
    res.json({
      id: ride.id,
      status: ride.status,
      fare: parseFloat(ride.fare),
      vehicleType: ride.vehicle_type,
      distance: parseFloat(ride.distance_km),
      duration: ride.duration_min,
      pickup: {
        lat: parseFloat(ride.pickup_lat),
        lon: parseFloat(ride.pickup_lon)
      },
      drop: {
        lat: parseFloat(ride.drop_lat),
        lon: parseFloat(ride.drop_lon)
      },
      pickupZone: ride.pickup_zone_name,
      dropZone: ride.drop_zone_name,
      createdAt: ride.created_at,
      updatedAt: ride.updated_at
    });
  } catch (err) {
    console.error('Error fetching ride:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT /api/v1/rides/:id/accept - Driver accepts a ride
app.put('/api/v1/rides/:id/accept', async (req, res) => {
  try {
    const { id } = req.params;
    const { driverId, driverName } = req.body;
    
    if (!driverId) {
      return res.status(400).json({ error: 'driverId is required' });
    }
    
    // Update ride status
    const query = `
      UPDATE trips 
      SET status = 'accepted', updated_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND status = 'pending'
      RETURNING id, status
    `;
    
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Ride not found or already accepted' });
    }
    
    // Notify customer via Socket.IO
    io.emit('ride-accepted', {
      rideId: id,
      driverId,
      driverName: driverName || 'Driver'
    });
    
    res.json({ success: true, rideId: id, status: 'accepted' });
  } catch (err) {
    console.error('Error accepting ride:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT /api/v1/rides/:id/start - Driver starts the ride
app.put('/api/v1/rides/:id/start', async (req, res) => {
  try {
    const { id } = req.params;
    
    const query = `
      UPDATE trips 
      SET status = 'in_progress', updated_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND status = 'accepted'
      RETURNING id, status
    `;
    
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Ride not found or cannot be started' });
    }
    
    // Notify customer
    io.emit('ride-started', { rideId: id });
    
    res.json({ success: true, rideId: id, status: 'in_progress' });
  } catch (err) {
    console.error('Error starting ride:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT /api/v1/rides/:id/complete - Complete a ride
app.put('/api/v1/rides/:id/complete', async (req, res) => {
  try {
    const { id } = req.params;
    const { actualFare, rating, feedback } = req.body;
    
    let query;
    let params;
    
    if (actualFare) {
      query = `
        UPDATE trips 
        SET status = 'completed', fare = $2, updated_at = CURRENT_TIMESTAMP
        WHERE id = $1 AND status = 'in_progress'
        RETURNING id, status, fare
      `;
      params = [id, actualFare];
    } else {
      query = `
        UPDATE trips 
        SET status = 'completed', updated_at = CURRENT_TIMESTAMP
        WHERE id = $1 AND status = 'in_progress'
        RETURNING id, status, fare
      `;
      params = [id];
    }
    
    const result = await pool.query(query, params);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Ride not found or cannot be completed' });
    }
    
    // Notify customer
    io.emit('ride-completed', { 
      rideId: id, 
      fare: parseFloat(result.rows[0].fare),
      rating,
      feedback
    });
    
    res.json({ 
      success: true, 
      rideId: id, 
      status: 'completed',
      fare: parseFloat(result.rows[0].fare)
    });
  } catch (err) {
    console.error('Error completing ride:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// PUT /api/v1/rides/:id/cancel - Cancel a ride
app.put('/api/v1/rides/:id/cancel', async (req, res) => {
  try {
    const { id } = req.params;
    const { reason } = req.body;
    
    const query = `
      UPDATE trips 
      SET status = 'cancelled', updated_at = CURRENT_TIMESTAMP
      WHERE id = $1 AND status IN ('pending', 'accepted')
      RETURNING id, status
    `;
    
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Ride not found or cannot be cancelled' });
    }
    
    // Notify relevant parties
    io.emit('ride-cancelled', { rideId: id, reason });
    
    res.json({ success: true, rideId: id, status: 'cancelled' });
  } catch (err) {
    console.error('Error cancelling ride:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// GET /api/v1/rides/customer/:customerId - Get all rides for a customer
app.get('/api/v1/rides/customer/:customerId', async (req, res) => {
  try {
    const { customerId } = req.params;
    // Note: You'll need to add customer_id column to trips table
    // For now, this is a placeholder
    res.json({ rides: [], message: 'Customer ID tracking not yet implemented in trips table' });
  } catch (err) {
    console.error('Error fetching customer rides:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Serve static files (admin interface)
app.use(express.static(__dirname));

// DELETE /api/v1/zones/:id
app.delete('/api/v1/zones/:id', async (req, res) => {
  try {
    const { id } = req.params;
    
    const query = 'DELETE FROM zones WHERE id = $1 RETURNING id, name';
    const result = await pool.query(query, [id]);
    
    if (result.rows.length === 0) {
      return res.status(404).json({ error: 'Zone not found' });
    }
    
    res.json({ success: true, deleted: result.rows[0] });
  } catch (err) {
    console.error('Error deleting zone:', err);
    res.status(500).json({ error: 'Internal server error' });
  }
});

const PORT = process.env.PORT || 3000;

// Create HTTP server
const server = http.createServer(app);

// Initialize Socket.IO
const io = new Server(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"]
  }
});

// Socket.IO for real-time features
io.on('connection', (socket) => {
  console.log('Client connected:', socket.id);
  
  // Driver location updates
  socket.on('driver-location-update', async (data) => {
    try {
      const { driverId, lat, lon } = data;
      
      // Update Redis (if available)
      if (redisClient) {
        await redisClient.geoAdd('drivers', {
          member: driverId,
          longitude: lon,
          latitude: lat
        });
      }
      
      // Broadcast to nearby riders
      let nearbyDrivers = [];
      if (redisClient) {
        nearbyDrivers = await redisClient.geoRadiusWithCoordinates(
          'drivers',
          {
            longitude: lon,
            latitude: lat
          },
          10, // 10km radius
          'km'
        );
      }
      
      socket.broadcast.emit('nearby-drivers-update', nearbyDrivers);
    } catch (err) {
      console.error('Error in driver-location-update:', err);
    }
  });
  
  // Rider subscribes to trip updates
  socket.on('subscribe-trip', (tripId) => {
    socket.join(`trip:${tripId}`);
    console.log(`Client ${socket.id} subscribed to trip ${tripId}`);
  });
  
  // Driver subscribes to ride requests
  socket.on('driver-online', async (data) => {
    const { driverId, lat, lon } = data;
    socket.join(`driver:${driverId}`);
    
    // Update driver location
    if (lat && lon) {
      await pool.query(
        `INSERT INTO drivers (driver_id, current_location, is_online, last_location_update)
         VALUES ($1, ST_SetSRID(ST_MakePoint($2, $3), 4326), true, CURRENT_TIMESTAMP)
         ON CONFLICT (driver_id) 
         DO UPDATE SET 
           current_location = ST_SetSRID(ST_MakePoint($2, $3), 4326),
           is_online = true,
           last_location_update = CURRENT_TIMESTAMP`,
        [driverId, lon, lat]
      );
    }
    
    console.log(`Driver ${driverId} is now online`);
  });
  
  // Driver goes offline
  socket.on('driver-offline', async (data) => {
    const { driverId } = data;
    await pool.query(
      `UPDATE drivers SET is_online = false WHERE driver_id = $1`,
      [driverId]
    );
    console.log(`Driver ${driverId} is now offline`);
  });
  
  // Driver emits trip location updates
  socket.on('trip-location-update', (data) => {
    const { tripId, lat, lon } = data;
    socket.to(`trip:${tripId}`).emit('trip-location', { lat, lon });
  });
  
  // Driver accepts ride request
  socket.on('accept-ride-request', async (data) => {
    const { rideId, driverId, driverName } = data;
    // This will be handled by the REST API endpoint, but we can also emit here
    socket.to(`trip:${rideId}`).emit('ride-accepted', { driverId, driverName });
  });
  
  socket.on('disconnect', () => {
    console.log('Client disconnected:', socket.id);
  });
});

server.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  await pool.end();
  if (redisClient) {
    await redisClient.quit();
  }
  server.close(() => {
    console.log('Process terminated');
  });
});
