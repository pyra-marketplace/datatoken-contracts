// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {DataTypes as LensTypes} from "lens-core/contracts/libraries/DataTypes.sol";
import {ILensHub} from "lens-core/contracts/interfaces/ILensHub.sol";
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

    constructor(address lensHub, address dataTokenHub) {
        LENS_HUB = lensHub;
        DATA_TOKEN_HUB = dataTokenHub;
    }

    /**
     * @inheritdoc IDataTokenFactory
     */
    function createDataToken(bytes calldata initVars) external returns (address) {
        LensTypes.PostWithSigData memory postWithSigData = abi.decode(initVars, (LensTypes.PostWithSigData));

        // check caller is profile owner
        address profileOwner = IERC721(LENS_HUB).ownerOf(postWithSigData.profileId);
        if (profileOwner != msg.sender) {
            revert Errors.NotProfileOwner(msg.sender);
        }
        return _createDataToken(profileOwner, postWithSigData);
    }

    function createDataTokenWithSig(bytes calldata initVars) external returns (address) {
        LensTypes.PostWithSigData memory postWithSigData = abi.decode(initVars, (LensTypes.PostWithSigData));
        address profileOwner = IERC721(LENS_HUB).ownerOf(postWithSigData.profileId);
        return _createDataToken(profileOwner, postWithSigData);
    }

    function _createDataToken(address dataTokenCreator, LensTypes.PostWithSigData memory postWithSigData)
        internal
        returns (address)
    {
        // 1. forward post() get pubId and init collect module by passing encoded parameters
        uint256 pubId = ILensHub(LENS_HUB).postWithSig(postWithSigData);
        string memory contentURI = ILensHub(LENS_HUB).getContentURI(postWithSigData.profileId, pubId);

        // 2. create DataToken contract
        DataTypes.Metadata memory metadata;
        metadata.originalContract = LENS_HUB;
        metadata.profileId = postWithSigData.profileId;
        metadata.pubId = pubId;
        metadata.collectModule = postWithSigData.collectModule;

        LensDataToken lensDataToken = new LensDataToken(DATA_TOKEN_HUB, contentURI, metadata);

        // 3. register DataToke to DataTokenHub
        IDataTokenHub(DATA_TOKEN_HUB).registerDataToken(dataTokenCreator, LENS_HUB, address(lensDataToken));

        // 4. emit Events
        emit Events.DataTokenCreated(dataTokenCreator, LENS_HUB, address(lensDataToken));
        return address(lensDataToken);
    }
}
