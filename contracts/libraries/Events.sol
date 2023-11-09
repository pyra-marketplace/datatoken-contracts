// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Events {
    event GovernorSet(address indexed prevGovernor, address indexed newGovernor, uint256 timestamp);

    event DataTokenRegistered(address indexed owner, address indexed originalContract, address indexed dataToken);

    event DataTokenFactoryWhitelisted(address indexed factory, bool indexed whitelistStatus);

    event DataTokenCreated(address indexed creator, address indexed originalContract, address indexed dataToken);

    event Collected(address indexed dataToken, address indexed collector, address indexed collectNFT, uint256 tokenId);
}
