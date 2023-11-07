// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import {LensTypes} from "../../vendor/lens/LensTypes.sol";
import {ILensHub} from "../../vendor/lens/ILensHub.sol";
import {ICollectPublicationAction} from "../../vendor/lens/ICollectPublicationAction.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {LensDataToken} from "./LensDataToken.sol";
import {IDataTokenHub} from "../../interfaces/IDataTokenHub.sol";
import {IDataTokenFactory} from "../../interfaces/IDataTokenFactory.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {Errors} from "../../libraries/Errors.sol";
import {Events} from "../../libraries/Events.sol";

contract LensDataTokenFactory is IDataTokenFactory, ReentrancyGuard {
    address internal immutable DATA_TOKEN_HUB;
    address internal immutable LENS_HUB;

    constructor(address dataTokenHub, address lensHub) {
        DATA_TOKEN_HUB = dataTokenHub;
        LENS_HUB = lensHub;
    }

    /**
     * @inheritdoc IDataTokenFactory
     */
    function createDataToken(bytes calldata initVars) external nonReentrant returns (address) {
        (LensTypes.PostParams memory postParams, LensTypes.EIP712Signature memory signature) =
            abi.decode(initVars, (LensTypes.PostParams, LensTypes.EIP712Signature));
        // check caller is profile owner
        address profileOwner = IERC721(LENS_HUB).ownerOf(postParams.profileId);
        if (profileOwner != msg.sender) {
            revert Errors.NotProfileOwner(msg.sender);
        }
        return _createDataToken(profileOwner, postParams, signature);
    }

    /**
     * @inheritdoc IDataTokenFactory
     */
    function createDataTokenWithSig(bytes calldata initVars) external nonReentrant returns (address) {
        (LensTypes.PostParams memory postParams, LensTypes.EIP712Signature memory signature) =
            abi.decode(initVars, (LensTypes.PostParams, LensTypes.EIP712Signature));
        address profileOwner = IERC721(LENS_HUB).ownerOf(postParams.profileId);
        return _createDataToken(profileOwner, postParams, signature);
    }

    function _createDataToken(
        address dataTokenCreator,
        LensTypes.PostParams memory postParams,
        LensTypes.EIP712Signature memory signature
    ) internal returns (address) {
        // 1. forward post() get pubId and init collect module by passing encoded parameters
        uint256 pubId = ILensHub(LENS_HUB).postWithSig(postParams, signature);
        string memory contentURI = ILensHub(LENS_HUB).getContentURI(postParams.profileId, pubId);

        // 2. create DataToken contract
        DataTypes.Metadata memory metadata = DataTypes.Metadata({
            originalContract: LENS_HUB,
            profileId: postParams.profileId,
            pubId: pubId,
            collectMiddleware: postParams.actionModules[0]
        });

        LensDataToken lensDataToken = new LensDataToken(DATA_TOKEN_HUB, contentURI, metadata);

        // 3. register DataToke to DataTokenHub
        IDataTokenHub(DATA_TOKEN_HUB).registerDataToken(dataTokenCreator, LENS_HUB, address(lensDataToken));

        // 4. emit Events
        emit Events.DataTokenCreated(dataTokenCreator, LENS_HUB, address(lensDataToken));
        return address(lensDataToken);
    }
}
