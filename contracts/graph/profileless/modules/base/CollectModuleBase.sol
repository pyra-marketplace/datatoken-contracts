// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IProfilelessHub} from "../../interfaces/IProfilelessHub.sol";
import {Errors} from "../../libraries/Errors.sol";

abstract contract CollectModuleBase {
    address internal immutable PROFILELESS_HUB;

    constructor(address profilelessHub) {
        if (profilelessHub == address(0)) {
            revert Errors.ZeroAddress();
        }
        PROFILELESS_HUB = profilelessHub;
    }

    modifier onlyHub() {
        if (msg.sender != PROFILELESS_HUB) {
            revert Errors.NotProfilelessHub();
        }
        _;
    }

    function _isCurrencyWhitelistedByHub(address currency) internal view returns (bool) {
        return IProfilelessHub(PROFILELESS_HUB).isCurrencyWhitelisted(currency);
    }

    function _validateDataIsExpected(bytes calldata data, address currency, uint256 amount) internal pure {
        (address decodedCurrency, uint256 decodedAmount) = abi.decode(data, (address, uint256));
        if (decodedAmount != amount || decodedCurrency != currency) {
            revert Errors.ModuleDataMismatch();
        }
    }
}
