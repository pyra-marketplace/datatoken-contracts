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
}
