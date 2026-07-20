const fetch = require('node-fetch');
const env = require('../config/env');

/**
 * Geocodes a free-text address into { lat, lng } using the Google Maps
 * Geocoding API. Returns null (rather than throwing) if the API key isn't
 * configured, so callers can fall back to manual lat/lng entry.
 */
async function geocodeAddress(address) {
  if (!env.googleMapsApiKey) return null;
  const url = `https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(address)}&key=${env.googleMapsApiKey}`;
  const res = await fetch(url);
  const json = await res.json();
  const loc = json?.results?.[0]?.geometry?.location;
  return loc ? { lat: loc.lat, lng: loc.lng } : null;
}

/**
 * Straight-line distance in km between two coordinates (Haversine formula).
 * Used as a free fallback when the Distance Matrix API isn't configured.
 */
function distanceKm(a, b) {
  const R = 6371;
  const dLat = ((b.lat - a.lat) * Math.PI) / 180;
  const dLng = ((b.lng - a.lng) * Math.PI) / 180;
  const lat1 = (a.lat * Math.PI) / 180;
  const lat2 = (b.lat * Math.PI) / 180;
  const h =
    Math.sin(dLat / 2) ** 2 + Math.sin(dLng / 2) ** 2 * Math.cos(lat1) * Math.cos(lat2);
  return R * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
}

module.exports = { geocodeAddress, distanceKm, isConfigured: () => Boolean(env.googleMapsApiKey) };
