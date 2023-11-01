// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library DataTypes {
    enum GraphType {
        Lens,
        Cyber,
        Profileless
    }

    struct Metadata {
        address originalContract;
        uint256 profileId;
        uint256 pubId;
        address collectMiddleware;
    }

    struct LensContracts {
        address lensHub;
        address collectPublicationAction;
    }

    struct CyberContracts {
        address profileNFT;
    }

    struct PostParams {
        string contentURI;
        address collectModule;
        bytes collectModuleInitData;
    }

    struct EIP712Signature {
        address signer;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }
}
