// SPDX-License-Identifier: AGPL-3.0-or-later
// RideChain deployment script
// Usage: forge script scripts/deploy.js --rpc-url <RPC_URL> --broadcast

// Deploy order (dependency chain):
//
//  1. Registry        (no dependencies)
//  2. OrderBook       (depends on Registry)
//  3. RideSession     (depends on Registry)
//  4. Dispute         (depends on Registry + RideSession)
//  5. ThresholdKYC    (depends on Registry)
//
// Post-deploy wiring:
//  Registry.setRideSessionContract(RideSession)
//  Registry.setDisputeContract(Dispute)
//  OrderBook.setRideSessionContract(RideSession)
//  RideSession.setDisputeContract(Dispute)
//  RideSession.setOrderBookContract(OrderBook)
//  ThresholdKYC.setRideSessionContract(RideSession)

const { ethers } = require("hardhat");

async function main() {
    const [deployer] = await ethers.getSigners();

    console.log("=".repeat(60));
    console.log("RideChain Deployment");
    console.log("=".repeat(60));
    console.log("Deployer  :", deployer.address);
    console.log("Network   :", (await ethers.provider.getNetwork()).name);
    console.log("Balance   :", ethers.formatEther(
        await ethers.provider.getBalance(deployer.address)
    ), "MATIC");
    console.log("=".repeat(60));

    // -------------------------
    // 1. Registry
    // -------------------------
    console.log("\n[1/5] Deploying Registry...");
    const Registry = await ethers.getContractFactory("Registry");
    const registry = await Registry.deploy(deployer.address);
    await registry.waitForDeployment();
    console.log("      Registry:", await registry.getAddress());

    // -------------------------
    // 2. OrderBook
    // -------------------------
    console.log("\n[2/5] Deploying OrderBook...");
    const OrderBook = await ethers.getContractFactory("OrderBook");
    const orderBook = await OrderBook.deploy(
        await registry.getAddress(),
        deployer.address
    );
    await orderBook.waitForDeployment();
    console.log("      OrderBook:", await orderBook.getAddress());

    // -------------------------
    // 3. RideSession
    // -------------------------
    console.log("\n[3/5] Deploying RideSession...");
    const RideSession = await ethers.getContractFactory("RideSession");
    const rideSession = await RideSession.deploy(
        await registry.getAddress(),
        deployer.address
    );
    await rideSession.waitForDeployment();
    console.log("      RideSession:", await rideSession.getAddress());

    // -------------------------
    // 4. Dispute
    // -------------------------
    console.log("\n[4/5] Deploying Dispute...");
    const Dispute = await ethers.getContractFactory("Dispute");
    const dispute = await Dispute.deploy(
        await registry.getAddress(),
        await rideSession.getAddress(),
        deployer.address
    );
    await dispute.waitForDeployment();
    console.log("      Dispute:", await dispute.getAddress());

    // -------------------------
    // 5. ThresholdKYC
    // -------------------------
    console.log("\n[5/5] Deploying ThresholdKYC...");
    const ThresholdKYC = await ethers.getContractFactory("ThresholdKYC");
    const thresholdKYC = await ThresholdKYC.deploy(
        await registry.getAddress(),
        deployer.address
    );
    await thresholdKYC.waitForDeployment();
    console.log("      ThresholdKYC:", await thresholdKYC.getAddress());

    // -------------------------
    // Post-deploy wiring
    // -------------------------
    console.log("\n" + "=".repeat(60));
    console.log("Wiring contracts...");
    console.log("=".repeat(60));

    const rideSessionAddr = await rideSession.getAddress();
    const disputeAddr     = await dispute.getAddress();
    const orderBookAddr   = await orderBook.getAddress();
    const thresholdAddr   = await thresholdKYC.getAddress();

    console.log("\n[1/6] Registry.setRideSessionContract...");
    await (await registry.setRideSessionContract(rideSessionAddr)).wait();
    console.log("      done");

    console.log("\n[2/6] Registry.setDisputeContract...");
    await (await registry.setDisputeContract(disputeAddr)).wait();
    console.log("      done");

    console.log("\n[3/6] OrderBook.setRideSessionContract...");
    await (await orderBook.setRideSessionContract(rideSessionAddr)).wait();
    console.log("      done");

    console.log("\n[4/6] RideSession.setDisputeContract...");
    await (await rideSession.setDisputeContract(disputeAddr)).wait();
    console.log("      done");

    console.log("\n[5/6] RideSession.setOrderBookContract...");
    await (await rideSession.setOrderBookContract(orderBookAddr)).wait();
    console.log("      done");

    console.log("\n[6/6] ThresholdKYC.setRideSessionContract...");
    await (await thresholdKYC.setRideSessionContract(rideSessionAddr)).wait();
    console.log("      done");

    // -------------------------
    // Summary
    // -------------------------
    console.log("\n" + "=".repeat(60));
    console.log("Deployment complete");
    console.log("=".repeat(60));

    const addresses = {
        network:      (await ethers.provider.getNetwork()).name,
        deployer:     deployer.address,
        Registry:     await registry.getAddress(),
        OrderBook:    await orderBook.getAddress(),
        RideSession:  await rideSession.getAddress(),
        Dispute:      await dispute.getAddress(),
        ThresholdKYC: await thresholdKYC.getAddress(),
    };

    console.log("\nContract addresses:");
    Object.entries(addresses).forEach(([k, v]) => {
        console.log(`  ${k.padEnd(14)}: ${v}`);
    });

    // write addresses to file for verify script
    const fs = require("fs");
    const outPath = "scripts/deployed-addresses.json";
    fs.writeFileSync(outPath, JSON.stringify(addresses, null, 2));
    console.log(`\nAddresses saved to ${outPath}`);
    console.log("=".repeat(60));
}

main()
    .then(() => process.exit(0))
    .catch((err) => {
        console.error(err);
        process.exit(1);
    });
