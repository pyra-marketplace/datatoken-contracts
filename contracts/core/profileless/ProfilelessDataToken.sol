// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ProfilelessDataTokenBase} from "./base/ProfilelessDataTokenBase.sol";
import {IDataTokenModule} from "./interface/IDataTokenModule.sol";
import {IDataToken} from "../../interfaces/IDataToken.sol";
import {IDataTokenHub} from "../../interfaces/IDataTokenHub.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";

contract ProfilelessDataToken is ProfilelessDataTokenBase, IDataToken {
    /**
     * @inheritdoc IDataToken
     */
    DataTypes.GraphType public constant graphType = DataTypes.GraphType.Profileless;

    constructor(address dataTokenHub, string memory contentURI, DataTypes.Metadata memory metadata)
        ProfilelessDataTokenBase(dataTokenHub, contentURI, metadata)
    {}

    /**
     * @inheritdoc IDataToken
     */
    function collect(bytes memory data) external returns (uint256) {
        // 1.decode
        (address collector, bytes memory validateData) = abi.decode(data, (address, bytes));

        // 2.collect
        IDataTokenModule(_metadata.collectMiddleware).processCollect(_metadata.pubId, collector, validateData);
        uint256 tokenId = _mintCollectNFT(collector);

        // 3.emit event
        IDataTokenHub(DATA_TOKEN_HUB).emitCollected(collector, address(this), tokenId);

        return tokenId;
    }

    /**
     * @inheritdoc IDataToken
     */
    function getContentURI() external view returns (string memory) {
        return _contentURI;
    }

    /**
     * @inheritdoc IDataToken
     */
    function isCollected(address user) external view returns (bool) {
        if (_getProfilelessTokenOwner() == user || balanceOf(user) > 0) {
            return true;
        }
        return false;
    }

    /**
     * @inheritdoc IDataToken
     */
    function getCollectNFT() public view returns (address) {
        return address(this);
    }

    /**
     * @inheritdoc IDataToken
     */
    function getMetadata() external view returns (DataTypes.Metadata memory) {
        return _metadata;
    }

    /**
     * @inheritdoc IDataToken
     */
    function getDataTokenOwner() external view override returns (address) {
        return _getProfilelessTokenOwner();
    }
}
