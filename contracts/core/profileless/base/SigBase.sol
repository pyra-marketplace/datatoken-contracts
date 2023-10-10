// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import {EIP712} from "openzeppelin-contracts/contracts/utils/cryptography/draft-EIP712.sol";
import {DataTypes} from "../../../libraries/DataTypes.sol";
import {Errors} from "../../../libraries/Errors.sol";

abstract contract SigBase is EIP712 {
    mapping(address => uint256) public sigNonces;

    bytes32 internal constant CREATE_DATA_TOKEN_WITH_SIG_TYPEHASH = keccak256(
        bytes(
            "CreateDataTokenWithSig(string contentURI,address collectModule,bytes collectModuleInitData,uint256 nonce,uin256 deadline)"
        )
    );

    constructor(string memory name, string memory version) EIP712(name, version) {}

    function getDomainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function _recoverSigner(bytes32 digest, DataTypes.EIP712Signature memory sig) internal view returns (address) {
        if (sig.deadline < block.timestamp) revert Errors.SignatureExpired();
        address recoveredAddress = ecrecover(digest, sig.v, sig.r, sig.s);
        return recoveredAddress;
    }
}
