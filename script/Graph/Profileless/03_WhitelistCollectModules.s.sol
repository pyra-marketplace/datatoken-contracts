// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {IProfilelessHub} from "../../../contracts/graph/profileless/interfaces/IProfilelessHub.sol";
import {Config} from "../../Config.sol";

contract WhitelistCollectModules is Script, Config {
    function run(address profilelessHub, address[] memory collectModules) public {
        _privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(_privateKey);
        for (uint256 i = 0; i < collectModules.length; i++) {
            IProfilelessHub(profilelessHub).whitelistCollectModule(collectModules[i], true);
            assert(IProfilelessHub(profilelessHub).isCollectModuleWhitelisted(collectModules[i]));
        }
        vm.stopBroadcast();
    }
}
