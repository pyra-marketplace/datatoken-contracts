// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {IProfilelessHub} from "../../../contracts/graph/profileless/interfaces/IProfilelessHub.sol";
import {FreeCollectModule} from "../../../contracts/graph/profileless/modules/FreeCollectModule.sol";
import {LimitedFeeCollectModule} from "../../../contracts/graph/profileless/modules/LimitedFeeCollectModule.sol";
import {LimitedTimedFeeCollectModule} from
    "../../../contracts/graph/profileless/modules/LimitedTimedFeeCollectModule.sol";
import {Config} from "../../Config.sol";

contract DeployCollectModules is Script, Config {
    function run() public returns (address[] memory) {
        _baseSetUp();
        _privateKey = vm.envUint("PRIVATE_KEY");

        if (_profilelessHub != address(0)) {
            vm.startBroadcast(_privateKey);
            FreeCollectModule freeCollectModule = new FreeCollectModule(_profilelessHub);
            LimitedFeeCollectModule limitedFeeCollectModule = new LimitedFeeCollectModule(_profilelessHub);
            LimitedTimedFeeCollectModule limitedTimedFeeCollectModule =
                new LimitedTimedFeeCollectModule(_profilelessHub);
            vm.stopBroadcast();

            address[] memory collectModules = new address[](3);
            collectModules[0] = address(freeCollectModule);
            collectModules[1] = address(limitedFeeCollectModule);
            collectModules[2] = address(limitedTimedFeeCollectModule);

            return collectModules;
        }
    }
}
