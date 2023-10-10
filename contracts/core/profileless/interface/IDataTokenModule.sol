// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

interface IDataTokenModule {
    function initializePublicationCollectModule(uint256 pubId, bytes calldata data, address dataToken)
        external
        returns (bytes memory);
    function processCollect(uint256 id, address collector, bytes calldata data) external;
}
