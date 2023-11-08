// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

library CyberTypes {
    struct RegisterEssenceParams {
        uint256 profileId;
        string name;
        string symbol;
        string essenceTokenURI;
        address essenceMw;
        bool transferable;
        bool deployAtRegister;
    }

    struct CollectParams {
        address collector;
        uint256 profileId;
        uint256 essenceId;
    }

    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }
}
