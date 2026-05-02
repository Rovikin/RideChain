# RideChain: A Decentralized Peer-to-Peer Ride-Hailing Protocol

**Version 0.1 — Concept Paper**
**Author: RideChain Initiative**

---

## Abstract

RideChain is a decentralized, peer-to-peer ride-hailing protocol built on the Polygon PoS blockchain. It addresses the fundamental asymmetry of power between ride-hailing platform operators and their driver partners — a structural problem in which a centralized third party unilaterally dictates pricing, enforces opaque policies, and extracts disproportionate value from both drivers and passengers without meaningful accountability.

RideChain eliminates the intermediary entirely. Drivers operate as independent merchants, setting their own fares and building reputation that belongs to them — not to any platform. Passengers choose from a transparent marketplace of available drivers, sorted by fare, proximity, and on-chain reputation. Payments are held in smart contract escrow and released automatically upon trip completion. Disputes are resolved by a community of arbiters with cryptographic accountability. Identity is protected by threshold encryption, accessible only through collective community consensus.

The protocol is designed to be censorship-resistant, transparent, and owned by no single entity. It is built for the Indonesian market — where ride-hailing is essential infrastructure and driver exploitation is a documented, ongoing harm — but its architecture is applicable anywhere the same conditions exist.

---

## 1. Introduction

### 1.1 The Problem

Ride-hailing platforms in Indonesia have grown into critical urban infrastructure. Millions of drivers depend on them for their primary income. Yet the relationship between platform and driver is structurally exploitative:

- **Unilateral rule-making.** Platform operators change commission rates, incentive structures, and suspension policies without driver input or consent.
- **Extractive commission.** Platform fees routinely exceed 20–25% of fare value — a rate higher than most state taxes — with no corresponding increase in service to drivers.
- **Platform-owned reputation.** A driver's rating, trip history, and earned trust are assets owned by the platform. A suspended or deplatformed driver loses everything built over years of service.
- **Regulatory capture.** Regulators in Indonesia have historically prioritized tax revenue from platform operators over the welfare of driver partners, who are also citizens and constituents.

These are not operational complaints. They are structural failures that emerge inevitably when a centralized intermediary controls both the rules and the infrastructure of a marketplace.

### 1.2 The Opportunity

Decentralized financial infrastructure — smart contracts, on-chain escrow, cryptographic identity, and peer-to-peer networking — has existed and matured for over a decade. The tools required to build a ride-hailing system without a central operator already exist. RideChain applies them to this specific, unsolved problem.

### 1.3 Design Philosophy

RideChain is built on three principles:

**Sovereignty.** Drivers own their reputation, their pricing, and their relationship with passengers. No entity can deplatform a driver, alter their history, or confiscate their earnings.

**Transparency.** Every rule encoded in the protocol is visible, auditable, and consistent. No algorithm operates in secret. No fee is hidden.

**Proportional accountability.** Every participant — driver, passenger, arbiter — has economic skin in the game. The cost of dishonesty always exceeds its potential benefit.

---

## 2. System Overview

RideChain consists of five interconnected layers:

```
┌─────────────────────────────────────────────────────┐
│                   Application Layer                  │
│         Android APK  ·  P2P Messaging (XMTP)        │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                  Discovery Layer                     │
│      libp2p  ·  DHT  ·  Super Nodes  ·  GPS        │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                  Routing Layer                       │
│         OSRM  ·  OpenStreetMap  ·  ENS Nodes       │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│               Smart Contract Layer                   │
│   Registry · OrderBook · RideSession · Dispute      │
│              ThresholdKYC · Governance               │
└──────────────────────┬──────────────────────────────┘
                       │
┌──────────────────────▼──────────────────────────────┐
│                 Blockchain Layer                     │
│              Polygon PoS  ·  MATIC                  │
└─────────────────────────────────────────────────────┘
```

---

## 3. Core Components

### 3.1 Driver as P2P Merchant

The conceptual foundation of RideChain is the reframing of the driver as an independent merchant rather than a platform-dependent contractor.

