// RideChain upgrade helper script
// Usage: node scripts/upgrade.js
//
// This script assists with the 48-hour timelock upgrade process.
// Actual upgrade logic depends on proxy pattern implementation (future work).
//
// Current phase: deployer key (Phase 1)
// Future phase:  Gnosis Safe multisig (Phase 2)

const fs   = require("fs");
const path = "scripts/deployed-addresses.json";

async function main() {
    if (!fs.existsSync(path)) {
        console.error("deployed-addresses.json not found. Run deploy.js first.");
        process.exit(1);
    }

    const addresses = JSON.parse(fs.readFileSync(path, "utf8"));

    console.log("=".repeat(60));
    console.log("RideChain Upgrade Helper");
    console.log("=".repeat(60));
    console.log("\nCurrent deployed addresses:");
    Object.entries(addresses).forEach(([k, v]) => {
        console.log(`  ${k.padEnd(14)}: ${v}`);
    });

    console.log("\nUpgrade process (Phase 1 — deployer key):");
    console.log("  1. Deploy new implementation contract");
    console.log("  2. Call admin upgrade function on proxy");
    console.log("  3. Verify new implementation on Polygonscan");
    console.log("  4. Update deployed-addresses.json");
    console.log("\nNote: 48-hour timelock enforced by TimelockController.");
    console.log("Users may withdraw funds before upgrade takes effect.");
    console.log("\nPhase 2 (multisig) upgrade process:");
    console.log("  1. Create proposal on Gnosis Safe");
    console.log("  2. Collect M-of-N signatures from contributors");
    console.log("  3. Execute proposal after timelock");
    console.log("=".repeat(60));
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
        console.error(err);
        process.exit(1);
    });
