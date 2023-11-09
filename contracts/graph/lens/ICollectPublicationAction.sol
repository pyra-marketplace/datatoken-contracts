// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface ICollectPublicationAction {
    struct CollectData {
        address collectModule;
        address collectNFT;
    }

    function getCollectData(uint256 profileId, uint256 pubId) external view returns (CollectData memory);
}
