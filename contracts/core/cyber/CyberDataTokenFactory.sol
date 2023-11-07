// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

import {CyberTypes} from "../../vendor/cyber/CyberTypes.sol";
import {IProfileNFT, CyberTypes} from "../../vendor/cyber/IProfileNFT.sol";
import {CyberDataToken} from "./CyberDataToken.sol";
import {IDataTokenHub} from "../../interfaces/IDataTokenHub.sol";
import {IDataTokenFactory} from "../../interfaces/IDataTokenFactory.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {Errors} from "../../libraries/Errors.sol";
import {Events} from "../../libraries/Events.sol";

contract CyberDataTokenFactory is IDataTokenFactory, ReentrancyGuard {
    address internal immutable DATA_TOKEN_HUB;
    address internal immutable CYBER_PROFILE_NFT;

    constructor(address dataTokenHub, address cyberProfileNFT) {
        DATA_TOKEN_HUB = dataTokenHub;
        CYBER_PROFILE_NFT = cyberProfileNFT;
    }

    /**
     * @inheritdoc IDataTokenFactory
     */
    function createDataToken(bytes calldata initVars) external nonReentrant returns (address) {
        (
            CyberTypes.RegisterEssenceParams memory _essenceParams,
            bytes memory _initData,
            CyberTypes.EIP712Signature memory _sig
        ) = abi.decode(initVars, (CyberTypes.RegisterEssenceParams, bytes, CyberTypes.EIP712Signature));

        // check caller is profile owner
        address profileOwner = IERC721(CYBER_PROFILE_NFT).ownerOf(_essenceParams.profileId);
        if (profileOwner != msg.sender) {
            revert Errors.NotProfileOwner(msg.sender);
        }
        return _createDataToken(profileOwner, _essenceParams, _initData, _sig);
    }

    function createDataTokenWithSig(bytes calldata initVars) external nonReentrant returns (address) {
        (
            CyberTypes.RegisterEssenceParams memory _essenceParams,
            bytes memory _initData,
            CyberTypes.EIP712Signature memory _sig
        ) = abi.decode(initVars, (CyberTypes.RegisterEssenceParams, bytes, CyberTypes.EIP712Signature));

        // check caller is profile owner
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
        DataTypes.Metadata memory metadata = DataTypes.Metadata({
            originalContract: CYBER_PROFILE_NFT,
            profileId: essenceParams.profileId,
            pubId: pubId,
            collectMiddleware: essenceParams.essenceMw
        });

        CyberDataToken cyberDataToken = new CyberDataToken(DATA_TOKEN_HUB, contentURI, metadata);

        // 3. register DataToken to DataTokenHub
        IDataTokenHub(DATA_TOKEN_HUB).registerDataToken(dataTokenCreator, CYBER_PROFILE_NFT, address(cyberDataToken));

        // 4. emit Events
        emit Events.DataTokenCreated(dataTokenCreator, CYBER_PROFILE_NFT, address(cyberDataToken));
        return address(cyberDataToken);
    }
}
