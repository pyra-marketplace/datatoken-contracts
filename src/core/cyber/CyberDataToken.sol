// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {IProfileNFT, CyberTypes} from "../../libraries/Cyber.sol";
import {IDataToken} from "../../interfaces/IDataToken.sol";
import {IDataTokenHub} from "../../interfaces/IDataTokenHub.sol";
import {DataTokenBase} from "../../base/DataTokenBase.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {Errors} from "../../libraries/Errors.sol";

contract CyberDataToken is DataTokenBase, IDataToken {
    constructor(address dataTokenHub, string memory contentURI, DataTypes.Metadata memory metadata)
        DataTokenBase(dataTokenHub, contentURI, metadata)
    {}

    /**
     * @inheritdoc IDataToken
     */
    function collect(bytes memory data) external returns (uint256) {
        // 1.decode
        (
            CyberTypes.CollectParams memory _params,
            bytes memory _preData,
            bytes memory _postData,
            address _sender,
            CyberTypes.EIP712Signature memory _sig
        ) = abi.decode(data, (CyberTypes.CollectParams, bytes, bytes, address, CyberTypes.EIP712Signature));

        // 2.collect
        uint256 tokenId =
            IProfileNFT(_metadata.originalContract).collectWithSig(_params, _preData, _postData, _sender, _sig);

        // 3.emit event
        address collectNFT = IProfileNFT(_metadata.originalContract).getEssenceNFT(_params.profileId, _params.essenceId);
        IDataTokenHub(DATA_TOKEN_HUB).emitCollected(_sender, collectNFT, tokenId);

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
        return _getCyberTokenOwner();
    }

    /**
     * @inheritdoc IDataToken
     */
    function isCollected(address user) external view returns (bool) {
        if (user == getDataTokenOwner()) return true;

        address collectNFT = getCollectNFT();
        if (collectNFT != address(0) && IERC721(collectNFT).balanceOf(user) > 0) {
            return true;
        }
        return true;
    }

    /**
     * @inheritdoc IDataToken
     */
    function getCollectNFT() public view returns (address) {
        return IProfileNFT(_metadata.originalContract).getEssenceNFT(_metadata.profileId, _metadata.pubId);
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

    function _getCyberTokenOwner() internal view returns (address) {
        return IERC721(_metadata.originalContract).ownerOf(_metadata.profileId);
    }
}
