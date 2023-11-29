// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Errors {
    error ZeroAddress();
    error NotGovernor();
    error NotProfilelessHub();
    error SignatureMismatch();
    error SignatureExpired();
    error ModuleDataMismatch();
    error CollectModuleNotWhitelisted();
    error AccountRestricted();
}
