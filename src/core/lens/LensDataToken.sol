// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {ILensHub} from "lens-core/contracts/interfaces/ILensHub.sol";
import {DataTypes as LensTypes} from "lens-core/contracts/libraries/DataTypes.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {IDataToken} from "../../interfaces/IDataToken.sol";
import {IDataTokenHub} from "../../interfaces/IDataTokenHub.sol";
import {DataTokenBase} from "../../base/DataTokenBase.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {Errors} from "../../libraries/Errors.sol";

contract LensDataToken is DataTokenBase, IDataToken {
    constructor(address dataTokenHub, string memory contentURI, DataTypes.Metadata memory metadata)
        DataTokenBase(dataTokenHub, contentURI, metadata)
    {}

    /**
     * @inheritdoc IDataToken
     */
    function collect(bytes memory encodedCollectWithSigData) external returns (uint256) {
        // 1.decode
        LensTypes.CollectWithSigData memory decodedCollectWithSigData =
            abi.decode(encodedCollectWithSigData, (LensTypes.CollectWithSigData));

        // 2.collect
        uint256 tokenId = ILensHub(_metadata.originalContract).collectWithSig(decodedCollectWithSigData);

        // 3.emit event
        address collectNFT = ILensHub(_metadata.originalContract).getCollectNFT(_metadata.profileId, _metadata.pubId);
        IDataTokenHub(DATA_TOKEN_HUB).emitCollected(decodedCollectWithSigData.collector, collectNFT, tokenId);

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
    function getDataTokenOwner() public view returns (address) {
        return _getLensTokenOwner();
    }

    /**
     * @inheritdoc IDataToken
     */
    function isCollected(address user) external view returns (bool) {
        if (user == getDataTokenOwner()) {
            return true;
        }

        address collectNFT = getCollectNFT();
        if (collectNFT != address(0) && IERC721(collectNFT).balanceOf(user) > 0) {
            return true;
        }

        return false;
    }

    /**
     * @inheritdoc IDataToken
     */
    function getCollectNFT() public view returns (address) {
        return ILensHub(_metadata.originalContract).getCollectNFT(_metadata.profileId, _metadata.pubId);
    }

    /**
     * @inheritdoc IDataToken
     */
    function getMetadata() external view returns (DataTypes.Metadata memory) {
        return _metadata;
    }

    /**
     * @inheritdoc DataTokenBase
     */
    function _checkDataTokenOwner() internal view override {
        if (msg.sender != getDataTokenOwner()) {
            revert Errors.NotDataTokenOwner();
        }
    }

    function _getLensTokenOwner() internal view returns (address) {
        return IERC721(_metadata.originalContract).ownerOf(_metadata.profileId);
    }
}
