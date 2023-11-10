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
    function run(address profilelessHub) public returns (address[] memory collectModules) {
        _privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(_privateKey);
        FreeCollectModule freeCollectModule = new FreeCollectModule(
            profilelessHub
        );
        LimitedFeeCollectModule limitedFeeCollectModule = new LimitedFeeCollectModule(
                profilelessHub
            );
        LimitedTimedFeeCollectModule limitedTimedFeeCollectModule = new LimitedTimedFeeCollectModule(
                profilelessHub
            );
        vm.stopBroadcast();

        collectModules = new address[](3);
        collectModules[0] = address(freeCollectModule);
        collectModules[1] = address(limitedFeeCollectModule);
        collectModules[2] = address(limitedTimedFeeCollectModule);

        return collectModules;
    }
}
