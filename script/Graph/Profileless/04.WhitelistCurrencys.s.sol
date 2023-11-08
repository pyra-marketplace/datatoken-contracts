// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {IProfilelessHub} from "../../../contracts/graph/profileless/interfaces/IProfilelessHub.sol";
import {Config} from "../../Config.sol";

contract WhitelistCurrencys is Script, Config {
    function run() public {
        _baseSetUp();
        _privateKey = vm.envUint("PRIVATE_KEY");

        if (_profilelessHub != address(0)) {
            vm.startBroadcast(_privateKey);
            for (uint256 i = 0; i < _currencys.length; i++) {
                IProfilelessHub(_profilelessHub).whitelistCurrency(_currencys[i], true);
                assert(IProfilelessHub(_profilelessHub).isCurrencyWhitelisted(_currencys[i]));
            }
            vm.stopBroadcast();
        }
    }
}
