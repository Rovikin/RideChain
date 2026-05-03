/**
 * Incentive tracker.
 * Monitors on-chain RoutingFeeDistributed events to verify
 * that this node is receiving routing fees correctly.
 */

import { ethers } from 'ethers';

const ORDER_BOOK_ABI = [
    'event RoutingFeeDistributed(bytes32 indexed orderId, address routingNode, uint256 amount)',
];

export async function createIncentive(config) {
    const provider = new ethers.JsonRpcProvider(config.rpcUrl);
    const contract = new ethers.Contract(
        config.orderBookContract,
        ORDER_BOOK_ABI,
        provider
    );

    let totalFeesEarned = BigInt(0);
    let totalQueries    = 0;

    // listen for fee events directed to this node
    contract.on('RoutingFeeDistributed', (orderId, routingNode, amount) => {
        if (routingNode.toLowerCase() === config.feeWallet.toLowerCase()) {
            totalFeesEarned += amount;
            console.log(
                `[incentive] fee received: ${ethers.formatEther(amount)} MATIC` +
                ` | order: ${orderId.slice(0, 10)}...`
            );
        }
    });

    return {
        // record a routing query (called by router handler)
        recordQuery(orderId) {
            totalQueries++;
        },

        // get current stats
        getStats() {
            return {
                totalFeesEarned: ethers.formatEther(totalFeesEarned),
                totalQueries,
            };
        }
    };
}
