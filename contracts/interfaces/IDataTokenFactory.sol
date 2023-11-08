// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IDataTokenFactory {
    /**
     * @dev create data token from lens, cyberconnect or profileless
     * @param initVars encoded bytes contains initialization
     * @return address deployed data token contract address
     */
    function createDataToken(bytes calldata initVars) external returns (address);
}
