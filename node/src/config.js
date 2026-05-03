import 'dotenv/config';

export function loadConfig() {
    const required = [
        'NODE_PRIVATE_KEY',
        'RPC_URL',
        'REGISTRY_CONTRACT',
        'ORDER_BOOK_CONTRACT',
        'FEE_WALLET',
    ];

    for (const key of required) {
        if (!process.env[key]) {
            throw new Error(`Missing required env var: ${key}`);
        }
    }

    return {
        // node identity
        privateKey:  process.env.NODE_PRIVATE_KEY,
        ensDomain:   process.env.NODE_ENS_DOMAIN || 'node.ridechain.eth',

        // network
        p2pPort:      parseInt(process.env.P2P_PORT     || '4001'),
        httpPort:     parseInt(process.env.HTTP_PORT    || '8080'),
        announceAddr: process.env.ANNOUNCE_ADDR         || null,

        // blockchain
        rpcUrl:              process.env.RPC_URL,
        registryContract:    process.env.REGISTRY_CONTRACT,
        orderBookContract:   process.env.ORDER_BOOK_CONTRACT,

        // osrm
        osrmUrl: process.env.OSRM_URL || 'http://localhost:5000',

        // incentive
        feeWallet: process.env.FEE_WALLET,
    };
}
