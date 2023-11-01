// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LensTypes} from "../../contracts/vendor/lens/LensTypes.sol";
import {Typehash} from "../../contracts/vendor/lens/Typehash.sol";
import {ICollectPublicationAction} from "../../contracts/vendor/lens/ICollectPublicationAction.sol";
import {LensDataTokenFactory} from "../../contracts/core/lens/LensDataTokenFactory.sol";
import {IDataToken} from "../../contracts/interfaces/IDataToken.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {Events} from "../../contracts/libraries/Events.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";
import {Test} from "forge-std/Test.sol";
import {LensBaseTest} from "./Base.t.sol";

contract LensDataTokenTest is Test, LensBaseTest {
    address governor;
    address notGovernor;
    address dataTokenOwner;
    uint256 dataTokenOwnerPK;
    uint256 dataTokenOwnerProfileId;
    LensDataTokenFactory dataTokenFactory;

    string contentURI;
    address currency;
    uint160 amount;
    uint96 collectLimit;
    uint256 deadline;

    bytes initVars;

    function setUp() public {
        _setUp();
        governor = makeAddr("governor");
        notGovernor = makeAddr("notGovernor");
        dataTokenOwnerPK = vm.envUint("PRIVATE_KEY");
        dataTokenOwner = vm.addr(dataTokenOwnerPK);
        contentURI = "https://dataverse-os.com";
        currency = LENS_CONTRACTS.WMATIC;
        amount = 10;
        collectLimit = type(uint96).max;
        deadline = block.timestamp + 1 days;

        vm.startPrank(governor);
        _createDataTokenHub();

        dataTokenFactory = new LensDataTokenFactory(address(dataTokenHub), address(LENS_CONTRACTS.lensHub));
        dataTokenHub.whitelistDataTokenFactory(address(dataTokenFactory), true);
        vm.stopPrank();

        dataTokenOwnerProfileId = _createLensProfile();
        initVars = _getPostWithSigDataBytes();
    }

    function test_CreateDataToken() public {
        vm.prank(dataTokenOwner);
        address dataToken = dataTokenFactory.createDataToken(initVars);

        DataTypes.Metadata memory metadata = IDataToken(dataToken).getMetadata();
        assertEq(metadata.originalContract, address(LENS_CONTRACTS.lensHub));
        assertEq(metadata.profileId, dataTokenOwnerProfileId);
        assertEq(metadata.collectMiddleware, LENS_CONTRACTS.collectPublicationAction);
        ICollectPublicationAction.CollectData memory collectData = ICollectPublicationAction(
            LENS_CONTRACTS.collectPublicationAction
        ).getCollectData(metadata.profileId, metadata.pubId);
        assertEq(collectData.collectNFT, address(0));
        assertEq(collectData.collectModule, LENS_CONTRACTS.simpleFeeCollectModule);
    }

    function test_CreateDataTokenWithSig() public {
        vm.prank(dataTokenOwner);
        address dataToken = dataTokenFactory.createDataTokenWithSig(initVars);

        DataTypes.Metadata memory metadata = IDataToken(dataToken).getMetadata();
        assertEq(metadata.originalContract, address(LENS_CONTRACTS.lensHub));
        assertEq(metadata.profileId, dataTokenOwnerProfileId);
        assertEq(metadata.collectMiddleware, LENS_CONTRACTS.collectPublicationAction);
        ICollectPublicationAction.CollectData memory collectData = ICollectPublicationAction(
            LENS_CONTRACTS.collectPublicationAction
        ).getCollectData(metadata.profileId, metadata.pubId);
        assertEq(collectData.collectNFT, address(0));
        assertEq(collectData.collectModule, LENS_CONTRACTS.simpleFeeCollectModule);
    }

    function _createLensProfile() internal pure returns (uint256 profileId) {
        // vm.prank(dataTokenOwner);
        // profileId = lensContracts.lensHub.createProfile(
        //     LensTypes.CreateProfileData({
        //         to: dataTokenOwner,
        //         handle: "sdasdawqewqqw",
        //         imageURI: "",
        //         followModule: address(lensContracts.approvalFollowModule),
        //         followModuleInitData: "",
        //         followNFTURI: ""
        //     })
        // );
        // (profileId, ) = LENS_CONTRACTS.profileCreationProxy.proxyCreateProfileWithHandle(
        //     LensTypes.CreateProfileParams({to: dataTokenOwner, followModule: address(0), followModuleInitData: new bytes(0)}),
        //     "sdasdawqewqqw"
        // );
        return 0x0250;
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
}
