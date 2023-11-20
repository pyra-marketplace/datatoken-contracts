// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {CyberTypes} from "../../graph/cyber/CyberTypes.sol";
import {IProfileNFT, CyberTypes} from "../../graph/cyber/IProfileNFT.sol";
import {IDataToken} from "../../interfaces/IDataToken.sol";
import {IDataTokenFactory} from "../../interfaces/IDataTokenFactory.sol";
import {IDataTokenHub} from "../../interfaces/IDataTokenHub.sol";
import {DataTokenBase} from "../../base/DataTokenBase.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {Errors} from "../../libraries/Errors.sol";

contract CyberDataToken is DataTokenBase, IDataToken {
    /**
     * @inheritdoc IDataToken
     */
    DataTypes.GraphType public constant graphType = DataTypes.GraphType.Cyber;

    constructor(address dataTokenHub, string memory contentURI, DataTypes.Metadata memory metadata)
        DataTokenBase(dataTokenHub, contentURI, metadata)
    {}

    /**
     * @inheritdoc IDataToken
     */
    function collect(bytes memory data) external returns (uint256) {
        // 1.decode
        (
            CyberTypes.CollectParams memory collectParams,
            bytes memory preData,
            bytes memory postData,
            address sender,
            CyberTypes.EIP712Signature memory signature
        ) = abi.decode(data, (CyberTypes.CollectParams, bytes, bytes, address, CyberTypes.EIP712Signature));

        // 2.collect
        uint256 tokenId =
            IProfileNFT(_metadata.originalContract).collectWithSig(collectParams, preData, postData, sender, signature);

        // 3.emit event
        address collectNFT = _getCyberCollectNFT();
        IDataTokenHub(DATA_TOKEN_HUB).emitCollected(sender, collectNFT, tokenId);

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
        return _getCyberTokenOwner();
    }

    /**
     * @inheritdoc IDataToken
     */
    function isCollected(address user) external view returns (bool) {
        if (user == _getCyberTokenOwner()) return true;

        address collectNFT = _getCyberCollectNFT();
        if (collectNFT != address(0) && IERC721(collectNFT).balanceOf(user) > 0) {
            return true;
        }

        return false;
    }

    /**
     * @inheritdoc IDataToken
     */
    function getCollectNFT() external view returns (address) {
        return _getCyberCollectNFT();
    }

    /**
     * @inheritdoc IDataToken
     */
    function getMetadata() external view returns (DataTypes.Metadata memory) {
        return _metadata;
    }

    function _getCyberTokenOwner() internal view returns (address) {
        return IERC721(_metadata.originalContract).ownerOf(_metadata.profileId);
    }

    function _getCyberCollectNFT() internal view returns (address) {
        return IProfileNFT(_metadata.originalContract).getEssenceNFT(_metadata.profileId, _metadata.pubId);
    }
}
