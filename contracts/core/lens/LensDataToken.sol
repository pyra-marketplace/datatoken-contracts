// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {LensTypes} from "../../graph/lens/LensTypes.sol";
import {ILensHub} from "../../graph/lens/ILensHub.sol";
import {ICollectPublicationAction} from "../../graph/lens/ICollectPublicationAction.sol";
import {IDataToken} from "../../interfaces/IDataToken.sol";
import {IDataTokenFactory} from "../../interfaces/IDataTokenFactory.sol";
import {IDataTokenHub} from "../../interfaces/IDataTokenHub.sol";
import {DataTokenBase} from "../../base/DataTokenBase.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {Errors} from "../../libraries/Errors.sol";

contract LensDataToken is DataTokenBase, IDataToken {
    /**
     * @inheritdoc IDataToken
     */
    DataTypes.GraphType public constant graphType = DataTypes.GraphType.Lens;

    constructor(address dataTokenHub, string memory contentURI, DataTypes.Metadata memory metadata)
        DataTokenBase(dataTokenHub, contentURI, metadata)
    {}

    /**
     * @inheritdoc IDataToken
     */
    function collect(bytes memory encodedActWithSigData) external returns (uint256) {
        // 1.decode
        (LensTypes.PublicationActionParams memory publicationActionParams, LensTypes.EIP712Signature memory signature) =
            abi.decode(encodedActWithSigData, (LensTypes.PublicationActionParams, LensTypes.EIP712Signature));

        // 2.collect
        bytes memory returnedData = ILensHub(_metadata.originalContract).actWithSig(publicationActionParams, signature);
        (, uint256 tokenId,,) = abi.decode(returnedData, (address, uint256, address, bytes));

        // 3.emit event
        address collectNFT = _getLensCollectNFT();
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
    function getDataTokenOwner() external view returns (address) {
        return _getLensTokenOwner();
    }

    /**
     * @inheritdoc IDataToken
     */
    function isCollected(address user) external view returns (bool) {
        if (user == _getLensTokenOwner()) {
            return true;
        }

        address collectNFT = _getLensCollectNFT();
        if (collectNFT != address(0) && IERC721(collectNFT).balanceOf(user) > 0) {
            return true;
        }

        return false;
    }

    /**
     * @inheritdoc IDataToken
     */
    function getCollectNFT() external view returns (address) {
        return _getLensCollectNFT();
    }

    /**
     * @inheritdoc IDataToken
     */
    function getMetadata() external view returns (DataTypes.Metadata memory) {
        return _metadata;
    }

    function _getLensTokenOwner() internal view returns (address) {
        return IERC721(_metadata.originalContract).ownerOf(_metadata.profileId);
    }

    function _getLensCollectNFT() internal view returns (address) {
        return ICollectPublicationAction(_metadata.collectMiddleware).getCollectData(
            _metadata.profileId, _metadata.pubId
        ).collectNFT;
    }
}
