// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {IProfileNFT, CyberTypes} from "../../libraries/Cyber.sol";
import {CyberDataToken} from "./CyberDataToken.sol";
import {IDataTokenHub} from "../../interfaces/IDataTokenHub.sol";
import {IDataTokenFactory} from "../../interfaces/IDataTokenFactory.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {Errors} from "../../libraries/Errors.sol";
import {Events} from "../../libraries/Events.sol";

contract CyberDataTokenFactory is IDataTokenFactory {
    address internal immutable DATA_TOKEN_HUB;
    address internal immutable CYBER_PROFILE_NFT;

    constructor(address cyberProfileNFT, address dataTokenHub) {
        CYBER_PROFILE_NFT = cyberProfileNFT;
        DATA_TOKEN_HUB = dataTokenHub;
    }

    /**
     * @inheritdoc IDataTokenFactory
     */
    function createDataToken(bytes calldata initVars) external returns (address) {
        (
            CyberTypes.RegisterEssenceParams memory _essenceParams,
            bytes memory _initData,
            CyberTypes.EIP712Signature memory _sig
        ) = abi.decode(initVars, (CyberTypes.RegisterEssenceParams, bytes, CyberTypes.EIP712Signature));

        // 1.check caller is profile owner
        address profileOwner = IERC721(CYBER_PROFILE_NFT).ownerOf(_essenceParams.profileId);
        if (profileOwner != msg.sender) {
            revert Errors.NotProfileOwner(msg.sender);
        }
        return _createDataToken(profileOwner, _essenceParams, _initData, _sig);
    }

    function createDataTokenWithSig(bytes calldata initVars) external returns (address) {
        (
            CyberTypes.RegisterEssenceParams memory _essenceParams,
            bytes memory _initData,
            CyberTypes.EIP712Signature memory _sig
        ) = abi.decode(initVars, (CyberTypes.RegisterEssenceParams, bytes, CyberTypes.EIP712Signature));

        // 1.check caller is profile owner
        address profileOwner = IERC721(CYBER_PROFILE_NFT).ownerOf(_essenceParams.profileId);
        return _createDataToken(profileOwner, _essenceParams, _initData, _sig);
    }

    function _createDataToken(
        address dataTokenCreator,
        CyberTypes.RegisterEssenceParams memory essenceParams,
        bytes memory _initData,
        CyberTypes.EIP712Signature memory _sig
    ) internal returns (address) {
        // 1. forward post() got essenceId as pubId and init collect module by passing encoded parameters
        uint256 pubId = IProfileNFT(CYBER_PROFILE_NFT).registerEssenceWithSig(essenceParams, _initData, _sig);
        string memory contentURI = IProfileNFT(CYBER_PROFILE_NFT).getEssenceNFTTokenURI(essenceParams.profileId, pubId);

        // 2. create DataToken contract
        DataTypes.Metadata memory metadata;
        metadata.originalContract = CYBER_PROFILE_NFT;
        metadata.profileId = essenceParams.profileId;
        metadata.pubId = pubId;
        metadata.collectModule = essenceParams.essenceMw;
        CyberDataToken cyberDataToken = new CyberDataToken(DATA_TOKEN_HUB, contentURI, metadata);

        // 3. register DataToken to DataTokenHub
        IDataTokenHub(DATA_TOKEN_HUB).registerDataToken(dataTokenCreator, CYBER_PROFILE_NFT, address(cyberDataToken));

        // 4. emit Events
        emit Events.DataTokenCreated(dataTokenCreator, CYBER_PROFILE_NFT, address(cyberDataToken));
        return address(cyberDataToken);
    }
}