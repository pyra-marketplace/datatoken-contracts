// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Errors {
    // Common
    error ZeroAddress();

    // DataTokenHub
    error NotGovernor();
    error DataTokenFactoryNotWhitelisted();
    error DataTokenNotRegistered(address dataToken);
    error DataTokenAlreadyRegistered(address dataToken);

    // CyberDataTokenFactory
    error NotProfileOwner(address account);

    // DataTokenBase
    error NotDataTokenOwner();
    error NotDataToken();

    // DataverseDataTokenBase
    error InvalidRoyaltyRate(uint256 royaltyRate, uint256 basisPoints);

    // Collect Module
    error CollectExpired();
    error InitParamsInvalid();
    error ExceedCollectLimit();
    error ModuleDataMismatch();
    error NotDataTokenFactory();

    // Eip712
    error SignatureExpired();
    error CreatorNotMatch();
}