In conventional P2P marketplaces — such as peer-to-peer cryptocurrency exchanges — merchants set their own prices, build their own reputation, and compete for customers on merit. No central operator dictates their terms. The platform provides only escrow infrastructure and a discovery mechanism.

RideChain applies this model to transportation:

- Drivers set their own per-kilometer fare
- Drivers build reputation that is stored on-chain and owned by their wallet address
- Passengers browse available drivers and select based on fare, proximity, and reputation
- The protocol provides escrow, dispute resolution, and identity infrastructure — nothing more

This framing resolves the core power asymmetry. A driver cannot be deplatformed because there is no platform to be deplatformed from. Their reputation cannot be confiscated because it exists on a public blockchain, not in a corporate database.

### 3.2 Matching Engine

#### 3.2.1 Driver Discovery via DHT and libp2p

Driver discovery in RideChain uses a hybrid architecture designed for the realities of mobile networks in Indonesia, where most users operate behind CGNAT and connections are intermittent.

**Super Nodes** form the backbone of the discovery layer. These are the same nodes that provide routing infrastructure (see Section 3.3), repurposed as relay and rendezvous points. They hold stable IP addresses, are incentivized to remain online, and serve as the anchor points for P2P connectivity.

**libp2p** handles transport between all nodes. It provides built-in NAT traversal, CGNAT hole-punching, and circuit relay — meaning two mobile devices that cannot connect directly can communicate via a super node relay without any centralized server.

**Driver presence** is maintained through periodic announcements to the nearest super node every 30 seconds while the application is in the foreground. The Android foreground service pattern — already familiar to Indonesian ride-hailing drivers from existing platforms — keeps the process alive and prevents OS battery optimization from terminating it.

#### 3.2.2 Order Matching Logic

When a passenger inputs a pickup point and destination:

1. The application queries nearby super nodes for available drivers within a configurable radius
2. Each driver entry includes: fare rate (per km), current distance from pickup, reputation score, estimated time of arrival
3. The passenger selects a driver from the list
4. The smart contract locks escrow and the session begins

Sorting is configurable by the passenger: nearest first, cheapest first, highest reputation first, or a composite score. The sorting algorithm is open source and identical for all users — no hidden prioritization.

**Natural price discovery** emerges from this model without any algorithmic surge pricing. During peak hours, drivers with higher fares are still chosen if supply is scarce. During quiet hours, competitive pressure drives fares down. The market sets prices transparently.

### 3.3 Routing Infrastructure

#### 3.3.1 OpenStreetMap as Data Foundation

RideChain uses OpenStreetMap (OSM) as its mapping data source. OSM data is contributed by a global community, licensed under the Open Database License, and cannot be revoked or restricted by any single entity. In major Indonesian cities, OSM coverage and accuracy is sufficient for routing purposes.

#### 3.3.2 OSRM Nodes with ENS Registration

Routing computation is performed by OSRM (Open Source Routing Machine) nodes operated by community members. Each node registers a subdomain under the project's ENS namespace (e.g., `node1.ridechain.eth`), resolving to their server address.

ENS operates on Ethereum mainnet and provides censorship-resistant domain resolution — no registrar can suspend or confiscate an ENS domain under external pressure.

Node operators sync OSM data weekly from the OpenStreetMap planet file. Because all nodes use the same data source, routing results are naturally consistent without requiring inter-node coordination.

#### 3.3.3 Node Incentives

Routing nodes are compensated from a small fee split equally between driver and passenger on each completed trip:

```
Routing fee per transaction: 0.5% of fare
  Split: 0.25% from passenger + 0.25% from driver

Fee model: per-query with per-transaction cap
  Each routing query: ~Rp10
  Cap per transaction: Rp100 total

Break-even: ~50 transactions/day
  (sufficient for VPS costs of Rp100,000–150,000/month)
```

Routing fees are paid at order creation, not at trip completion — the node has provided its service regardless of trip outcome.

