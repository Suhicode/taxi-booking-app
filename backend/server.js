const express = require('express');
const cors = require('cors');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = 3000;

// Middleware
app.use(cors());
app.use(express.json());

// In-memory storage (replace with database in production)
const rides = new Map();
const drivers = new Map();

// Mock drivers data
const mockDrivers = [
  {
    id: 'driver_1',
    name: 'John Driver',
    phone: '+1234567890',
    vehicleNumber: 'ABC-1234',
    vehicleModel: 'Toyota Camry',
    rating: 4.8,
    location: { lat: 12.9716, lng: 77.5946 }, // Bangalore
    isAvailable: true,
  },
  {
    id: 'driver_2',
    name: 'Sarah Driver',
    phone: '+0987654321',
    vehicleNumber: 'XYZ-5678',
    vehicleModel: 'Honda Accord',
    rating: 4.9,
    location: { lat: 12.9616, lng: 77.5846 },
    isAvailable: true,
  },
  {
    id: 'driver_3',
    name: 'Mike Driver',
    phone: '+1122334455',
    vehicleNumber: 'DEF-9012',
    vehicleModel: 'Nissan Altima',
    rating: 4.7,
    location: { lat: 12.9816, lng: 77.6046 },
    isAvailable: true,
  },
];

// Initialize drivers
mockDrivers.forEach(driver => {
  drivers.set(driver.id, driver);
});

// Routes

// POST /api/ride/request - Book a ride
app.post('/api/ride/request', (req, res) => {
  try {
    const {
      pickupLat,
      pickupLng,
      pickupAddress,
      dropLat,
      dropLng,
      dropAddress,
      userId,
      vehicleType,
      estimatedFare
    } = req.body;

    // Validate required fields
    if (!pickupLat || !pickupLng || !dropLat || !dropLng || !userId) {
      return res.status(400).json({
        error: 'Missing required fields',
        required: ['pickupLat', 'pickupLng', 'dropLat', 'dropLng', 'userId']
      });
    }

    // Create ride request
    const rideId = uuidv4();
    const ride = {
      id: rideId,
      status: 'searching',
      userId,
      pickup: {
        lat: parseFloat(pickupLat),
        lng: parseFloat(pickupLng),
        address: pickupAddress || 'Pickup Location'
      },
      drop: {
        lat: parseFloat(dropLat),
        lng: parseFloat(dropLng),
        address: dropAddress || 'Drop Location'
      },
      vehicleType: vehicleType || 'standard',
      estimatedFare: parseFloat(estimatedFare) || 0,
      createdAt: new Date().toISOString(),
      driverId: null,
      acceptedAt: null,
      startedAt: null,
      completedAt: null,
      cancelledAt: null
    };

    rides.set(rideId, ride);

    // Simulate driver assignment after 3-8 seconds
    setTimeout(() => {
      assignDriverToRide(rideId);
    }, Math.random() * 5000 + 3000);

    res.status(201).json({
      rideId,
      status: 'searching',
      message: 'Ride request created successfully'
    });

  } catch (error) {
    console.error('Ride request error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to create ride request'
    });
  }
});

// GET /api/ride/status/:rideId - Check ride status
app.get('/api/ride/status/:rideId', (req, res) => {
  try {
    const { rideId } = req.params;
    const ride = rides.get(rideId);

    if (!ride) {
      return res.status(404).json({
        error: 'Ride not found',
        rideId
      });
    }

    const response = {
      rideId: ride.id,
      status: ride.status,
      message: getStatusMessage(ride.status)
    };

    // Add driver info if ride is accepted
    if (ride.driverId && drivers.has(ride.driverId)) {
      response.driver = drivers.get(ride.driverId);
    }

    res.json(response);

  } catch (error) {
    console.error('Status check error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to check ride status'
    });
  }
});

// POST /api/ride/cancel/:rideId - Cancel a ride
app.post('/api/ride/cancel/:rideId', (req, res) => {
  try {
    const { rideId } = req.params;
    const ride = rides.get(rideId);

    if (!ride) {
      return res.status(404).json({
        error: 'Ride not found',
        rideId
      });
    }

    if (ride.status === 'completed') {
      return res.status(400).json({
        error: 'Cannot cancel completed ride',
        rideId
      });
    }

    // Update ride status
    ride.status = 'cancelled';
    ride.cancelledAt = new Date().toISOString();

    // Make driver available again if assigned
    if (ride.driverId && drivers.has(ride.driverId)) {
      const driver = drivers.get(ride.driverId);
      driver.isAvailable = true;
    }

    res.json({
      rideId,
      status: 'cancelled',
      message: 'Ride cancelled successfully'
    });

  } catch (error) {
    console.error('Ride cancellation error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to cancel ride'
    });
  }
});

// GET /api/drivers/available - Get available drivers
app.get('/api/drivers/available', (req, res) => {
  try {
    const availableDrivers = Array.from(drivers.values())
      .filter(driver => driver.isAvailable);

    res.json({
      drivers: availableDrivers,
      count: availableDrivers.length
    });

  } catch (error) {
    console.error('Get drivers error:', error);
    res.status(500).json({
      error: 'Internal server error',
      message: 'Failed to get available drivers'
    });
  }
});

// Helper functions
function assignDriverToRide(rideId) {
  const ride = rides.get(rideId);
  if (!ride || ride.status !== 'searching') {
    return;
  }

  // Find nearest available driver
  const availableDrivers = Array.from(drivers.values())
    .filter(driver => driver.isAvailable);

  if (availableDrivers.length === 0) {
    // No drivers available, keep searching
    setTimeout(() => {
      assignDriverToRide(rideId);
    }, 5000);
    return;
  }

  // Simple distance calculation (in production, use proper distance formula)
  const pickupLat = ride.pickup.lat;
  const pickupLng = ride.pickup.lng;

  let nearestDriver = availableDrivers[0];
  let minDistance = Math.abs(
    Math.sqrt(
      Math.pow(nearestDriver.location.lat - pickupLat, 2) +
      Math.pow(nearestDriver.location.lng - pickupLng, 2)
    )
  );

  availableDrivers.forEach(driver => {
    const distance = Math.abs(
      Math.sqrt(
        Math.pow(driver.location.lat - pickupLat, 2) +
        Math.pow(driver.location.lng - pickupLng, 2)
      )
    );
    if (distance < minDistance) {
      minDistance = distance;
      nearestDriver = driver;
    }
  });

  // Assign driver to ride
  ride.driverId = nearestDriver.id;
  ride.status = 'accepted';
  ride.acceptedAt = new Date().toISOString();
  
  // Mark driver as unavailable
  nearestDriver.isAvailable = false;

  console.log(`Driver ${nearestDriver.name} assigned to ride ${rideId}`);
}

function getStatusMessage(status) {
  switch (status) {
    case 'searching':
      return 'Searching for nearby drivers...';
    case 'pending':
      return 'Waiting for driver acceptance...';
    case 'accepted':
      return 'Driver has accepted your ride';
    case 'started':
      return 'Your ride has started';
    case 'completed':
      return 'Ride completed successfully';
    case 'cancelled':
      return 'Ride has been cancelled';
    default:
      return 'Unknown status';
  }
}

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    rides: rides.size,
    drivers: drivers.size
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Taxi booking server running on http://localhost:${PORT}`);
  console.log(`📍 Available drivers: ${mockDrivers.length}`);
  console.log(`📊 Health check: http://localhost:${PORT}/api/health`);
});

module.exports = app;
