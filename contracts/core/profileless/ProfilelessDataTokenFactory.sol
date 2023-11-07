// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ReentrancyGuard} from "openzeppelin-contracts/contracts/security/ReentrancyGuard.sol";

import {ProfilelessDataTokenFactoryBase} from "./base/ProfilelessDataTokenFactoryBase.sol";
import {ProfilelessDataToken} from "./ProfilelessDataToken.sol";
import {IDataTokenModule} from "./interface/IDataTokenModule.sol";
import {IDataTokenFactory} from "../../interfaces/IDataTokenFactory.sol";
import {IDataTokenHub} from "../../interfaces/IDataTokenHub.sol";
import {DataTypes} from "../../libraries/DataTypes.sol";
import {Errors} from "../../libraries/Errors.sol";
import {Events} from "../../libraries/Events.sol";

contract ProfilelessDataTokenFactory is ProfilelessDataTokenFactoryBase, IDataTokenFactory, ReentrancyGuard {
    address internal immutable DATA_TOKEN_HUB;

    constructor(address dataTokenHub) {
        DATA_TOKEN_HUB = dataTokenHub;
    }

    /**
     * @inheritdoc IDataTokenFactory
     */
    function createDataToken(bytes calldata initVars) external nonReentrant returns (address) {
        DataTypes.PostParams memory postParams = abi.decode(initVars, (DataTypes.PostParams));
        return _createDataToken(msg.sender, postParams);
    }

    /**
     * @inheritdoc IDataTokenFactory
     */
    function createDataTokenWithSig(bytes memory initVars) external nonReentrant returns (address) {
        (DataTypes.PostParams memory postParams, DataTypes.EIP712Signature memory signature) =
            abi.decode(initVars, (DataTypes.PostParams, DataTypes.EIP712Signature));
        address recoveredAddr = _recoverSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        CREATE_DATA_TOKEN_WITH_SIG_TYPEHASH,
                        keccak256(bytes(postParams.contentURI)),
                        postParams.collectModule,
                        keccak256(bytes(postParams.collectModuleInitData)),
                        sigNonces[signature.signer]++,
                        signature.deadline
                    )
                )
            ),
            signature
        );

        // check recovered address
        if (signature.signer != recoveredAddr) {
            revert Errors.CreatorNotMatch();
        }

        return _createDataToken(signature.signer, postParams);
    }

    function _createDataToken(address dataTokenCreator, DataTypes.PostParams memory postParams)
        internal
        returns (address)
    {
        // 1. mint pub NFT to get pubId
        uint256 pubId = _mintPublicationNFT(dataTokenCreator);

        // 2. create DataToke contract
        DataTypes.Metadata memory metadata = DataTypes.Metadata({
            originalContract: address(this),
            profileId: 0,
            pubId: pubId,
            collectMiddleware: postParams.collectModule
        });

        ProfilelessDataToken dataToken = new ProfilelessDataToken(DATA_TOKEN_HUB, postParams.contentURI, metadata);

        // 3. register DataToke to DataTokenHub
        IDataTokenHub(DATA_TOKEN_HUB).registerDataToken(dataTokenCreator, address(this), address(dataToken));

        // 4. init collect module by passing encoded parameters
        IDataTokenModule(postParams.collectModule).initializePublicationCollectModule(
            pubId, postParams.collectModuleInitData, address(dataToken)
        );

        // 5. change contract state
        _tokenIdByDataToken[address(dataToken)] = pubId;

        // 6. emit Events
        emit Events.DataTokenCreated(dataTokenCreator, address(this), address(dataToken));
        return address(dataToken);
    }
}
