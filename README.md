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

```json
{
  "Polygon": {},
  "Mumbai": {
    "DataTokenHub": "0x30E1568C539346bc1eddd7781C4B442397BE067D",
    "Lens": {
      "DataTokenFactory": "0xBD33A154970C33c99233971509aaED4322b84961",

      "LensHubProxy": "0x60Ae865ee4C725cd04353b5AAb364553f56ceF82",
      "LimitedFeeCollectModule": "0xFCDA2801a31ba70dfe542793020a934F880D54aB",
      "FreeCollectModule": "0x0BE6bD7092ee83D44a6eC1D949626FeE48caB30c",
      "LimitedTimedFeeCollectModule":
        "0xDa76E44775C441eF53B9c769d175fB2948F15e1C",
    },
    "Profileless": {
      "DataTokenFactory": "0x6431eBEfE13E87bde75585C6fd1ea5596161732f",

      "LimitedFeeCollectModule": "0xE8c5253778f1Fd4502CF291e64a8031B9c364760",
      "FreeCollectModule": "0x9347A77e2622536b99Dde836B444be4E89533DE7",
      "LimitedTimedFeeCollectModule":
        "0x45b9fA329b4f96901d326bD3bd2E745Bcbd34D01",
    },
  },
  "BSCT": {
    "DataTokenHub": "0x66B17D5E86109D9C977Bac5fB030738Ff668Df70",
    "Cyber": {
      "DataTokenFactory": "0x9580915945BBB1675e7a4df340dab4137E514fe7",

      "CyberProfileProxy": "0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271",
      "CollectPaidMw": "0x4e0d14e52418881511fd8156585d4b03eec1ff36",
    },
    "Profileless": {
      "DataTokenFactory": "0x5D9DBdCC35A5b87A7FFF1809939eF2221d508123",

      "LimitedFeeCollectModule": "0x3B9d1Ec3A252F1010566e67C81db575512b46a51",
      "FreeCollectModule": "0x82ADCe787883CA32cB21DC7E698280E48eF53AF7",
      "LimitedTimedFeeCollectModule":
        "0x376BF88Ce33564e7A345Bb9f647ea0C7E12dD709",
    },
  },
  "Polygon": {},
  "BSC": {},
  "Scroll": {

  },
  "ScrollSepolia": {
    "DataTokenHub": "0x5957Ee314FF6519962Ebcce71603b7271081F5d2",
    "Profileless": {
      "DataTokenFactory": "0x69a2A4738DcB9cc64A5AC4526987335CC155190a",

      "LimitedFeeCollectModule": "0x088B4DddbdaFF5E006D033A46e89b0D0ec0Be0C8",
      "FreeCollectModule": "0x9c105dDB7810d1EB2640f1F8Dc93060552b4c4FE",
      "LimitedTimedFeeCollectModule": "0xc1D4a3082C88BE811aD59DD0A0F339cc08815b1F",
    }
  },
  "Filecoin":{},
  "Calibration": {}
}
```
