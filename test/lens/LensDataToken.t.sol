// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {LensTypes} from "../../contracts/vendor/lens/LensTypes.sol";
import {Typehash} from "../../contracts/vendor/lens/Typehash.sol";
import {ICollectPublicationAction} from "../../contracts/vendor/lens/ICollectPublicationAction.sol";
import {LensDataTokenFactory} from "../../contracts/core/lens/LensDataTokenFactory.sol";
import {LensDataToken} from "../../contracts/core/lens/LensDataToken.sol";
import {IDataToken} from "../../contracts/interfaces/IDataToken.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {Events} from "../../contracts/libraries/Events.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";
import {Constants} from "../../contracts/libraries/Constants.sol";
import {Test} from "forge-std/Test.sol";
import {LensBaseTest} from "./Base.t.sol";

contract LensDataTokenTest is Test, LensBaseTest {
    address governor;
    address notGovernor;
    address dataTokenOwner;
    uint256 dataTokenOwnerPK;
    uint256 dataTokenOwnerProfileId;
    address collector;
    uint256 collectorPK;
    uint256 collectorProfileId;
    address notCollector;
    LensDataTokenFactory dataTokenFactory;
    LensDataToken lensDataToken;

    string contentURI;
    address currency;
    uint160 amount;
    uint96 collectLimit;
    uint256 deadline;

    function setUp() public {
        _setUp();
        governor = makeAddr("governor");
        notGovernor = makeAddr("notGovernor");
        dataTokenOwnerPK = vm.envUint("PRIVATE_KEY");
        dataTokenOwner = vm.addr(dataTokenOwnerPK);
        collectorPK = vm.envUint("PRIVATE_KEY");
        collector = vm.addr(collectorPK);
        notCollector = makeAddr("notCollector");
        contentURI = "https://dataverse-os.com";
        currency = LENS_CONTRACTS.WMATIC;
        amount = 10;
        collectLimit = type(uint96).max;
        deadline = block.timestamp + 1 days;

        vm.startPrank(governor);
        _createDataTokenHub();

        dataTokenFactory = new LensDataTokenFactory(
            address(dataTokenHub),
            address(LENS_CONTRACTS.lensHub)
        );
        dataTokenHub.whitelistDataTokenFactory(address(dataTokenFactory), true);
        vm.stopPrank();

        dataTokenOwnerProfileId = _getLensProfiles(dataTokenOwner)[0];
        collectorProfileId = _getLensProfiles(collector)[0];

        lensDataToken = _createDataToken();
    }

    function test_GraphType() public {
        assertTrue(lensDataToken.graphType() == DataTypes.GraphType.Lens);
    }

    function test_Collect() public {
        bytes memory data = _getActWithSigDataBytes();
        vm.startPrank(collector);
        IERC20(currency).approve(LENS_CONTRACTS.simpleFeeCollectModule, amount);
        lensDataToken.collect(data);
        vm.stopPrank();
        assertTrue(lensDataToken.isCollected(collector));
    }

    function test_IsCollected() public {
        assertFalse(lensDataToken.isCollected(notCollector));

        bytes memory data = _getActWithSigDataBytes();
        vm.startPrank(collector);
        IERC20(currency).approve(LENS_CONTRACTS.simpleFeeCollectModule, amount);
        lensDataToken.collect(data);
        vm.stopPrank();

        assertTrue(lensDataToken.isCollected(collector));
    }

    function test_GetCollectNFT() public {
        assertTrue(lensDataToken.getCollectNFT() == address(0));

        bytes memory data = _getActWithSigDataBytes();
        vm.startPrank(collector);
        IERC20(currency).approve(LENS_CONTRACTS.simpleFeeCollectModule, amount);
        lensDataToken.collect(data);
        vm.stopPrank();

        assertFalse(lensDataToken.getCollectNFT() == address(0));
    }

    function test_GetDataTokenOwner() public {
        assertEq(dataTokenOwner, lensDataToken.getDataTokenOwner());
    }

    function test_GetContentURI() public {
        assertEq(contentURI, lensDataToken.getContentURI());
    }

    function test_GetMetadata() public {
        DataTypes.Metadata memory metadata = lensDataToken.getMetadata();
        assertEq(metadata.profileId, dataTokenOwnerProfileId);
        assertEq(metadata.originalContract, address(LENS_CONTRACTS.lensHub));
        assertEq(metadata.collectMiddleware, LENS_CONTRACTS.collectPublicationAction);
    }

    function _createLensProfile() internal pure returns (uint256 profileId) {
        return 0x0250;
    }

    function _createDataToken() internal returns (LensDataToken) {
        bytes memory initVars = _getPostWithSigDataBytes();

        vm.prank(dataTokenOwner);
        address dataToken = dataTokenFactory.createDataToken(initVars);
        return LensDataToken(dataToken);
    }

    function _getPostWithSigDataBytes() internal view returns (bytes memory) {
        address[] memory actionModules = new address[](1);
        actionModules[0] = LENS_CONTRACTS.collectPublicationAction;

        bytes[] memory actionModulesInitDatas = new bytes[](1);
        actionModulesInitDatas[0] = _getActionModuleInitData();

        LensTypes.PostParams memory postParams = LensTypes.PostParams({
            profileId: dataTokenOwnerProfileId,
            contentURI: contentURI,
            actionModules: actionModules,
            actionModulesInitDatas: actionModulesInitDatas,
            referenceModule: address(0),
            referenceModuleInitData: new bytes(0)
        });

        LensTypes.EIP712Signature memory signature =
            _getEIP712PostSignature(postParams, dataTokenOwner, dataTokenOwnerPK);

        return abi.encode(postParams, signature);
    }

    function _getActWithSigDataBytes() internal view returns (bytes memory) {
        DataTypes.Metadata memory metadata = lensDataToken.getMetadata();
        bytes memory actionModuleData = _getActionModuleProcessData();
        LensTypes.PublicationActionParams memory actParams = LensTypes.PublicationActionParams({
            publicationActedProfileId: metadata.profileId,
            publicationActedId: metadata.pubId,
            actorProfileId: collectorProfileId,
            referrerProfileIds: new uint256[](0),
            referrerPubIds: new uint256[](0),
            actionModuleAddress: metadata.collectMiddleware,
            actionModuleData: actionModuleData
        });

        LensTypes.EIP712Signature memory signature = _getEIP712ActSignature(actParams, collector, collectorPK);

        return abi.encode(actParams, signature);
    }

    function _getActionModuleInitData() internal view returns (bytes memory) {
        LensTypes.BaseFeeCollectModuleInitData memory collectModuleInitParams = LensTypes.BaseFeeCollectModuleInitData({
            amount: amount,
            collectLimit: collectLimit,
            currency: currency,
            referralFee: 0,
            followerOnly: false,
            endTimestamp: type(uint72).max,
            recipient: dataTokenOwner
        });
        bytes memory collectModuleInitData = abi.encode(collectModuleInitParams);

        return abi.encode(LENS_CONTRACTS.simpleFeeCollectModule, collectModuleInitData);
    }

    function _getActionModuleProcessData() internal view returns (bytes memory) {
        address collectNftRecipient = collector;
        bytes memory collectData = abi.encode(currency, amount);
        return abi.encode(collectNftRecipient, collectData);
    }

    function _getEIP712PostSignature(LensTypes.PostParams memory postParams, address signer, uint256 signerPK)
        internal
        view
        returns (LensTypes.EIP712Signature memory)
    {
        uint256 nonce = LENS_CONTRACTS.lensHub.nonces(signer);
        bytes32 domainSeparator = LENS_CONTRACTS.lensHub.getDomainSeparator();
        bytes32 digest;
        {
            bytes32 hashedMessage = keccak256(
                abi.encode(
                    Typehash.POST,
                    postParams.profileId,
                    _encodeUsingEIP712Rules(postParams.contentURI),
                    _encodeUsingEIP712Rules(postParams.actionModules),
                    _encodeUsingEIP712Rules(postParams.actionModulesInitDatas),
                    postParams.referenceModule,
                    _encodeUsingEIP712Rules(postParams.referenceModuleInitData),
                    nonce,
                    deadline
                )
            );

            digest = _calculateDigest(domainSeparator, hashedMessage);
        }
        LensTypes.EIP712Signature memory signature;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPK, digest);
            signature.v = v;
            signature.r = r;
            signature.s = s;
            signature.deadline = deadline;
            signature.signer = signer;
        }
        return signature;
    }

    function _getEIP712ActSignature(
        LensTypes.PublicationActionParams memory actParams,
        address signer,
        uint256 signerPK
    ) internal view returns (LensTypes.EIP712Signature memory) {
        bytes32 domainSeparator = LENS_CONTRACTS.lensHub.getDomainSeparator();
        uint256 nonce = LENS_CONTRACTS.lensHub.nonces(signer);
        bytes32 digest;
        {
            bytes32 hashedMessage = keccak256(
                abi.encode(
                    Typehash.ACT,
                    actParams.publicationActedProfileId,
                    actParams.publicationActedId,
                    actParams.actorProfileId,
                    _encodeUsingEIP712Rules(actParams.referrerProfileIds),
                    _encodeUsingEIP712Rules(actParams.referrerPubIds),
                    actParams.actionModuleAddress,
                    _encodeUsingEIP712Rules(actParams.actionModuleData),
                    nonce,
                    deadline
                )
            );

            digest = _calculateDigest(domainSeparator, hashedMessage);
        }
        LensTypes.EIP712Signature memory signature;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPK, digest);
            signature.v = v;
            signature.r = r;
            signature.s = s;
            signature.signer = signer;
            signature.deadline = deadline;
        }
        return signature;
    }
}
