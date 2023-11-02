// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IDataTokenFactory {
    /**
     * @dev create data token from lens, cyberconnect or profileless
     * @param initVars encoded bytes contains initialization
     * @return address deployed data token contract address
     */
    function createDataToken(bytes calldata initVars) external returns (address);

    /**
     * @dev create data token from lens, cyberconnect or profileless
     * @param initVars encoded bytes contains initialization and signature data
     * @return address deployed data token contract address
     */
    function createDataTokenWithSig(bytes memory initVars) external returns (address);
}
