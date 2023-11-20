// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {IProfilelessHub} from "../../graph/profileless/interfaces/IProfilelessHub.sol";
import {ProfilelessTypes} from "../../graph/profileless/libraries/ProfilelessTypes.sol";
import {IDataToken} from "../../interfaces/IDataToken.sol";
import {IDataTokenHub} from "../../interfaces/IDataTokenHub.sol";
import {DataTokenBase} from "../../base/DataTokenBase.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";

contract ProfilelessDataToken is DataTokenBase, IDataToken {
    /**
     * @inheritdoc IDataToken
     */
    DataTypes.GraphType public constant graphType = DataTypes.GraphType.Profileless;

    constructor(address dataTokenHub, string memory contentURI, DataTypes.Metadata memory metadata)
        DataTokenBase(dataTokenHub, contentURI, metadata)
    {}

    /**
     * @inheritdoc IDataToken
     */
    function collect(bytes memory data) external returns (uint256) {
        // 1.decode
        (ProfilelessTypes.CollectParams memory collectParams, ProfilelessTypes.EIP712Signature memory signature) =
            abi.decode(data, (ProfilelessTypes.CollectParams, ProfilelessTypes.EIP712Signature));

        // 2.collect
        uint256 tokenId = IProfilelessHub(_metadata.originalContract).collectWithSig(collectParams, signature);

        // 3.emit event
        address collectNFT = _getProfilelessCollectNFT();
        IDataTokenHub(DATA_TOKEN_HUB).emitCollected(signature.signer, collectNFT, tokenId);

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
        if (user == _getProfilelessTokenOwner()) {
            return true;
        }

        address collectNFT = _getProfilelessCollectNFT();
        if (collectNFT != address(0) && IERC721(collectNFT).balanceOf(user) > 0) {
            return true;
        }

        return false;
    }

    /**
     * @inheritdoc IDataToken
     */
    function getCollectNFT() public view returns (address) {
        return _getProfilelessCollectNFT();
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

    function _getProfilelessTokenOwner() internal view returns (address) {
        return IERC721(_metadata.originalContract).ownerOf(_metadata.pubId);
    }

    function _getProfilelessCollectNFT() internal view returns (address) {
        return IProfilelessHub(_metadata.originalContract).getPublication(_metadata.pubId).collectNFT;
    }
}
