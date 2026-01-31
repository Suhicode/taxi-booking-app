const fs = require('fs');
const path = require('path');

const CONFIG_PATH = path.join(__dirname, '../pricing.config.json');

function loadConfig() {
  return JSON.parse(fs.readFileSync(CONFIG_PATH, 'utf8'));
}

function isNightTime(date, nightCfg) {
  const hour = date.getHours();
  if (nightCfg.startHour > nightCfg.endHour) {
    return hour >= nightCfg.startHour || hour < nightCfg.endHour;
  }
  return hour >= nightCfg.startHour && hour < nightCfg.endHour;
}

function calculateFare(payload, now = new Date()) {
  const cfg = loadConfig();
  const v = cfg.vehicleTypes[payload.vehicleType] || cfg.vehicleTypes['Standard'];
  const baseFare = v.baseFare;
  const perKm = v.perKm;
  const perMin = v.perMin;
  const minFare = v.minFare;

  // Distance and duration
  const distance = Math.max(payload.distanceKm, 0);
  const duration = Math.max(payload.durationMin, 0);
  const waiting = Math.max((payload.waitingMin || 0) - (cfg.waiting.freeMins || 0), 0);
  const waitingCharge = waiting * (cfg.waiting.perMin || 0);

  // Night surcharge
  let nightMultiplier = 1.0;
  if (cfg.nightSurcharge.enabled && isNightTime(now, cfg.nightSurcharge)) {
    nightMultiplier = cfg.nightSurcharge.multiplier;
  }

  // Surge
  let surgeMultiplier = (payload.surgeMultiplier || cfg.surge.defaultMultiplier) || 1.0;
  surgeMultiplier = Math.min(surgeMultiplier, cfg.surge.maxMultiplier);

  // Fare calculation
  let fare = baseFare + (distance * perKm) + (duration * perMin) + waitingCharge;
  fare = Math.max(fare, minFare);
  fare = fare * nightMultiplier * surgeMultiplier;

  // Rounding
  fare = Math.round(fare);

  // Platform commission
  const commission = Math.round(fare * cfg.platformCommission);
  // Tax
  const tax = Math.round(fare * cfg.taxRate);
  // Driver payout
  const driverPayout = fare - commission - tax;

  return {
    vehicleType: payload.vehicleType,
    distanceKm: distance,
    durationMin: duration,
    waitingMin: waiting,
    surgeMultiplier,
    nightMultiplier,
    baseFare,
    perKm,
    perMin,
    waitingCharge,
    minFare,
    subtotal: fare,
    commission,
    tax,
    total: fare + tax,
    driverPayout,
    breakdown: {
      baseFare,
      distanceFare: distance * perKm,
      timeFare: duration * perMin,
      waitingCharge,
      nightMultiplier,
      surgeMultiplier,
      minFare,
      subtotal: fare,
      commission,
      tax,
      total: fare + tax,
      driverPayout
    }
  };
}

module.exports = { calculateFare, loadConfig };
