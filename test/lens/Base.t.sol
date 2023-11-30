// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ILensHub} from "../../contracts/graph/lens/ILensHub.sol";
import {LensTypes} from "../../contracts/graph/lens/LensTypes.sol";
import {IProfileCreationProxy} from "../../contracts/graph/lens/IProfileCreationProxy.sol";
import {DataTokenHub} from "../../contracts/DataTokenHub.sol";
import {Test} from "forge-std/Test.sol";

contract LensBaseTest is Test {
    struct LensDeployedContracts {
        ILensHub lensHub;
        IProfileCreationProxy profileCreationProxy;
        address collectPublicationAction;
        address simpleFeeCollectModule;
        address WMATIC;
    }

    uint256 _forkPolygonMumbai;
    LensDeployedContracts internal LENS_CONTRACTS;
    DataTokenHub dataTokenHub;

    function _setUp() internal {
        _forkPolygonMumbai = vm.createSelectFork("polygon_mumbai");

        LENS_CONTRACTS = LensDeployedContracts({
            lensHub: ILensHub(0x4fbffF20302F3326B20052ab9C217C44F6480900),
            profileCreationProxy: IProfileCreationProxy(0x0554a7163C3aa423429719940FFE179F21cD83f6),
            collectPublicationAction: 0x4FdAae7fC16Ef41eAE8d8f6578d575C9d64722f2,
            simpleFeeCollectModule: 0x345Cc3A3F9127DE2C69819C2E07bB748dE6E45ee,
            WMATIC: 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889
        });
    }

    function _createDataTokenHub() internal {
        dataTokenHub = new DataTokenHub();
        dataTokenHub.initialize();
    }

    function _createLensProfile(address creator, string memory handle) internal returns (uint256) {
        address profileCreationProxyOwner = LENS_CONTRACTS.profileCreationProxy.OWNER();
        vm.prank(profileCreationProxyOwner);
        (uint256 profileId,) = LENS_CONTRACTS.profileCreationProxy.proxyCreateProfileWithHandle(
            LensTypes.CreateProfileParams({to: creator, followModule: address(0), followModuleInitData: new bytes(0)}),
            handle
        );

        return profileId;
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
