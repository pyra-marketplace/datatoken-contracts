// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library ProfilelessTypes {
    struct Publication {
        uint256 pubId;
        string contentURI;
        address collectModule;
        address collectNFT;
    }

    struct PostParams {
        string contentURI;
        address collectModule;
        bytes collectModuleInitData;
    }

    struct CollectParams {
        uint256 pubId;
        bytes collectModuleValidateData;
    }

    struct EIP712Signature {
        address signer;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }
}
