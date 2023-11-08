// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ProfilelessTypes} from "../libraries/ProfilelessTypes.sol";

interface IProfilelessHub {
    function getDomainSeparator() external view returns (bytes32);

    function getSigNonces(address signer) external view returns (uint256);

    function getGovernor() external view returns (address);

    function setGovernor(address newGovernor) external;

    function isCurrencyWhitelisted(address currency) external view returns (bool);

    function whitelistCurrency(address currency, bool isWhitelisted) external;

    function isCollectModuleWhitelisted(address collectModule) external view returns (bool);

    function whitelistCollectModule(address collectModule, bool isWhitelisted) external;

    function getPublication(uint256 pubId) external view returns (ProfilelessTypes.Publication memory);

    function post(ProfilelessTypes.PostParams memory postParams) external returns (uint256);

    function postWithSig(
        ProfilelessTypes.PostParams memory postParams,
        ProfilelessTypes.EIP712Signature memory signature
    ) external returns (uint256);

    function collect(ProfilelessTypes.CollectParams memory collectParams) external returns (uint256);

    function collectWithSig(
        ProfilelessTypes.CollectParams memory collectParams,
        ProfilelessTypes.EIP712Signature memory signature
    ) external returns (uint256);
}
