// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Events {
    // DataTokenHub
    event GovernorSet(address indexed prevGovernor, address indexed newGovernor, uint256 timestamp);

    event DataTokenRegistered(address indexed owner, address indexed originalContract, address indexed dataToken);

    event DataTokenFactoryWhitelisted(address indexed factory, bool indexed whitelistStatus);

    // DataTokenFactory
    event DataTokenCreated(address indexed creator, address indexed originalContract, address indexed dataToken);

    // DataTokenBase
    event Collected(address indexed dataToken, address indexed collector, address indexed collectNFT, uint256 tokenId);

    // FeeCollectModule
    event DataTokenCollectModuleBaseConstructed(
        address indexed dataTokenHub, address indexed collectModule, uint256 timestamp
    );
}
