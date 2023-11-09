// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Errors {
    error ZeroAddress();
    error NotGovernor();
    error DataTokenFactoryNotWhitelisted();
    error DataTokenNotRegistered(address dataToken);
    error DataTokenAlreadyRegistered(address dataToken);
}
