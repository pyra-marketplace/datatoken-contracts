// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LensTypes} from "../../graph/lens/LensTypes.sol";
import {ILensHub} from "../../graph/lens/ILensHub.sol";
import {ICollectPublicationAction} from "../../graph/lens/ICollectPublicationAction.sol";
import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import {LensDataToken} from "./LensDataToken.sol";
import {IDataTokenHub} from "../../interfaces/IDataTokenHub.sol";
import {IDataTokenFactory} from "../../interfaces/IDataTokenFactory.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {Errors} from "../../libraries/Errors.sol";
import {Events} from "../../libraries/Events.sol";

contract LensDataTokenFactory is IDataTokenFactory {
    address internal immutable DATA_TOKEN_HUB;
    address internal immutable LENS_HUB;

    constructor(address dataTokenHub, address lensHub) {
        DATA_TOKEN_HUB = dataTokenHub;
        LENS_HUB = lensHub;
    }

    /**
     * @inheritdoc IDataTokenFactory
     */
    function createDataToken(bytes calldata initVars) external returns (address) {
        (LensTypes.PostParams memory postParams, LensTypes.EIP712Signature memory signature) =
            abi.decode(initVars, (LensTypes.PostParams, LensTypes.EIP712Signature));

        address profileOwner = IERC721(LENS_HUB).ownerOf(postParams.profileId);

        // 1. forward postWithSig to get pubId and init collect module by passing encoded parameters
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
        IDataTokenHub(DATA_TOKEN_HUB).registerDataToken(profileOwner, LENS_HUB, address(lensDataToken));

        // 4. emit Events
        emit Events.DataTokenCreated(profileOwner, LENS_HUB, address(lensDataToken));
        return address(lensDataToken);
    }
}
