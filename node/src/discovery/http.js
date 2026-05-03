/**
 * HTTP API server for client queries.
 * Clients query this endpoint to discover nearby drivers
 * and request route calculations.
 */

import { createServer } from 'http';
import { _presenceStore } from './node.js';

export async function createHTTPServer(port, p2pNode, router) {
    const server = createServer(async (req, res) => {
        res.setHeader('Content-Type', 'application/json');
        res.setHeader('Access-Control-Allow-Origin', '*');

        try {
            const url = new URL(req.url, `http://localhost:${port}`);

            // GET /drivers?lat=X&lng=Y&radius=Z
            if (req.method === 'GET' && url.pathname === '/drivers') {
                const lat    = parseFloat(url.searchParams.get('lat'));
                const lng    = parseFloat(url.searchParams.get('lng'));
                const radius = parseFloat(url.searchParams.get('radius') || '5000');

                if (isNaN(lat) || isNaN(lng)) {
                    res.writeHead(400);
                    return res.end(JSON.stringify({ error: 'invalid coordinates' }));
                }

                const nearby = _getNearbyDrivers(lat, lng, radius);
                res.writeHead(200);
                return res.end(JSON.stringify({ drivers: nearby }));
            }

            // POST /route
            if (req.method === 'POST' && url.pathname === '/route') {
                const body = await _readBody(req);
                const { pickupLat, pickupLng, dropoffLat, dropoffLng } =
                    JSON.parse(body);

                const result = await router.route(
                    pickupLat, pickupLng,
                    dropoffLat, dropoffLng
                );

                res.writeHead(200);
                return res.end(JSON.stringify({ ok: true, ...result }));
            }

            // GET /health
            if (req.method === 'GET' && url.pathname === '/health') {
                res.writeHead(200);
                return res.end(JSON.stringify({
                    ok:       true,
                    peers:    p2pNode.getPeers().length,
                    drivers:  _presenceStore.size,
                    uptime:   process.uptime(),
                }));
            }

            res.writeHead(404);
            res.end(JSON.stringify({ error: 'not found' }));

        } catch (err) {
            res.writeHead(500);
            res.end(JSON.stringify({ error: err.message }));
        }
    });

    await new Promise(resolve => server.listen(port, resolve));
    console.log(`[http]     listening on port ${port}`);

    return server;
}

// -------------------------
// Internal helpers
// -------------------------

function _getNearbyDrivers(lat, lng, radiusMeters) {
    const results = [];
    const now     = Date.now();
    const stale   = 120_000; // 2 minutes

    for (const [address, data] of _presenceStore.entries()) {
        if (!data.available)           continue;
        if (now - data.updatedAt > stale) continue;

        const distance = _haversine(lat, lng, data.lat, data.lng);
        if (distance > radiusMeters)   continue;

        results.push({
            address:        address,
            farePerKm:      data.farePerKm,
            distanceMeters: Math.round(distance),
            reputationScore: data.reputationScore || 500,
            lat:            data.lat,
            lng:            data.lng,
        });
    }

    // sort by distance ascending
    return results.sort((a, b) => a.distanceMeters - b.distanceMeters);
}

function _haversine(lat1, lng1, lat2, lng2) {
    const toRad = deg => deg * Math.PI / 180;
    const R     = 6_371_000;

    const dLat = toRad(lat2 - lat1);
    const dLng = toRad(lng2 - lng1);

    const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos(toRad(lat1)) *
        Math.cos(toRad(lat2)) *
        Math.sin(dLng / 2) ** 2;

    return R * 2 * Math.asin(Math.sqrt(a));
}

async function _readBody(req) {
    return new Promise((resolve, reject) => {
        const chunks = [];
        req.on('data', chunk => chunks.push(chunk));
        req.on('end',  ()    => resolve(Buffer.concat(chunks).toString()));
        req.on('error', reject);
    });
}