Nodes with outlier results (inconsistent with majority of queried nodes) are not compensated. Persistent outlier behavior triggers removal from the registry.

### 3.4 Order Book and Pricing Mechanism

Drivers publish their availability as persistent asks in the order book:

```
Driver Ask:
  wallet_address: 0x...
  fare_per_km: X MATIC (displayed as IDR equivalent)
  max_order_value: determined by deposit
  location: updated every 30 seconds via super node
  reputation_score: pulled from Registry Contract
  status: available | busy | offline
```

Passengers do not bid. They browse and select. This is a single-sided marketplace, not a two-sided auction.

Fare calculation at order creation:

```
estimated_distance = OSRM query (majority result of 3–5 nodes)
estimated_fare = driver.fare_per_km × estimated_distance
escrow_amount = estimated_fare + routing_fee + gas_buffer
```

The estimated fare is locked at order creation. If the actual distance deviates significantly from the estimate (configurable threshold), the difference is settled at trip completion using the GPS-verified actual route.

### 3.5 Escrow and Payment Flow

```
ORDER CREATED
  Passenger deposits escrow to RideSession Contract
  Escrow = estimated_fare + routing_fee + gas_buffer
  Routing fee distributed immediately to routing node
  
TRIP IN PROGRESS
  GPS checkpoints accumulated locally as Merkle tree
  Only Merkle root submitted on-chain periodically
  
TRIP COMPLETED
  Driver submits completion claim
  10-minute confirmation window opens
  
CONFIRMED (passenger confirms OR timeout expires)
  Fare released to driver
  Gas buffer remainder returned to passenger
  
DISPUTED
  Escrow frozen
  Dispute Contract engaged
  Merkle proof available as forensic evidence
```

### 3.6 Deposit and Slash Mechanism

All participants must maintain collateral deposits that exceed the value of any transaction they participate in. This ensures that the economic cost of dishonesty always exceeds its potential gain.

#### 3.6.1 Deposit Requirements

```
Driver deposit:    2× maximum order value they wish to accept
Passenger deposit: 2× value of current order (per trip)
Arbiter deposit:   2× the arbitration fee they will earn
```

The 2× multiplier (rather than 1.5×) provides a buffer against MATIC price volatility. A 25% price decline reduces effective collateral to 1.5× — still sufficient for system integrity.

#### 3.6.2 Dynamic Deposit Monitoring

A Chainlink price oracle monitors MATIC/IDR value continuously:

```
Deposit value > 1.5× order value  →  eligible to operate
Deposit value 1.2×–1.5×           →  warning notification
Deposit value < 1.2×               →  operations suspended
                                       until top-up
```

Users see all values in IDR equivalent. MATIC denomination is abstracted away.

#### 3.6.3 Slash Rules

```
Driver fraud confirmed    →  slash driver deposit by fare value
                              → to passenger + arbiter fee
Passenger fraud confirmed →  slash passenger deposit by fare value
                              → to driver + arbiter fee
Arbiter non-responsive    →  slash arbiter deposit (small)
                              → split between driver and passenger
                              → case reassigned to new arbiter
```

### 3.7 Dispute Resolution

#### 3.7.1 Optimistic Default

The system assumes honest behavior by default. After a driver submits a completion claim, funds are released automatically after a timeout if the passenger does not dispute. This minimizes unnecessary on-chain activity for the majority of trips that complete without issue.

#### 3.7.2 Dispute Flow

```
1. Passenger disputes within confirmation window
   → Passenger deposits arbiter fee upfront
   → Escrow frozen in RideSession Contract

2. Dispute Contract selects arbiter randomly from active pool
   → Arbiter notified with case details and time limit

3. Three-party chat room opened via XMTP protocol
   → Driver, passenger, and arbiter participate
   → GPS Merkle proof available for arbiter review
   → Proximity confirmation logs available

4. Arbiter renders decision: driver correct OR passenger correct
   → No split decisions. One party is found at fault.
   → Contract executes immediately upon decision submission

5. Losing party's deposit slashed
   → Winning party compensated
   → Arbiter receives fee from slashed deposit
   → Winning party rates the arbiter (1–5 stars)
```

