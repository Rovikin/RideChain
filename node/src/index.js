import { createNode }       from './discovery/node.js';
import { createRouter }     from './routing/router.js';
import { createRegistry }   from './registry/registry.js';
import { createIncentive }  from './incentive/incentive.js';
import { loadConfig }       from './config.js';

async function main() {
    const config = loadConfig();

    console.log('='.repeat(60));
    console.log('RideChain Super Node v0.1.0');
    console.log('='.repeat(60));
    console.log('ENS domain :', config.ensDomain);
    console.log('P2P port   :', config.p2pPort);
    console.log('HTTP port  :', config.httpPort);
    console.log('='.repeat(60));

    // start OSRM routing layer
    const router = await createRouter(config);
    console.log('[router]   OSRM connection verified');

    // start incentive tracker (monitors fee events on-chain)
    const incentive = await createIncentive(config);
    console.log('[incentive] listening for routing fee events');

    // register node on-chain via ENS
    const nodeRegistry = await createRegistry(config);
    console.log('[registry] ENS domain resolved');

    // start libp2p node
    const p2pNode = await createNode(config, router, incentive);
    console.log('[p2p]      listening on:');
    p2pNode.getMultiaddrs().forEach(addr => {
        console.log('           ', addr.toString());
    });

    console.log('\nRideChain node is running.');

    // graceful shutdown
    process.on('SIGTERM', async () => {
        console.log('\nShutting down...');
        await p2pNode.stop();
        process.exit(0);
    });

    process.on('SIGINT', async () => {
        console.log('\nShutting down...');
        await p2pNode.stop();
        process.exit(0);
    });
}

main().catch(err => {
    console.error('Fatal error:', err);
    process.exit(1);
});
