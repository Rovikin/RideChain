/**
 * OSRM routing client.
 * Queries local OSRM instance and returns route data.
 * Falls back to straight-line distance if OSRM unavailable.
 */

const EARTH_RADIUS_METERS = 6_371_000;

export async function createRouter(config) {
    const osrmUrl = config.osrmUrl;

    // verify OSRM is reachable
    try {
        const res = await fetch(`${osrmUrl}/health`);
        if (!res.ok) throw new Error('OSRM health check failed');
    } catch (err) {
        console.warn('[router] OSRM not reachable — fallback mode active');
    }

    return {
        /**
         * Calculate route between two GPS coordinates.
         * @param {number} pickupLat  - pickup latitude
         * @param {number} pickupLng  - pickup longitude
         * @param {number} dropoffLat - dropoff latitude
         * @param {number} dropoffLng - dropoff longitude
         * @returns {{ distanceMeters: number, durationSeconds: number, source: string }}
         */
        async route(pickupLat, pickupLng, dropoffLat, dropoffLng) {
            try {
                return await _osrmRoute(
                    osrmUrl,
                    pickupLat, pickupLng,
                    dropoffLat, dropoffLng
                );
            } catch {
                // fallback: straight-line × 1.3 correction factor
                const distance = _haversine(
                    pickupLat, pickupLng,
                    dropoffLat, dropoffLng
                );
                return {
                    distanceMeters:  Math.round(distance * 1.3),
                    durationSeconds: Math.round((distance * 1.3) / 8), // ~8 m/s average
                    source:          'fallback'
                };
            }
        }
    };
}

// -------------------------
// Internal: OSRM query
// -------------------------

async function _osrmRoute(osrmUrl, pickupLat, pickupLng, dropoffLat, dropoffLng) {
    const url = `${osrmUrl}/route/v1/driving/` +
        `${pickupLng},${pickupLat};${dropoffLng},${dropoffLat}` +
        `?overview=false`;

    const res  = await fetch(url);
    const data = await res.json();

    if (data.code !== 'Ok') {
        throw new Error(`OSRM error: ${data.code}`);
    }

    const route = data.routes[0];
    return {
        distanceMeters:  Math.round(route.distance),
        durationSeconds: Math.round(route.duration),
        source:          'osrm'
    };
}

// -------------------------
// Internal: Haversine formula
// -------------------------

function _haversine(lat1, lng1, lat2, lng2) {
    const toRad = deg => deg * Math.PI / 180;

    const dLat = toRad(lat2 - lat1);
    const dLng = toRad(lng2 - lng1);

    const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(lat1)) *
        Math.cos(toRad(lat2)) *
        Math.sin(dLng / 2) ** 2;

    return EARTH_RADIUS_METERS * 2 * Math.asin(Math.sqrt(a));
}