#### 3.7.3 Cancellation Rules

```
Passenger cancels at CREATED state          →  full refund
Passenger cancels at ACCEPTED (pre-movement) →  full refund
Passenger cancels at PICKING_UP             →  20% penalty to driver
Passenger cancels at IN_PROGRESS            →  proportional by GPS distance
Driver cancels at ACCEPTED or PICKING_UP    →  full refund to passenger
                                               + small slash from driver deposit
```

### 3.8 Arbiter System and Reputation

Any active driver or passenger with sufficient on-chain history may register as an arbiter by depositing collateral.

#### 3.8.1 Arbiter Reputation

All arbiter activity is recorded on-chain:

```
struct Arbiter {
  uint256 totalCases;
  uint256 ratingTotal;
  uint256 slashCount;
  bool active;
}
```

Rating is provided by the **winning party only** after resolution. The losing party has no rating privilege — their incentive to rate negatively regardless of arbiter quality would corrupt the signal.

#### 3.8.2 Automatic Disqualification

```
Rating average < 3.5 / 5.0   →  automatically deactivated
Slash count ≥ 3               →  permanently banned
                                  partial deposit forfeit
```

#### 3.8.3 Arbiter Selection

Arbiters are selected randomly from the active pool for each dispute. Random selection prevents gaming of case assignment. If a selected arbiter fails to respond within the time limit, they are penalized and a new arbiter is selected automatically.

### 3.9 Threshold KYC and Community Safety

#### 3.9.1 Philosophy

RideChain does not involve state law enforcement by design. Identity data is protected by the community itself, accessible only through collective consensus under defined conditions.

#### 3.9.2 Shamir's Secret Sharing

Driver and passenger identity documents (KTP, SIM, vehicle registration) are encrypted at registration using a threshold encryption scheme based on Shamir's Secret Sharing.

The encryption key is split into N shards distributed to N active arbiters. A minimum of M shards must be combined to reconstruct the key and access identity data.

```
Initial deployment (small community):  3-of-5
Growth phase:                          5-of-9
Mature deployment:                     7-of-13
```

Schema upgrades are governed on-chain. Key shards are re-encrypted and redistributed during each upgrade via proactive secret sharing — the underlying secret does not change, but shard holders are rotated.

#### 3.9.3 Identity Access Conditions

The Threshold KYC Contract will only permit identity reconstruction under strictly defined conditions:

```
Permitted:
  - Panic button activated by a participant
  - Community governance vote reaching threshold
  - Escrow value frozen exceeds defined threshold
    (indicator of serious incident)

Prohibited:
  - All other requests, including from protocol developers
```

Every access attempt is recorded permanently on-chain. Silent access is architecturally impossible.

#### 3.9.4 Encrypted Data Storage

Identity documents are stored on IPFS/Arweave after encryption. Only the content hash is stored on-chain. The documents are inaccessible without the reconstructed key regardless of who holds the IPFS hash.

#### 3.9.5 Panic Button

A concealed SOS button is available to both driver and passenger throughout every trip:

```
Activation:
  → Real-time GPS location transmitted to registered emergency contacts
  → Location hash committed to blockchain (irrevocable)
  → Active arbiters in network notified as digital witnesses
  → Cannot be cancelled after activation
```

The irrevocability of panic button activation is a deliberate design choice. Coercion to cancel an activated alert is not possible at the protocol level.

---

## 4. Smart Contract Architecture

RideChain uses a modular contract architecture. Each contract has a single responsibility and can be upgraded independently without affecting others.

### 4.1 Registry Contract

Stores all participant records: drivers, passengers, arbiters.

