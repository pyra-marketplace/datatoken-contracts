// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import {ModuleGlobals} from "lens-core/contracts/core/modules/ModuleGlobals.sol";
import {LensHub} from "lens-core/contracts/core/LensHub.sol";
import {FollowNFT} from "lens-core/contracts/core/FollowNFT.sol";
import {CollectNFT} from "lens-core/contracts/core/CollectNFT.sol";

import {TransparentUpgradeableProxy} from "lens-core/contracts/upgradeability/TransparentUpgradeableProxy.sol";

import {FeeCollectModule} from "lens-core/contracts/core/modules/collect/FeeCollectModule.sol";
import {LimitedFeeCollectModule} from "lens-core/contracts/core/modules/collect/LimitedFeeCollectModule.sol";
import {TimedFeeCollectModule} from "lens-core/contracts/core/modules/collect/TimedFeeCollectModule.sol";
import {LimitedTimedFeeCollectModule} from "lens-core/contracts/core/modules/collect/LimitedTimedFeeCollectModule.sol";
import {RevertCollectModule} from "lens-core/contracts/core/modules/collect/RevertCollectModule.sol";
import {FreeCollectModule} from "lens-core/contracts/core/modules/collect/FreeCollectModule.sol";

import {FeeFollowModule} from "lens-core/contracts/core/modules/follow/FeeFollowModule.sol";
import {ProfileFollowModule} from "lens-core/contracts/core/modules/follow/ProfileFollowModule.sol";
import {RevertFollowModule} from "lens-core/contracts/core/modules/follow/RevertFollowModule.sol";
import {ApprovalFollowModule} from "lens-core/contracts/core/modules/follow/ApprovalFollowModule.sol";

import {FollowerOnlyReferenceModule} from "lens-core/contracts/core/modules/reference/FollowerOnlyReferenceModule.sol";

import {LensPeriphery} from "lens-core/contracts/misc/LensPeriphery.sol";
import {UIDataProvider} from "lens-core/contracts/misc/UIDataProvider.sol";
import {ProfileCreationProxy} from "lens-core/contracts/misc/ProfileCreationProxy.sol";

import {DataTypes} from "lens-core/contracts/libraries/DataTypes.sol";

import {CurrencyMock} from "./CurrencyMock.sol";

import "forge-std/Test.sol";

struct LensContracts {
    ModuleGlobals moduleGlobals;
    LensHub lensHubImpl;
    FollowNFT followNFT;
    CollectNFT collectNFT;
    TransparentUpgradeableProxy proxy;
    LensHub lensHub;
    LensPeriphery lensPeriphery;
    CurrencyMock currency;
    FeeCollectModule feeCollectModule;
    LimitedFeeCollectModule limitedFeeCollectModule;
    TimedFeeCollectModule timedFeeCollectModule;
    LimitedTimedFeeCollectModule limitedTimedFeeCollectModule;
    RevertCollectModule revertCollectModule;
    FreeCollectModule freeCollectModule;
    FeeFollowModule feeFollowModule;
    ProfileFollowModule profileFollowModule;
    RevertFollowModule revertFollowModule;
    ApprovalFollowModule approvalFollowModule;
    FollowerOnlyReferenceModule followerOnlyReferenceModule;
    UIDataProvider uiDataProvider;
    ProfileCreationProxy profileCreationProxy;
}

