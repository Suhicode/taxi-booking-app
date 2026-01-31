const express = require('express');
const { calculateFare } = require('./pricing/priceCalculator');

const router = express.Router();

// POST /api/v1/calculate-fare
router.post('/calculate-fare', (req, res) => {
  try {
    const result = calculateFare(req.body);
    res.json(result);
  } catch (err) {
    res.status(400).json({ error: err.message });
  }
});

module.exports = router;
