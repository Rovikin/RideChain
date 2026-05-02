// RideChain contract verification script
// Usage: node scripts/verify.js
// Reads deployed-addresses.json and verifies all contracts on Polygonscan

const { run } = require("hardhat");
const fs      = require("fs");

async function main() {
    const path = "scripts/deployed-addresses.json";

    if (!fs.existsSync(path)) {
        console.error("deployed-addresses.json not found. Run deploy.js first.");
        process.exit(1);
    }

    const addresses = JSON.parse(fs.readFileSync(path, "utf8"));
    const deployer  = addresses.deployer;

    console.log("=".repeat(60));
    console.log("RideChain Contract Verification");
    console.log("=".repeat(60));

    const contracts = [
        {
            name:    "Registry",
            address: addresses.Registry,
            args:    [deployer],
        },
        {
            name:    "OrderBook",
            address: addresses.OrderBook,
            args:    [addresses.Registry, deployer],
        },
        {
            name:    "RideSession",
            address: addresses.RideSession,
            args:    [addresses.Registry, deployer],
        },
        {
            name:    "Dispute",
            address: addresses.Dispute,
            args:    [addresses.Registry, addresses.RideSession, deployer],
        },
        {
            name:    "ThresholdKYC",
            address: addresses.ThresholdKYC,
            args:    [addresses.Registry, deployer],
        },
    ];

    for (const contract of contracts) {
        console.log(`\nVerifying ${contract.name} at ${contract.address}...`);
        try {
            await run("verify:verify", {
                address:              contract.address,
                constructorArguments: contract.args,
            });
            console.log(`  ${contract.name} verified`);
        } catch (err) {
            if (err.message.includes("Already Verified")) {
                console.log(`  ${contract.name} already verified`);
            } else {
                console.error(`  ${contract.name} failed:`, err.message);
            }
        }
    }

    console.log("\n" + "=".repeat(60));
    console.log("Verification complete");
    console.log("=".repeat(60));
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
        console.error(err);
        process.exit(1);
    });
