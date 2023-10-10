// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {LensHub} from "lens-core/contracts/core/LensHub.sol";
import {FreeCollectModule} from "lens-core/contracts/core/modules/collect/FreeCollectModule.sol";
import {DataTypes as LensTypes} from "lens-core/contracts/libraries/DataTypes.sol";
import {DataTokenHub} from "../../contracts/DataTokenHub.sol";
import {LensDataTokenFactory} from "../../contracts/core/lens/LensDataTokenFactory.sol";
import {LensDataToken} from "../../contracts/core/lens/LensDataToken.sol";
import {IDataToken} from "../../contracts/interfaces/IDataToken.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {Errors} from "../../contracts/libraries/Errors.sol";
import {Constants} from "../../contracts/libraries/Constants.sol";
import {LensDeployerMock, LensContracts} from "../../contracts/mocks/LensDeployerMock.sol";
import {EIP712Mock} from "../../contracts/mocks/EIP712Mock.sol";
import {Test} from "forge-std/Test.sol";

contract LensDataTokenTest is Test {
    address governor;
    address dataTokenOwner;
    uint256 dataTokenOwnerPK;
    uint256 dataTokenOwnerProfileId;
    address notDataTokenOwner;
    address collector;
    uint256 collectorPK;
    DataTokenHub dataTokenHub;

    string contentURI;
    string newContentURI;

    uint256 amount; // collect amount
    uint256 balance; // balance of Currency of collector

    LensDeployerMock lensDeployer;
    address lensTreasury;
    uint16 lensTreasuryFeeRate;
    LensContracts lensContracts;
    FreeCollectModule collectModule;
    LensDataTokenFactory dataTokenFactory;
    LensDataToken dataToken;

    bytes collectModuleInitData;

    function setUp() public {
        governor = makeAddr("governor");
        (dataTokenOwner, dataTokenOwnerPK) = makeAddrAndKey("dataTokenOwner");
        notDataTokenOwner = makeAddr("notDataTokenOwner");
        (collector, collectorPK) = makeAddrAndKey("collector");
        lensTreasury = makeAddr("lensTreasury");
        contentURI = "https://dataverse-os.com";
        newContentURI = "https://github.com/dataverse-os";
        lensTreasuryFeeRate = 100; // 100/10000 = 1%
        amount = 10e8;
        balance = 10e18;

        vm.startPrank(governor);
        _createDataTokenHub();
        lensContracts = _createLens();

        dataTokenFactory = new LensDataTokenFactory(
            address(lensContracts.lensHub),
            address(dataTokenHub)
        );
        dataTokenHub.whitelistDataTokenFactory(address(dataTokenFactory), true);

        collectModule = new FreeCollectModule(address(lensContracts.lensHub));

        lensContracts.lensHub.whitelistCollectModule(address(collectModule), true);
        lensContracts.lensHub.whitelistProfileCreator(dataTokenOwner, true);
        lensContracts.moduleGlobals.setTreasuryFee(lensTreasuryFeeRate);
        lensContracts.currency.mint(collector, balance);

        vm.stopPrank();

        lensDeployer.whitelistLens(lensContracts, governor);
        dataTokenOwnerProfileId = _createLensProfile();
        dataToken = _createLensDataToken();
    }

    function test_Collect() public {
        vm.prank(collector);
        bytes memory data = _getCollectWithSigDataBytes();
        dataToken.collect(data);
    }

    function test_IsCollected() public {
        bytes memory data = _getCollectWithSigDataBytes();
        dataToken.collect(data);
        assertEq(dataToken.isCollected(collector), true);
    }

    function test_GetDataTokenOwner() public {
        assertEq(dataTokenOwner, dataToken.getDataTokenOwner());
    }

    function test_GetContentURI() public {
        assertEq(contentURI, dataToken.getContentURI());
    }

    function test_GetMetadata() public {
        DataTypes.Metadata memory metadata = dataToken.getMetadata();
        assertEq(metadata.profileId, 1);
        assertEq(metadata.originalContract, address(lensContracts.lensHub));
        assertEq(metadata.pubId, 1);
    }

    function testRevert_Collect_WhenInvalidData() public {
        bytes memory validataData = abi.encode(address(lensContracts.currency), amount);
        bytes memory data = abi.encode(validataData);

        vm.startPrank(collector);
        lensContracts.currency.approve(address(collectModule), balance);
        vm.expectRevert();
        dataToken.collect(data);
        vm.stopPrank();
    }

    function _createLensDataToken() internal returns (LensDataToken) {
        bytes memory initVars = _getPostWithSigDataBytes();

        vm.prank(dataTokenOwner);
        address lensDataToken = dataTokenFactory.createDataToken(initVars);

        return LensDataToken(lensDataToken);
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
        postWithSigData.contentURI = contentURI;
        postWithSigData.collectModuleInitData = _getCollectModuleInitData();
        postWithSigData.collectModule = address(collectModule);
        postWithSigData.referenceModule = address(lensContracts.followerOnlyReferenceModule);
        postWithSigData.referenceModuleInitData = new bytes(0);
        postWithSigData.sig = _getEIP712PostSigData(postWithSigData, dataTokenOwner, dataTokenOwnerPK);

        return abi.encode(postWithSigData);
    }

    function _getCollectWithSigDataBytes() internal view returns (bytes memory) {
        DataTypes.Metadata memory metadata = dataToken.getMetadata();
        bytes memory validateData = abi.encode(address(lensContracts.currency), amount);

        LensTypes.CollectWithSigData memory collectWithSigData;

        collectWithSigData.collector = collector;
        collectWithSigData.profileId = metadata.profileId;
        collectWithSigData.pubId = metadata.pubId;
        collectWithSigData.data = validateData;
        collectWithSigData.sig = _getEIP712CollectSigData(collectWithSigData, collector, collectorPK);

        return abi.encode(collectWithSigData);
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

    function _getEIP712CollectSigData(
        LensTypes.CollectWithSigData memory collectWithoutSigData,
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
                    EIP712Mock.COLLECT_WITH_SIG_TYPEHASH,
                    collectWithoutSigData.profileId,
                    collectWithoutSigData.pubId,
                    keccak256(bytes(collectWithoutSigData.data)),
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
