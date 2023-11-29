// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {ProfilelessHub} from "../../contracts/graph/profileless/ProfilelessHub.sol";
import {ProfilelessTypes} from "../../contracts/graph/profileless/libraries/ProfilelessTypes.sol";
import {LimitedFeeCollectModule} from "../../contracts/graph/profileless/modules/LimitedFeeCollectModule.sol";
import {Typehash} from "../../contracts/graph/profileless/libraries/Typehash.sol";
import {CurrencyMock} from "../../contracts/mocks/CurrencyMock.sol";
import {Test} from "forge-std/Test.sol";

contract ProfilelessBaseTest is Test {
    address public governor;
    address public notGovernor;
    address public pubOwner;
    uint256 public pubOwnerPK;
    address public collector;
    uint256 public collectorPK;

    ProfilelessHub profilelessHub;

    string public contentURI;
    LimitedFeeCollectModule public collectModule;
    uint256 public collectLimit;
    uint256 public amount;
    CurrencyMock public currency;

    function _setUp() internal {
        governor = makeAddr("governor");
        notGovernor = makeAddr("notGovernor");
        (pubOwner, pubOwnerPK) = makeAddrAndKey("pubOwnerPK");
        (collector, collectorPK) = makeAddrAndKey("collectorPK");

        contentURI = "https://dataverse-os.com";
        collectLimit = 10000;
        amount = 1e8;

        vm.startPrank(governor);
        currency = new CurrencyMock("Test Currency", "TC");
        currency.mint(collector, 100 ether);
        profilelessHub = new ProfilelessHub(governor);
        collectModule = new LimitedFeeCollectModule(address(profilelessHub));
        profilelessHub.whitelistCollectModule(address(collectModule), true);
        profilelessHub.whitelistCurrency(address(currency), true);
        vm.stopPrank();
    }

    function _getEIP721PostSignature(ProfilelessTypes.PostParams memory postParams, address signer, uint256 signerPK)
        internal
        view
        returns (ProfilelessTypes.EIP712Signature memory)
    {
        uint256 nonce = profilelessHub.getSigNonces(signer);
        bytes32 domainSeparator = profilelessHub.getDomainSeparator();
        uint256 deadline = block.timestamp + 1 days;
        bytes32 digest;
        {
            bytes32 hashedMessage = keccak256(
                abi.encode(
                    Typehash.POST_WITH_SIG_TYPEHASH,
                    keccak256(bytes(postParams.contentURI)),
                    postParams.collectModule,
                    keccak256(bytes(postParams.collectModuleInitData)),
                    nonce,
                    deadline
                )
            );

            digest = _calculateDigest(domainSeparator, hashedMessage);
        }
        ProfilelessTypes.EIP712Signature memory signature;
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

    function _getEIP721CollectSignature(
        ProfilelessTypes.CollectParams memory collectParams,
        address signer,
        uint256 signerPK
    ) internal view returns (ProfilelessTypes.EIP712Signature memory) {
        uint256 nonce = profilelessHub.getSigNonces(signer);
        bytes32 domainSeparator = profilelessHub.getDomainSeparator();
        uint256 deadline = block.timestamp + 1 days;
        bytes32 digest;
        {
            bytes32 hashedMessage = keccak256(
                abi.encode(
                    Typehash.COLLECT_WITH_SIG_TYPEHASH,
                    collectParams.pubId,
                    keccak256(bytes(collectParams.collectModuleValidateData)),
                    nonce,
                    deadline
                )
            );

            digest = _calculateDigest(domainSeparator, hashedMessage);
        }
        ProfilelessTypes.EIP712Signature memory signature;
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

    function _getEIP721RestrictSignature(
        ProfilelessTypes.RestrictParams memory restrictParams,
        address signer,
        uint256 signerPK
    ) internal view returns (ProfilelessTypes.EIP712Signature memory) {
        uint256 nonce = profilelessHub.getSigNonces(signer);
        bytes32 domainSeparator = profilelessHub.getDomainSeparator();
        uint256 deadline = block.timestamp + 1 days;
        bytes32 digest;
        {
            bytes32 hashedMessage = keccak256(
                abi.encode(
                    Typehash.RESTRICT_WITH_SIG_TYPEHASH,
                    restrictParams.account,
                    restrictParams.restricted,
                    nonce,
                    deadline
                )
            );

            digest = _calculateDigest(domainSeparator, hashedMessage);
        }
        ProfilelessTypes.EIP712Signature memory signature;
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

    function _calculateDigest(bytes32 domainSeparator, bytes32 hashedMessage) internal pure returns (bytes32) {
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, hashedMessage));
        return digest;
    }
}
