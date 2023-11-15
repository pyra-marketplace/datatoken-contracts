// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Strings} from "openzeppelin-contracts/contracts/utils/Strings.sol";
import {IProfileNFT} from "../../contracts/graph/cyber/IProfileNFT.sol";
import {CyberTypes} from "../../contracts/graph/cyber/CyberTypes.sol";
import {DataTokenHub} from "../../contracts/DataTokenHub.sol";
import {Test} from "forge-std/Test.sol";

contract CyberBaseTest is Test {
    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    struct CyberDeployedContracts {
        IProfileNFT profileNFT;
        address collectPaidMw;
        address LINK;
    }

    uint256 _forkBSCTestnet;
    CyberDeployedContracts internal CYBER_CONTRACTS;
    DataTokenHub dataTokenHub;

    function _setUp() internal {
        _forkBSCTestnet = vm.createSelectFork("bsc_testnet");

        CYBER_CONTRACTS = CyberDeployedContracts({
            profileNFT: IProfileNFT(0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271),
            collectPaidMw: 0x4e0D14e52418881511Fd8156585D4B03eEc1FF36,
            LINK: 0x84b9B910527Ad5C03A9Ca831909E21e236EA7b06
        });
    }

    function _createDataTokenHub() internal {
        dataTokenHub = new DataTokenHub();
        dataTokenHub.initialize();
    }

    function _createCyberProfile(address profileOwner) internal returns (uint256) {
        uint256 profileId = CYBER_CONTRACTS.profileNFT.createProfile(
            CyberTypes.CreateProfileParams(
                profileOwner, string.concat("profile", Strings.toString(block.number + 1)), "", "", address(0)
            ),
            new bytes(0),
            new bytes(0)
        );
        return profileId;
    }

    function _hashTypedDataV4(address addr, bytes32 structHash, string memory name, string memory version)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encodePacked("\x19\x01", _domainSeparator(name, version, addr), structHash));
    }

    function _domainSeparator(string memory name, string memory version, address addr)
        internal
        view
        returns (bytes32)
    {
        return keccak256(abi.encode(_TYPE_HASH, keccak256(bytes(name)), keccak256(bytes(version)), block.chainid, addr));
    }
}
