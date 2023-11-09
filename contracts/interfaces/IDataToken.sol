// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";

interface IDataToken {
    /**
     * @dev get graph type (Lens, Cyber or Profileless)
     */
    function graphType() external view returns (DataTypes.GraphType);

    /**
     * @dev execute collect
     * @param data eg. encoded LensTypes.CollectWithSigData bytes
     * @return tokenId
     */
    function collect(bytes memory data) external returns (uint256);

    /**
     * @dev get current contentURI from DataToken contract
     * @return string current contentURI
     */
    function getContentURI() external view returns (string memory);

    /**
     * @dev check whether the user has collected
     * @param user user account
     */
    function isCollected(address user) external view returns (bool);

    /**
     * @dev get collect NFT contract address
     */
    function getCollectNFT() external view returns (address);

    /**
     * @dev get metadata from DataToken contract
     * @return DataTypes.Metadata
     */
    function getMetadata() external view returns (DataTypes.Metadata memory);

    /**
     * @dev get the owner of data token, the same as the original token owner
     * @return address the owner address
     */
    function getDataTokenOwner() external view returns (address);
}
