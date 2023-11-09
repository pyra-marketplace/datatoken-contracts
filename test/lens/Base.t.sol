// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ILensHub} from "../../contracts/graph/lens/ILensHub.sol";
import {IProfileCreationProxy} from "../../contracts/graph/lens/IProfileCreationProxy.sol";
import {DataTokenHub} from "../../contracts/DataTokenHub.sol";
import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";

contract LensBaseTest is Test {
    struct LensDeployedContracts {
        ILensHub lensHub;
        address collectPublicationAction;
        address simpleFeeCollectModule;
        address WMATIC;
    }

    uint256 MUMBAI_FORK;
    LensDeployedContracts internal LENS_CONTRACTS;
    DataTokenHub dataTokenHub;

    function _setUp() internal {
        MUMBAI_FORK = vm.createSelectFork("polygon_mumbai");

        LENS_CONTRACTS = LensDeployedContracts({
            lensHub: ILensHub(0xC1E77eE73403B8a7478884915aA599932A677870),
            collectPublicationAction: 0x5FE7918C3Ef48E6C5Fd79dD22A3120a3C4967aC2,
            simpleFeeCollectModule: 0x98daD8B389417A5A7D971D7F83406Ac7c646A8e2,
            WMATIC: 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889
        });
    }

    function _createDataTokenHub() internal {
        dataTokenHub = new DataTokenHub();
        dataTokenHub.initialize();
    }

    function _getLensProfiles(address profileOwner) internal pure returns (uint256[] memory profileIds) {
        profileIds = new uint256[](1);
        profileIds[0] = 0x0250;
    }

    function _createLensProfile(address creator, string memory handle) internal view returns (uint256) {
        // vm.prank(creator);
        // profileId = lensContracts.lensHub.createProfile(
        //     LensTypes.CreateProfileData({
        //         to: creator,
        //         handle: handle,
        //         imageURI: "",
        //         followModule: address(lensContracts.approvalFollowModule),
        //         followModuleInitData: "",
        //         followNFTURI: ""
        //     })
        // );
        // (profileId, ) = LENS_CONTRACTS.profileCreationProxy.proxyCreateProfileWithHandle(
        //     LensTypes.CreateProfileParams({to: creator, followModule: address(0), followModuleInitData: new bytes(0)}),
        //     handle
        // );
        console.log("Lens protocol unable to create profile except owner");
        console.log("Please go to lens mumbai testnent hey.xyz to get a profile");

        return 0;
    }

    function _calculateDigest(bytes32 domainSeparator, bytes32 hashedMessage) internal pure returns (bytes32) {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hashedMessage));
        return digest;
    }

    function _encodeUsingEIP712Rules(bytes32[] memory bytes32Array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(bytes32Array));
    }

    function _encodeUsingEIP712Rules(string memory stringValue) internal pure returns (bytes32) {
        return keccak256(bytes(stringValue));
    }

    function _encodeUsingEIP712Rules(bytes memory bytesValue) internal pure returns (bytes32) {
        return keccak256(bytesValue);
    }

    function _encodeUsingEIP712Rules(address[] memory addressArray) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(addressArray));
    }

    function _encodeUsingEIP712Rules(bytes[] memory bytesArray) internal pure returns (bytes32) {
        bytes32[] memory bytesArrayEncodedElements = new bytes32[](bytesArray.length);
        uint256 i;
        while (i < bytesArray.length) {
            // A `bytes` type is encoded as its keccak256 hash.
            bytesArrayEncodedElements[i] = keccak256(bytesArray[i]);
            unchecked {
                ++i;
            }
        }
        // An array is encoded as the keccak256 hash of the concatenation of their encoded elements.
        return _encodeUsingEIP712Rules(bytesArrayEncodedElements);
    }

    function _encodeUsingEIP712Rules(uint256[] memory uint256Array) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(uint256Array));
    }
}
