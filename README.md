# FHE Private DeFi Yield Farming

A professional demo DeFi farming dApp built on **Zama's FHEVM**.  
The goal is to demonstrate how yield farming can preserve user privacy while staying auditable and composable in the DeFi ecosystem.  

## Why
Traditional DeFi exposes farming strategies on-chain, making it easy for competitors and bots to copy or front-run positions.  
With **Fully Homomorphic Encryption (FHE)**, we can encrypt deposits, LP positions, and rewards, protecting users while still maintaining verifiability.  

## Key Features
- 🌱 **Encrypted positions** — LP token deposits and stakes are stored as ciphertext.  
- 💰 **Encrypted rewards** — farming yields are calculated privately, decryptable only by the farmer.  
- 🛡️ **Protection against farm sniping** — competitors cannot track allocations in real time.  
- 🔗 **Composable** — can be integrated with other DeFi protocols while maintaining privacy.  
- 📊 **Transparent aggregates** — total value locked (TVL) and pool health stats are auditable without exposing individual users.  

## How It Works
1. User deposits LP tokens → encrypted stake is recorded on-chain.  
2. Yield accrues continuously using FHE computations.  
3. Farmers can claim rewards, which remain encrypted until locally decrypted.  
4. Public only see aggregate pool metrics, not private allocations.  

## Contracts
- `contracts/YieldFarm.sol` — minimal demo contract that stores encrypted positions and manages encrypted yield rewards.  

## Roadmap
- [ ] Add frontend demo for deposit and encrypted claim.  
- [ ] Extend to multi-pool farming (ETH/USDC, ETH/DAI).  
- [ ] Add encrypted governance for reward parameters.  
- [ ] Explore integration with lending/borrowing protocols under privacy constraints.  

## Disclaimer
This is a non-production proof-of-concept to illustrate how **FHEVM** can enable private, trustless, and composable DeFi primitives.
