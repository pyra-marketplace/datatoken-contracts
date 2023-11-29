// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library Typehash {
    bytes32 constant POST_WITH_SIG_TYPEHASH = keccak256(
        bytes(
            "PostWithSig(string contentURI,address collectModule,bytes collectModuleInitData,uint256 nonce,uint256 deadline)"
        )
    );

    bytes32 constant COLLECT_WITH_SIG_TYPEHASH =
        keccak256(bytes("CollectWithSig(uint256 pubId,bytes collectModuleValidateData,uint256 nonce,uint256 deadline)"));

    bytes32 constant RESTRICT_WITH_SIG_TYPEHASH =
        keccak256(bytes("RestrictWithSig(address account,bool restricted,uint256 nonce,uint256 deadline)"));
}