```solidity
// Core data structures (simplified)

struct Driver {
  address wallet;
  uint256 depositAmount;
  uint256 maxOrderValue;
  uint256 farePerKm;
  uint256 reputationScore;
  uint256 totalTrips;
  bool active;
  bytes32 kycHash;        // IPFS hash of encrypted identity
}

struct Passenger {
  address wallet;
  uint256 reputationScore;
  uint256 totalTrips;
  bool active;
  bytes32 kycHash;
}

struct Arbiter {
  address wallet;
  uint256 depositAmount;
  uint256 totalCases;
  uint256 ratingTotal;
  uint256 slashCount;
  bool active;
}
```

### 4.2 OrderBook Contract

Manages driver availability announcements and order creation.

```
Responsibilities:
  - Receive and store driver ask entries
  - Accept passenger order requests with escrow
  - Match passenger to selected driver
  - Create RideSession upon match
  - Distribute routing fee at order creation
```

### 4.3 RideSession Contract

The core state machine for each trip.

```
States:
  CREATED → ACCEPTED → PICKING_UP → IN_PROGRESS
  → COMPLETED → CONFIRMED
  → DISPUTED → RESOLVED
  → CANCELLED
  → EXPIRED

State transitions are permissioned:
  CREATED → ACCEPTED:     driver only
  ACCEPTED → PICKING_UP:  driver only
  PICKING_UP → IN_PROGRESS: driver only (passenger proximity confirmed)
  IN_PROGRESS → COMPLETED:  driver only
  COMPLETED → CONFIRMED:    passenger or timeout
  ANY → DISPUTED:           passenger only (within window)
  DISPUTED → RESOLVED:      Dispute Contract only
  ANY → CANCELLED:          rules-based (see Section 3.7.3)
  ANY → EXPIRED:            timeout-based (automatic)
```

All state transitions emit on-chain events. GPS Merkle root is submitted at COMPLETED state.

### 4.4 Dispute Contract

```
Responsibilities:
  - Receive dispute trigger from RideSession
  - Select arbiter randomly from Registry pool
  - Manage arbiter response timeout and replacement
  - Receive arbiter decision
  - Execute slash and fund distribution
  - Update reputation scores in Registry
  - Record audit trail
```

### 4.5 Threshold KYC Contract

```
Responsibilities:
  - Store encrypted identity hash per wallet
  - Manage shard distribution metadata
  - Verify access conditions before permitting reconstruction
  - Record every access attempt on-chain
  - Manage shard rotation during schema upgrades
```

### 4.6 Edge Cases and Safety Mechanisms

#### Reentrancy Protection
All functions that transfer funds follow the Checks → Effects → Interactions pattern and use OpenZeppelin's ReentrancyGuard.

#### Minimum Order Value
A protocol-level minimum order value prevents griefing via dust orders that consume contract capacity without genuine intent.

#### Universal Timeouts
Every state has an explicit maximum duration. No state can persist indefinitely. Expired states return funds to their rightful owners automatically.

#### Gas Safety via EIP-1559
All transactions set `maxFeePerGas` at 5× normal average. Transactions queue during congestion rather than failing or overpaying. Gas buffer is included in escrow at order creation and refunded if unused.

#### Gasless Transactions via ERC-4337
Account abstraction allows a protocol paymaster to cover gas fees on behalf of users. Paymaster funding comes from a portion of routing fees. Users never need to hold MATIC for gas — only for fares and deposits.

#### Contract Upgrade Timelock
All contract upgrades are subject to a 48-hour timelock. Users have time to withdraw funds before any upgrade takes effect. Timelock is enforced by a separate TimelockController contract.

---

## 5. Economic Model

### 5.1 Fee Distribution Per Trip

```
From passenger:
  Fare                →  100% to driver (via escrow release)
  Routing fee (0.25%) →  to routing node (at order creation)
  Gas buffer          →  actual gas consumed, remainder refunded

From driver:
  Routing fee (0.25%) →  to routing node (deducted from fare)
  
Protocol fee:           0% (phase 1), activatable via governance
```

### 5.2 Deposit Structure Summary

```
Driver:    2× max order value (locked in Registry Contract)
Passenger: 2× trip fare (locked in RideSession Contract per trip)
Arbiter:   2× arbitration fee (locked in Dispute Contract per case)
```

