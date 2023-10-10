// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {CyberDataTokenFactory} from "../../contracts/core/cyber/CyberDataTokenFactory.sol";
import {Config} from "../Config.sol";

contract DeployCyberDataTokenFactory is Script, Config {
    function run(address dataTokenHub) public returns (address) {
        _baseSetUp();

        if (_cyberProfileProxy != address(0)) {
            _privateKey = vm.envUint("PRIVATE_KEY");

            vm.startBroadcast(_privateKey);
            CyberDataTokenFactory factory = new CyberDataTokenFactory(_cyberProfileProxy, dataTokenHub);
            vm.stopBroadcast();

            return address(factory);
        } else {
            return address(0);
        }
    }
}
