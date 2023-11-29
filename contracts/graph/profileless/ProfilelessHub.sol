// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {PublicateNFT} from "./PublicateNFT.sol";
import {CollectNFT} from "./CollectNFT.sol";
import {IProfilelessHub} from "./interfaces/IProfilelessHub.sol";
import {ICollectModule} from "./interfaces/ICollectModule.sol";
import {ProfilelessTypes} from "./libraries/ProfilelessTypes.sol";
import {Typehash} from "./libraries/Typehash.sol";
import {Events} from "./libraries/Events.sol";
import {Errors} from "./libraries/Errors.sol";

contract ProfilelessHub is IProfilelessHub, PublicateNFT, EIP712 {
    address internal _governor;
    mapping(address => uint256) internal _sigNonces;
    mapping(address => bool) internal _isCurrencyWhitelisted;
    mapping(address => bool) internal _isCollectModuleWhitelisted;
    mapping(uint256 => ProfilelessTypes.Publication) internal _publicationById;
    mapping(address => mapping(address => bool)) internal _restrictedStatus;

    constructor(address governor) EIP712("Profileless Hub", "1") {
        _setGovernor(governor);
    }

    modifier onlyGovernor() {
        if (msg.sender != _governor) {
            revert Errors.NotGovernor();
        }
        _;
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function getDomainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function getSigNonces(address signer) external view returns (uint256) {
        return _sigNonces[signer];
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function getGovernor() external view returns (address) {
        return _governor;
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function setGovernor(address newGovernor) external {
        _setGovernor(newGovernor);
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function isCurrencyWhitelisted(address currency) external view returns (bool) {
        return _isCurrencyWhitelisted[currency];
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function whitelistCurrency(address currency, bool isWhitelisted) external onlyGovernor {
        if (currency == address(0)) {
            revert Errors.ZeroAddress();
        }
        _isCurrencyWhitelisted[currency] = isWhitelisted;
        emit Events.CurrencyWhitelisted(currency, isWhitelisted);
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function isCollectModuleWhitelisted(address collectModule) external view returns (bool) {
        return _isCollectModuleWhitelisted[collectModule];
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function whitelistCollectModule(address collectModule, bool isWhitelisted) external onlyGovernor {
        if (collectModule == address(0)) {
            revert Errors.ZeroAddress();
        }
        _isCollectModuleWhitelisted[collectModule] = isWhitelisted;
        emit Events.CollectModuleWhitelisted(collectModule, isWhitelisted);
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function getPublication(uint256 pubId) external view returns (ProfilelessTypes.Publication memory) {
        return _publicationById[pubId];
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function isRestricted(address account, address byAccount) external view returns (bool) {
        return _restrictedStatus[byAccount][account];
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function post(ProfilelessTypes.PostParams memory postParams) external returns (uint256) {
        return _post(postParams, msg.sender);
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function postWithSig(
        ProfilelessTypes.PostParams memory postParams,
        ProfilelessTypes.EIP712Signature memory signature
    ) external returns (uint256) {
        address recoveredAddr = _recoverSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Typehash.POST_WITH_SIG_TYPEHASH,
                        keccak256(bytes(postParams.contentURI)),
                        postParams.collectModule,
                        keccak256(bytes(postParams.collectModuleInitData)),
                        _sigNonces[signature.signer]++,
                        signature.deadline
                    )
                )
            ),
            signature
        );

        if (signature.signer != recoveredAddr) {
            revert Errors.SignatureMismatch();
        }

        return _post(postParams, signature.signer);
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function collect(ProfilelessTypes.CollectParams memory collectParams) external returns (uint256) {
        return _collect(collectParams, msg.sender);
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function collectWithSig(
        ProfilelessTypes.CollectParams memory collectParams,
        ProfilelessTypes.EIP712Signature memory signature
    ) external returns (uint256) {
        address recoveredAddr = _recoverSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Typehash.COLLECT_WITH_SIG_TYPEHASH,
                        collectParams.pubId,
                        keccak256(bytes(collectParams.collectModuleValidateData)),
                        _sigNonces[signature.signer]++,
                        signature.deadline
                    )
                )
            ),
            signature
        );

        if (signature.signer != recoveredAddr) {
            revert Errors.SignatureMismatch();
        }
        return _collect(collectParams, signature.signer);
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function restrict(ProfilelessTypes.RestrictParams memory restrictParams) external {
        _restrict(restrictParams, msg.sender);
    }

    /**
     * @inheritdoc IProfilelessHub
     */
    function restrictWithSig(
        ProfilelessTypes.RestrictParams memory restrictParams,
        ProfilelessTypes.EIP712Signature memory signature
    ) external {
        address recoveredAddr = _recoverSigner(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        Typehash.RESTRICT_WITH_SIG_TYPEHASH,
                        restrictParams.account,
                        restrictParams.restricted,
                        _sigNonces[signature.signer]++,
                        signature.deadline
                    )
                )
            ),
            signature
        );

        if (signature.signer != recoveredAddr) {
            revert Errors.SignatureMismatch();
        }

        _restrict(restrictParams, signature.signer);
    }

    function _post(ProfilelessTypes.PostParams memory postParams, address author) internal returns (uint256) {
        if (!_isCollectModuleWhitelisted[postParams.collectModule]) {
            revert Errors.CollectModuleNotWhitelisted();
        }
        uint256 pubId = _mintPublicateNFT(author);

        _publicationById[pubId] = ProfilelessTypes.Publication({
            pubId: pubId,
            contentURI: postParams.contentURI,
            collectModule: postParams.collectModule,
            collectNFT: address(0)
        });

        bytes memory collectModuleReturnData = ICollectModule(postParams.collectModule)
            .initializePublicationCollectModule(pubId, postParams.collectModuleInitData);

        emit Events.PublicationPosted(
            author, pubId, postParams.contentURI, postParams.collectModule, collectModuleReturnData
        );

        return pubId;
    }

    function _collect(ProfilelessTypes.CollectParams memory collectParams, address collector)
        internal
        returns (uint256)
    {
        if (_restrictedStatus[ownerOf(collectParams.pubId)][collector]) {
            revert Errors.AccountRestricted();
        }
        ProfilelessTypes.Publication storage targetPublication = _publicationById[collectParams.pubId];
        if (targetPublication.collectNFT == address(0)) {
            targetPublication.collectNFT = address(new CollectNFT(address(this)));
        }
        uint256 collectTokenId = CollectNFT(targetPublication.collectNFT).mintCollectNFT(collector);

        ICollectModule(targetPublication.collectModule).processCollect(
            targetPublication.pubId, collector, collectParams.collectModuleValidateData
        );

        emit Events.PublicationCollected(collector, collectParams.pubId);

        return collectTokenId;
    }

    function _restrict(ProfilelessTypes.RestrictParams memory restrictParams, address byAccount) internal {
        _restrictedStatus[byAccount][restrictParams.account] = restrictParams.restricted;
        emit Events.AccountRestricted(restrictParams.account, byAccount, restrictParams.restricted);
    }

    function _setGovernor(address newGovernor) internal {
        if (newGovernor == address(0)) {
            revert Errors.ZeroAddress();
        }
        address previousGovernor = _governor;
        _governor = newGovernor;
        emit Events.GovernorSet(previousGovernor, newGovernor);
    }

    function _recoverSigner(bytes32 digest, ProfilelessTypes.EIP712Signature memory signature)
        internal
        view
        returns (address)
    {
        if (signature.deadline < block.timestamp) revert Errors.SignatureExpired();
        address recoveredAddress = ecrecover(digest, signature.v, signature.r, signature.s);
        return recoveredAddress;
    }
}
