/**
 * libp2p super node.
 * Serves as relay and rendezvous point for driver-passenger P2P connections.
 * Handles CGNAT traversal via circuit relay.
 */

import { createLibp2p }         from 'libp2p';
import { tcp }                  from '@libp2p/tcp';
import { noise }                from '@libp2p/noise';
import { identify }             from '@libp2p/identify';
import { kadDHT }               from '@libp2p/kad-dht';
import { circuitRelayServer }   from '@libp2p/circuit-relay-v2';
import { createHTTPServer }     from './http.js';

// protocol identifiers
export const PROTOCOL_ROUTE    = '/ridechain/route/1.0.0';
export const PROTOCOL_PRESENCE = '/ridechain/presence/1.0.0';
export const PROTOCOL_ORDER    = '/ridechain/order/1.0.0';

export async function createNode(config, router, incentive) {
    const listenAddrs = [
        `/ip4/0.0.0.0/tcp/${config.p2pPort}`,
    ];

    const announceAddrs = config.announceAddr
        ? [config.announceAddr]
        : [];

    const node = await createLibp2p({
        addresses: {
            listen:   listenAddrs,
            announce: announceAddrs,
        },
        transports: [tcp()],
        connectionEncrypters: [noise()],
        services: {
            identify:      identify(),
            dht:           kadDHT({ clientMode: false }),
            relay:         circuitRelayServer({
                // allow all peers to use this node as relay
                reservations: { maxReservations: 1024 }
            }),
        },
    });

    // register protocol handlers
    await node.handle(PROTOCOL_ROUTE,    _routeHandler(router, incentive));
    await node.handle(PROTOCOL_PRESENCE, _presenceHandler());
    await node.handle(PROTOCOL_ORDER,    _orderHandler());

    // start HTTP API for client queries
    await createHTTPServer(config.httpPort, node, router);

    await node.start();
    return node;
}

// -------------------------
// Protocol handlers
// -------------------------

function _routeHandler(router, incentive) {
    return async ({ stream }) => {
        const chunks = [];
        for await (const chunk of stream.source) {
            chunks.push(chunk.subarray());
        }

        try {
            const req = JSON.parse(Buffer.concat(chunks).toString());
            const result = await router.route(
                req.pickupLat,
                req.pickupLng,
                req.dropoffLat,
                req.dropoffLng
            );

            // track query for incentive reporting
            incentive.recordQuery(req.orderId || null);

            const response = JSON.stringify({ ok: true, ...result });
            await stream.sink([Buffer.from(response)]);
        } catch (err) {
            const response = JSON.stringify({ ok: false, error: err.message });
            await stream.sink([Buffer.from(response)]);
        }
    };
}

function _presenceHandler() {
    return async ({ stream, connection }) => {
        const chunks = [];
        for await (const chunk of stream.source) {
            chunks.push(chunk.subarray());
        }

        try {
            const presence = JSON.parse(Buffer.concat(chunks).toString());
            // presence data: { driverAddress, lat, lng, farePerKm, available }
            // stored in memory — used to serve discovery queries
            _presenceStore.set(presence.driverAddress, {
                ...presence,
                peerId:    connection.remotePeer.toString(),
                updatedAt: Date.now(),
            });

            await stream.sink([Buffer.from(JSON.stringify({ ok: true }))]);
        } catch (err) {
            await stream.sink([Buffer.from(JSON.stringify({
                ok: false, error: err.message
            }))]);
        }
    };
}

function _orderHandler() {
    return async ({ stream }) => {
        // order matching happens via HTTP API
        // this handler acknowledges P2P order broadcasts
        await stream.sink([Buffer.from(JSON.stringify({ ok: true }))]);
    };
}

// -------------------------
// In-memory presence store
// -------------------------

export const _presenceStore = new Map();

// clean up stale entries every 60 seconds
setInterval(() => {
    const staleThreshold = Date.now() - 120_000; // 2 minutes
    for (const [addr, data] of _presenceStore.entries()) {
        if (data.updatedAt < staleThreshold) {
            _presenceStore.delete(addr);
        }
    }
}, 60_000);
