// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {EIP712} from "openzeppelin-contracts/contracts/utils/cryptography/draft-EIP712.sol";
import {DataTypes} from "../../../libraries/DataTypes.sol";
import {Errors} from "../../../libraries/Errors.sol";

contract ProfilelessDataTokenFactoryBase is ERC721, EIP712 {
    uint256 internal _tokenIdCount = 0;
    mapping(address => uint256) public sigNonces;

    bytes32 internal constant CREATE_DATA_TOKEN_WITH_SIG_TYPEHASH = keccak256(
        bytes(
            "CreateDataTokenWithSig(string contentURI,address collectModule,bytes collectModuleInitData,uint256 nonce,uint256 deadline)"
        )
    );

    mapping(address => uint256) internal _tokenIdByDataToken;

    constructor() ERC721("Profileless Publication NFT", "PPN") EIP712("Profileless DataTokenFactory", "1") {}

    function _mintPublicationNFT(address to) internal returns (uint256) {
        _safeMint(to, _tokenIdCount);
        return _tokenIdCount++;
    }

    function getOwnerByDataToken(address dataToken) external view returns (address) {
        return ownerOf(_tokenIdByDataToken[dataToken]);
    }

    function getPubIdByDataToken(address dataToken) external view returns (uint256) {
        return _tokenIdByDataToken[dataToken];
    }

    function getDomainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _recoverSigner(bytes32 digest, DataTypes.EIP712Signature memory sig) internal view returns (address) {
        if (sig.deadline < block.timestamp) revert Errors.SignatureExpired();
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        return recoveredAddress;
    }
}