### 5.3 MATIC Volatility Mitigation

The 2× deposit factor provides a 25% price decline buffer while maintaining 1.5× effective collateral. Chainlink MATIC/USD price feeds provide continuous monitoring. Operations are suspended automatically when collateral falls below safe thresholds, with user notification in IDR equivalent.

### 5.4 Gas Fee Protection

GPS data is stored off-chain as a Merkle tree. Only the Merkle root is submitted on-chain — one transaction regardless of trip length. This reduces per-trip on-chain transactions from potentially dozens to four in the normal case.

---

## 6. Governance

### 6.1 Phase 1 — Deployer Key

Initial deployment is controlled by a single deployer key held by the protocol author. All actions are on-chain and publicly auditable. This phase exists to enable rapid iteration during early development.

### 6.2 Phase 2 — Multisig

As active contributors join the project, the deployer key is replaced by a Gnosis Safe multisig wallet (deployed on Polygon). Protocol changes require M-of-N contributor signatures. No single contributor can make unilateral changes.

### 6.3 Phase 3 — On-chain Governance

At sufficient community scale, governance transitions to on-chain voting by active arbiters — participants with demonstrated commitment to the protocol's integrity. Proposals are submitted on-chain, subject to a voting period, and executed automatically upon passing.

---

## 7. Roadmap

### Phase 1 — Foundation
- Smart contract development and internal testing
- Android APK prototype (wallet, order flow, GPS tracking)
- OSRM node deployment on testnet
- Threshold KYC implementation on testnet

### Phase 2 — Testnet
- Full system deployment on Polygon Mumbai/Amoy testnet
- Community arbiter recruitment
- Security audit of all smart contracts
- Limited pilot with volunteer drivers and passengers

### Phase 3 — Mainnet Launch
- Mainnet deployment on Polygon PoS
- Routing node incentive activation
- Governance transition to multisig

### Phase 4 — Decentralization
- On-chain governance activation
- Threshold KYC schema upgrade to 7-of-13
- Protocol fee activation via governance vote
- Cross-city expansion

---

## 8. Conclusion

RideChain is a response to a specific, documented injustice: the structural exploitation of ride-hailing drivers by centralized platform operators. It applies mature cryptographic and blockchain infrastructure to a problem that technology alone has not yet solved.

The protocol gives drivers ownership of their reputation, control over their pricing, and protection from arbitrary deplatforming. It gives passengers a transparent marketplace with no hidden fees and no algorithmic manipulation. It gives the community tools to enforce accountability without surrendering identity to the state.

No system can guarantee perfect justice. RideChain does not claim to. It claims only to make dishonesty more expensive than honesty — consistently, transparently, and without the need to trust any single party.

That is enough to change the structure of the problem.

---

## References

- Buterin, V. (2013). *Ethereum Whitepaper*
- Nakamoto, S. (2008). *Bitcoin: A Peer-to-Peer Electronic Cash System*
- Shamir, A. (1979). *How to Share a Secret*. Communications of the ACM
- OpenZeppelin. *Smart Contract Security Guidelines*. https://docs.openzeppelin.com
- Chainlink. *Decentralized Oracle Networks*. https://chain.link
- libp2p. *Modular Networking Stack*. https://libp2p.io
- OSRM. *Open Source Routing Machine*. https://project-osrm.org
- OpenStreetMap Foundation. *OpenStreetMap Data*. https://openstreetmap.org
- Ethereum Name Service. *ENS Documentation*. https://docs.ens.domains
- XMTP. *Decentralized Messaging Protocol*. https://xmtp.org
- ERC-4337. *Account Abstraction Standard*. https://eips.ethereum.org/EIPS/eip-4337
- Kleros. *Decentralized Arbitration*. https://kleros.io
- Polygon. *Polygon PoS Documentation*. https://docs.polygon.technology

---

*RideChain is an open protocol. No rights reserved.*
*Contributions welcome. The code, when written, will be free.*