contract LensDeployerMock is Test {
    uint16 constant TREASURY_FEE_BPS = 50;
    string constant LENS_HUB_NFT_NAME = "Lens Protocol Profiles";
    string constant LENS_HUB_NFT_SYMBOL = "LPP";

    function deployLens(address governance, address treasury) public returns (LensContracts memory contracts) {
        require(governance != address(0), "Governance address not set!");
        require(treasury != address(0), "Treasury address not set!");

        contracts.moduleGlobals = new ModuleGlobals(governance, treasury, TREASURY_FEE_BPS);

        address deployer = address(this);

        uint256 deployerNonce = vm.getNonce(deployer);

        uint256 followNFTNonce = deployerNonce + 1;
        uint256 collectNFTNonce = deployerNonce + 2;
        uint256 hubProxyNonce = deployerNonce + 3;

        address followNFTImplAddress = addressFrom(deployer, followNFTNonce);
        address collectNFTImplAddress = addressFrom(deployer, collectNFTNonce);
        address hubProxyAddress = addressFrom(deployer, hubProxyNonce);

        contracts.lensHubImpl = new LensHub(followNFTImplAddress, collectNFTImplAddress);

        contracts.followNFT = new FollowNFT(hubProxyAddress);
        assertEq(followNFTImplAddress, address(contracts.followNFT));

        contracts.collectNFT = new CollectNFT(hubProxyAddress);
        assertEq(collectNFTImplAddress, address(contracts.collectNFT));

        contracts.proxy = new TransparentUpgradeableProxy(
            address(contracts.lensHubImpl),
            msg.sender,
            abi.encodeWithSelector(
                LensHub.initialize.selector,
                LENS_HUB_NFT_NAME,
                LENS_HUB_NFT_SYMBOL,
                governance
            )
        );
        assertEq(hubProxyAddress, address(contracts.proxy));

        contracts.lensHub = LensHub(address(contracts.proxy));

        contracts.lensPeriphery = new LensPeriphery(contracts.lensHub);

        contracts.currency = new CurrencyMock("Currency-Mock", "CUR");

        address lensHubAddress = address(contracts.lensHub);
        address moduleGlobalsAddress = address(contracts.moduleGlobals);

        contracts.feeCollectModule = new FeeCollectModule(lensHubAddress, moduleGlobalsAddress);
        contracts.limitedFeeCollectModule = new LimitedFeeCollectModule(
            lensHubAddress,
            moduleGlobalsAddress
        );
        contracts.timedFeeCollectModule = new TimedFeeCollectModule(
            lensHubAddress,
            moduleGlobalsAddress
        );
        contracts.limitedTimedFeeCollectModule = new LimitedTimedFeeCollectModule(
            lensHubAddress,
            moduleGlobalsAddress
        );
        contracts.revertCollectModule = new RevertCollectModule();
        contracts.freeCollectModule = new FreeCollectModule(lensHubAddress);

        contracts.feeFollowModule = new FeeFollowModule(lensHubAddress, moduleGlobalsAddress);
        contracts.profileFollowModule = new ProfileFollowModule(lensHubAddress);
        contracts.revertFollowModule = new RevertFollowModule(lensHubAddress);
        contracts.approvalFollowModule = new ApprovalFollowModule(lensHubAddress);

        contracts.followerOnlyReferenceModule = new FollowerOnlyReferenceModule(lensHubAddress);

        contracts.uiDataProvider = new UIDataProvider(contracts.lensHub);

        contracts.profileCreationProxy = new ProfileCreationProxy(msg.sender, contracts.lensHub);
    }

    function whitelistLens(LensContracts calldata contracts, address governance) external {
        vm.startPrank(governance);
        contracts.lensHub.whitelistCollectModule(address(contracts.feeCollectModule), true);
        contracts.lensHub.whitelistCollectModule(address(contracts.limitedFeeCollectModule), true);
        contracts.lensHub.whitelistCollectModule(address(contracts.timedFeeCollectModule), true);
        contracts.lensHub.whitelistCollectModule(address(contracts.limitedTimedFeeCollectModule), true);
        contracts.lensHub.whitelistCollectModule(address(contracts.revertCollectModule), true);
        contracts.lensHub.whitelistCollectModule(address(contracts.freeCollectModule), true);

        contracts.lensHub.whitelistFollowModule(address(contracts.feeFollowModule), true);
        contracts.lensHub.whitelistFollowModule(address(contracts.profileFollowModule), true);
        contracts.lensHub.whitelistFollowModule(address(contracts.revertFollowModule), true);
        contracts.lensHub.whitelistFollowModule(address(contracts.approvalFollowModule), true);

        contracts.lensHub.whitelistReferenceModule(address(contracts.followerOnlyReferenceModule), true);

        contracts.moduleGlobals.whitelistCurrency(address(contracts.currency), true);

        contracts.lensHub.whitelistProfileCreator(address(contracts.profileCreationProxy), true);

        contracts.lensHub.setState(DataTypes.ProtocolState.Unpaused);
        vm.stopPrank();
    }

    function addressFrom(address _origin, uint256 _nonce) internal pure returns (address _address) {
        bytes memory data;
        if (_nonce == 0x00) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, bytes1(0x80));
        } else if (_nonce <= 0x7f) {
            data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), _origin, uint8(_nonce));
        } else if (_nonce <= 0xff) {
            data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), _origin, bytes1(0x81), uint8(_nonce));
        } else if (_nonce <= 0xffff) {
            data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), _origin, bytes1(0x82), uint16(_nonce));
        } else if (_nonce <= 0xffffff) {
            data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), _origin, bytes1(0x83), uint24(_nonce));
        } else {
            data = abi.encodePacked(bytes1(0xda), bytes1(0x94), _origin, bytes1(0x84), uint32(_nonce));
        }
        bytes32 hash = keccak256(data);
        assembly {
            mstore(0, hash)
            _address := mload(0)
        }
    }
}
