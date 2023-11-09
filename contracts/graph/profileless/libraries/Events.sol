// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Events {
    event GovernorSet(address previousGovernor, address newGovernor);
    event CurrencyWhitelisted(address currency, bool isWhitelisted);
    event CollectModuleWhitelisted(address collectModule, bool isWhitelisted);
    event PublicationPosted(
        address indexed author,
        uint256 indexed pubId,
        string contentURI,
        address collectModule,
        bytes collectModuleReturnData
    );
    event PublicationCollected(address indexed collector, uint256 indexed pubId);
}
