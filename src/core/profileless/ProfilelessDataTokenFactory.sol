// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ProfilelessDataTokenFactoryBase} from "./base/ProfilelessDataTokenFactoryBase.sol";
import {ProfilelessDataToken} from "./ProfilelessDataToken.sol";
import {SigBase} from "./base/SigBase.sol";
import {IDataTokenModule} from "./interface/IDataTokenModule.sol";
import {IDataTokenFactory} from "../../interfaces/IDataTokenFactory.sol";
import {IDataTokenHub} from "../../interfaces/IDataTokenHub.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {Errors} from "../../libraries/Errors.sol";
import {Events} from "../../libraries/Events.sol";

contract ProfilelessDataTokenFactory is Ownable, ProfilelessDataTokenFactoryBase, SigBase, IDataTokenFactory {
    address internal immutable DATA_TOKEN_HUB;

    constructor(address dataTokenHub) SigBase("ProfilelessDataTokenFactory", "1.0") {
        DATA_TOKEN_HUB = dataTokenHub;
    }

    /**
     * @inheritdoc IDataTokenFactory
     */
    function createDataToken(bytes calldata initVars) external returns (address) {
        DataTypes.ProfilelessPostData memory postData = abi.decode(initVars, (DataTypes.ProfilelessPostData));
        return _createDataToken(msg.sender, postData);
    }

    /**
     * @inheritdoc IDataTokenFactory
     */
    function createDataTokenWithSig(bytes memory initVars) external returns (address) {
        (DataTypes.ProfilelessPostData memory postData, DataTypes.ProfilelessPostDataSigParams memory sigParams) =
            abi.decode(initVars, (DataTypes.ProfilelessPostData, DataTypes.ProfilelessPostDataSigParams));
        address recoveredAddr = _recoverSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        CREATE_DATA_TOKEN_WITH_SIG_TYPEHASH,
                        keccak256(bytes(postData.contentURI)),
                        postData.collectModule,
                        keccak256(bytes(postData.collectModuleInitData)),
                        sigNonces[sigParams.dataTokenCreator]++,
                        sigParams.sig.deadline
                    )
                )
            ),
            sigParams.sig
        );

        // 0. check recovered address
        if (sigParams.dataTokenCreator != recoveredAddr) {
            revert Errors.CreatorNotMatch();
        }

        return _createDataToken(sigParams.dataTokenCreator, postData);
    }

    function _createDataToken(address dataTokenCreator, DataTypes.ProfilelessPostData memory postData)
        internal
        returns (address)
    {
        // 2. mint pub NFT to get pubId
        uint256 pubId = _mintPublicationNFT(dataTokenCreator);

        // 3. create DataToke contract
        DataTypes.Metadata memory metadata;
        metadata.originalContract = address(this);
        metadata.profileId = 0;
        metadata.pubId = pubId;
        metadata.collectModule = postData.collectModule;

        ProfilelessDataToken dataToken = new ProfilelessDataToken(DATA_TOKEN_HUB, postData.contentURI, metadata);

        // 4. register DataToke to DataTokenHub
        IDataTokenHub(DATA_TOKEN_HUB).registerDataToken(dataTokenCreator, address(this), address(dataToken));

        // 5. init collect module by passing encoded parameters
        IDataTokenModule(postData.collectModule).initializePublicationCollectModule(
            pubId, postData.collectModuleInitData, address(dataToken)
        );

        // 5. change contract state
        _tokenIdByDataToken[address(dataToken)] = pubId;

        // 6. emit Events
        emit Events.DataTokenCreated(dataTokenCreator, address(this), address(dataToken));
        return address(dataToken);
    }
}
