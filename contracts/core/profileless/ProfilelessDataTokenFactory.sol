// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ProfilelessDataToken} from "./ProfilelessDataToken.sol";
import {IProfilelessHub} from "../../graph/profileless/interfaces/IProfilelessHub.sol";
import {ProfilelessTypes} from "../../graph/profileless/libraries/ProfilelessTypes.sol";
import {IDataTokenFactory} from "../../interfaces/IDataTokenFactory.sol";
import {IDataTokenHub} from "../../interfaces/IDataTokenHub.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {Errors} from "../../libraries/Errors.sol";
import {Events} from "../../libraries/Events.sol";

contract ProfilelessDataTokenFactory is IDataTokenFactory {
    address internal immutable DATA_TOKEN_HUB;
    address internal immutable PROFILELESS_HUB;

    constructor(address dataTokenHub, address profilelessHub) {
        DATA_TOKEN_HUB = dataTokenHub;
        PROFILELESS_HUB = profilelessHub;
    }

    /**
     * @inheritdoc IDataTokenFactory
     */
    function createDataToken(bytes calldata initVars) external returns (address) {
        (ProfilelessTypes.PostParams memory postParams, ProfilelessTypes.EIP712Signature memory signature) =
            abi.decode(initVars, (ProfilelessTypes.PostParams, ProfilelessTypes.EIP712Signature));

        // 1. forward postWithSig to get pubId and init collect module by passing encoded parameters
        uint256 pubId = IProfilelessHub(PROFILELESS_HUB).postWithSig(postParams, signature);

        // 2. create DataToken contract
        DataTypes.Metadata memory metadata = DataTypes.Metadata({
            originalContract: PROFILELESS_HUB,
            profileId: 0,
            pubId: pubId,
            collectMiddleware: postParams.collectModule
        });

        ProfilelessDataToken dataToken = new ProfilelessDataToken(DATA_TOKEN_HUB, postParams.contentURI, metadata);

        // 3. register DataToke to DataTokenHub
        IDataTokenHub(DATA_TOKEN_HUB).registerDataToken(signature.signer, PROFILELESS_HUB, address(dataToken));

        // 4. emit Events
        emit Events.DataTokenCreated(signature.signer, PROFILELESS_HUB, address(dataToken));
        return address(dataToken);
    }
}
