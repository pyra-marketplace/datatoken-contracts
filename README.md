<br/>
<p align="center">
<a href=" " target="_blank">
<img src="https://bafybeifozdhcbbfydy2rs6vbkbbtj3wc4vjlz5zg2cnqhb2g4rm2o5ldna.ipfs.w3s.link/dataverse.svg" width="180" alt="Dataverse logo">
</a >
</p >
<br/>

# DataToken Contracts

**⚠️ Warning: This Smart Contract has not been professionally audited.**

## Overview

The main goal of this project is to abstract the `post` and `collect` functionalities from popular social protocols such as [Lens Protocol V2](https://github.com/lens-protocol/core) and [Cyber Connect](https://github.com/cyberconnecthq/cybercontracts) into a unified concept called `DataToken`. With the help of different types of `DataTokenFactory`, users can create various types of DataTokens. These DataTokens can then be collected by other users.

- **DataTokenHub**: DataTokenHub contract serves as a central hub for managing DataTokenFactory instances. Its primary functions include whitelisting DataTokenFactories, registering DataTokens, and emitting the "Collected" event in a unified manner.

- **DataTokenFactory**: DataTokenFactory contract is responsible for creating different types of DataTokens. It is categorized into three types: Lens, Cyber, and Profileless. Each type of DataTokenFactory is specialized in creating its corresponding DataToken.

- **DataToken**: DataToken represent ownership of specific data or digital assets. These tokens can be collected, and the resulting revenue will be distributed to the DataToken owners.

## Setup

Install Foundry:

```
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

Install dependencies:

```
npm install
forge install
```

## Compile

```
npm run build
```

## Test

```
npm run test
```

Test the code with logs and traces:

```
npm run test -vvvv
```

## Deploy

Please add a new file named `.env` and configure your environment as `.env.example` showed.

```
npm run deploy:polygon_mumbai
npm run deploy:bsc_testnet
npm run deploy:scroll_sepolia
npm run deploy:filecoin_calibration
```

## Deployed Contract Address

The contract addresses deployed on different blockchain networks are listed in the `addresses.json` file.
