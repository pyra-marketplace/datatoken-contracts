// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {IProfilelessHub} from "../../../contracts/graph/profileless/interfaces/IProfilelessHub.sol";
import {Config} from "../../Config.sol";

contract WhitelistCollectModules is Script, Config {
    function run(address[] memory collectModules) public {
        _baseSetUp();
        _privateKey = vm.envUint("PRIVATE_KEY");

        if (_profilelessHub != address(0)) {
            vm.startBroadcast(_privateKey);
            for (uint256 i = 0; i < collectModules.length; i++) {
                IProfilelessHub(_profilelessHub).whitelistCollectModule(collectModules[i], true);
                assert(IProfilelessHub(_profilelessHub).isCollectModuleWhitelisted(collectModules[i]));
            }
            vm.stopBroadcast();
        }
    }
}
