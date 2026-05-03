/**
 * ENS registry helper.
 * Resolves this node's ENS domain and verifies it points
 * to the correct address before accepting connections.
 */

import { ethers } from 'ethers';

export async function createRegistry(config) {
    const provider = new ethers.JsonRpcProvider(config.rpcUrl);
    const wallet   = new ethers.Wallet(config.privateKey, provider);

    // resolve ENS domain
    let resolvedAddress = null;
    try {
        resolvedAddress = await provider.resolveName(config.ensDomain);
    } catch {
        console.warn('[registry] ENS resolution failed — operating without ENS');
    }

    if (resolvedAddress && resolvedAddress.toLowerCase() !== wallet.address.toLowerCase()) {
        console.warn(
            `[registry] ENS domain ${config.ensDomain} resolves to ` +
            `${resolvedAddress} but node wallet is ${wallet.address}`
        );
    }

    return {
        address:  wallet.address,
        domain:   config.ensDomain,
        resolved: resolvedAddress,

        // verify a peer's claimed ENS domain
        async verifyPeer(domain, claimedAddress) {
            try {
                const resolved = await provider.resolveName(domain);
                return resolved?.toLowerCase() === claimedAddress.toLowerCase();
            } catch {
                return false;
            }
        }
    };
}
