// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {LensTypes} from "./LensTypes.sol";

interface IProfileCreationProxy {
    function proxyCreateProfile(LensTypes.CreateProfileParams calldata createProfileParams)
        external
        returns (uint256);

    function proxyCreateProfileWithHandle(
        LensTypes.CreateProfileParams memory createProfileParams,
        string calldata handle
    ) external returns (uint256, uint256);
}
