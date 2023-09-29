// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {LensHub} from "lens-core/contracts/core/LensHub.sol";
import {FreeCollectModule} from "lens-core/contracts/core/modules/collect/FreeCollectModule.sol";
import {DataTypes as LensTypes} from "lens-core/contracts/libraries/DataTypes.sol";
import {DataTokenHub} from "../../src/DataTokenHub.sol";
import {LensDataTokenFactory} from "../../src/core/lens/LensDataTokenFactory.sol";
import {IDataToken} from "../../src/interfaces/IDataToken.sol";
import {DataTypes} from "../../src/libraries/DataTypes.sol";
import {Events} from "../../src/libraries/Events.sol";
import {Errors} from "../../src/libraries/Errors.sol";
import {Constants} from "../../src/libraries/Constants.sol";
import {LensDeployerMock, LensContracts} from "../../src/mocks/LensDeployerMock.sol";
import {EIP712Mock} from "../../src/mocks/EIP712Mock.sol";
import {Test} from "forge-std/Test.sol";

contract LensDataTokenFactoryTest is Test {
    address governor;
    address notGovernor;
    address dataTokenOwner;
    uint256 dataTokenOwnerPK;
    uint256 dataTokenOwnerProfileId;
    DataTokenHub dataTokenHub;
    FreeCollectModule collectModule;
    LensDeployerMock lensDeployer;
    address lensTreasury;
    uint256 lensTreasuryFeeRate;
    LensDataTokenFactory dataTokenFactory;
    LensContracts lensContracts;

    bytes initVars;
    bytes collectModuleInitData;

    function setUp() public {
        governor = makeAddr("governor");
        notGovernor = makeAddr("notGovernor");
        (dataTokenOwner, dataTokenOwnerPK) = makeAddrAndKey("dataTokenOwner");
        lensTreasury = makeAddr("lensTreasury");
        lensTreasuryFeeRate = 100; // 100/10000 = 1%

        vm.startPrank(governor);
        _createDataTokenHub();
        lensContracts = _createLens();

        dataTokenFactory = new LensDataTokenFactory(address(lensContracts.lensHub), address(dataTokenHub));
        dataTokenHub.whitelistDataTokenFactory(address(dataTokenFactory), true);

        collectModule = new FreeCollectModule(address(lensContracts.lensHub));

        lensContracts.lensHub.whitelistCollectModule(address(collectModule), true);
        lensContracts.lensHub.whitelistProfileCreator(dataTokenOwner, true);

        vm.stopPrank();

        lensDeployer.whitelistLens(lensContracts, governor);
        dataTokenOwnerProfileId = _createLensProfile();

        initVars = _getPostWithSigDataBytes();
    }

    function test_CreateDataToken() public {
        vm.prank(dataTokenOwner);
        address dataToken = dataTokenFactory.createDataToken(initVars);

        DataTypes.Metadata memory metadata = IDataToken(dataToken).getMetadata();
        assertEq(metadata.originalContract, address(lensContracts.lensHub));
        assertEq(metadata.profileId, dataTokenOwnerProfileId);
    }

    function test_CreateDataTokenWithSig() public {
        vm.prank(dataTokenOwner);
        address dataToken = dataTokenFactory.createDataTokenWithSig(initVars);

        DataTypes.Metadata memory metadata = IDataToken(dataToken).getMetadata();
        assertEq(metadata.originalContract, address(lensContracts.lensHub));
        assertEq(metadata.profileId, dataTokenOwnerProfileId);
    }

    function _createLens() internal returns (LensContracts memory) {
        lensDeployer = new LensDeployerMock();
        (bool success, bytes memory result) = address(lensDeployer).delegatecall(
            abi.encodeWithSelector(LensDeployerMock.deployLens.selector, address(governor), lensTreasury)
        );
        require(success, "Lens deployed failed");
        return abi.decode(result, (LensContracts));
    }

    function _createLensProfile() internal returns (uint256 profileId) {
        vm.prank(dataTokenOwner);
        profileId = lensContracts.lensHub.createProfile(
            LensTypes.CreateProfileData({
                to: dataTokenOwner,
                handle: "sdasdawqewqqw",
                imageURI: "",
                followModule: address(lensContracts.approvalFollowModule),
                followModuleInitData: "",
                followNFTURI: ""
            })
        );
    }

    function _getPostWithSigDataBytes() internal view returns (bytes memory) {
        LensTypes.PostWithSigData memory postWithSigData;

        postWithSigData.profileId = dataTokenOwnerProfileId;
        postWithSigData.contentURI = "https://dataverse-os.com";
        postWithSigData.collectModuleInitData = _getCollectModuleInitData();
        postWithSigData.collectModule = address(collectModule);
        postWithSigData.referenceModule = address(lensContracts.followerOnlyReferenceModule);
        postWithSigData.referenceModuleInitData = new bytes(0);
        postWithSigData.sig = _getEIP712PostSigData(postWithSigData, dataTokenOwner, dataTokenOwnerPK);

        return abi.encode(postWithSigData);
    }

    function _getCollectModuleInitData() internal pure returns (bytes memory) {
        bool followerOnly = false;
        return abi.encode(followerOnly);
    }

    function _getEIP712PostSigData(
        LensTypes.PostWithSigData memory postWithoutSigData,
        address signer,
        uint256 signerPK
    ) internal view returns (LensTypes.EIP712Signature memory) {
        uint256 nonce = EIP712Mock.getSigNonce(address(lensContracts.lensHub), signer);
        bytes32 domainSeparator = lensContracts.lensHub.getDomainSeparator();
        uint256 deadline = block.timestamp + 1 days;
        bytes32 digest;
        {
            bytes32 hashedMessage = keccak256(
                abi.encode(
                    EIP712Mock.POST_WITH_SIG_TYPEHASH,
                    postWithoutSigData.profileId,
                    keccak256(bytes(postWithoutSigData.contentURI)),
                    postWithoutSigData.collectModule,
                    keccak256(postWithoutSigData.collectModuleInitData),
                    postWithoutSigData.referenceModule,
                    keccak256(postWithoutSigData.referenceModuleInitData),
                    nonce,
                    deadline
                )
            );

            digest = EIP712Mock.calculateDigest(domainSeparator, hashedMessage);
        }
        LensTypes.EIP712Signature memory signature;
        {
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(signerPK, digest);
            signature.v = v;
            signature.r = r;
            signature.s = s;
        }
        signature.deadline = deadline;
        return signature;
    }

    function _createDataTokenHub() internal {
        dataTokenHub = new DataTokenHub();
        dataTokenHub.initialize();
    }
}
