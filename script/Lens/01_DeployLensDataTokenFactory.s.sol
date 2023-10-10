// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {LensDataTokenFactory} from "../../contracts/core/lens/LensDataTokenFactory.sol";
import {Config} from "../Config.sol";

contract DeployLensDataTokenFactory is Script, Config {
    function run(address dataTokenHub) public returns (address) {
        _baseSetUp();
        if (_lensHubProxy != address(0)) {
            _privateKey = vm.envUint("PRIVATE_KEY");

            vm.startBroadcast(_privateKey);
            LensDataTokenFactory factory = new LensDataTokenFactory(_lensHubProxy, dataTokenHub);
            vm.stopBroadcast();

            return address(factory);
        } else {
            return address(0);
        }
    }
}
