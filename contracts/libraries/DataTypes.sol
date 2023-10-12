// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library DataTypes {
    struct Metadata {
        address originalContract; // Cyber: profileNFT; Lens: lensHub
        uint256 profileId;
        uint256 pubId;
        address collectModule;
    }

    struct ProfilelessPostData {
        string contentURI;
        address collectModule;
        bytes collectModuleInitData;
    }

    struct ProfilelessPostDataSigParams {
        address dataTokenCreator;
        EIP712Signature sig;
    }

    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }
}
