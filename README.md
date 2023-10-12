<br/>
<p align="center">
<a href=" " target="_blank">
<img src="https://bafybeifozdhcbbfydy2rs6vbkbbtj3wc4vjlz5zg2cnqhb2g4rm2o5ldna.ipfs.w3s.link/dataverse.svg" width="180" alt="Dataverse logo">
</a >
</p >
<br/>

# DataToken Contracts

## Overview

The main goal of this project is to abstract the `post` and `collect` functionalities from popular social protocols such as [Lens Protocol](https://github.com/lens-protocol/core) and [Cyber Connect](https://github.com/cyberconnecthq/cybercontracts) into a unified concept called `DataToken`. With the help of different types of `DataTokenFactory`, users can create various types of DataTokens. These DataTokens can then be collected by other users.

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
forge install
```

## Compile

```
forge build
```

## Test

```
forge test
```

Test the code with logs and traces:

```
forge test -vvvv
```

## Deploy

Please add a new file named `.env` and configure your environment as `.env.example` showed.

```
MUMBAI_RPC_URL=
BSCT_RPC_URL=
PRIVATE_KEY=
```

Then source `.env` in shell:

```
source .env
```

The combined deploy script is `script/Deploy.s.sol`.

```
forge script script/Deploy.s.sol --rpc-url $MUMBAI_RPC_URL --broadcast --legacy
forge script script/Deploy.s.sol --rpc-url $BSCT_RPC_URL --broadcast --legacy
```

## Deployed Contract Address

```ts
const DeployedContracts = {
  Mumbai: {
    DataTokenHub: "0x30E1568C539346bc1eddd7781C4B442397BE067D",
    Lens: {
      DataTokenFactory: "0xBD33A154970C33c99233971509aaED4322b84961",

      LensHub: "0x60Ae865ee4C725cd04353b5AAb364553f56ceF82",
      FeeCollectModule: "0xeb4f3EC9d01856Cec2413bA5338bF35CeF932D82",
      FreeCollectModule: "0x0BE6bD7092ee83D44a6eC1D949626FeE48caB30c",
      LimitedTimedFeeCollectModule:
        "0xDa76E44775C441eF53B9c769d175fB2948F15e1C",
      LimitedFeeCollectModule: "0xFCDA2801a31ba70dfe542793020a934F880D54aB",
    },
    Cyber: {},
    Profileless: {
      DataTokenFactory: "0x183aeB3F3f88c2d6f615e844bB4938249A57D9c4",

      FeeCollectModule: "0xC4F8392196FFbaf8eb5Abce8656288D0C3421ec7",
      FreeCollectModule: "0x907b737e88AC5eBF3032Df4E106F2579688161A3",
      LimitedTimedFeeCollectModule:
        "0x5d2B41c42e858D1F756A3CCF663d8e526076c129",
    },
  },
  BSCT: {
    DataTokenHub: "0x66B17D5E86109D9C977Bac5fB030738Ff668Df70",
    Lens: {},
    Cyber: {
      DataTokenFactory: "0x9580915945BBB1675e7a4df340dab4137E514fe7",

      CyberProfileImpl: "0xeD2788C005C8715cFC7C2A29fF81B40b479Cc6fb",
      CyberProfileProxy: "0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271",
      CollectPaidMw: "0x4e0d14e52418881511fd8156585d4b03eec1ff36",
      CollectDisallowedMw: "0xea5ec5a6b2613eebe7df63a6ac394759514baa3f",
      CollectOnlySubscribedMw: "0x13fc351b4daaddd5dd4768ca62f41a10fe548642",
      CollectMerkleDropMw: "0x1488e8f5aab7f609cfdc04997d5c73e4d7b6ad0d",
      SignaturePermissionEssenceMw:
        "0x733142f467904f9a2e8efa0119523d3cc7a99b0b",
      CollectPermissionMw: "0xbbbab0257edba5823ddb5aa62c08f07bd0d302d9",
      StableFeeCreationMw: "0x4db6b3f3236adb0fb85a3957e740f07481c1dc99",
      PermissionedFeeCreationMw: "0xd1587f68e9d9f9ee93c9aa6fc60c7da414e90818",
    },
    Profileless: {},
  },
  Polygon: {},
  BSC: {},
};
```