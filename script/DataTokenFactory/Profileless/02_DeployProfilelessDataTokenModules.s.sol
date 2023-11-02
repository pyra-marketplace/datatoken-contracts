// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {ProfilelessDataTokenFactory} from "../../../contracts/core/profileless/ProfilelessDataTokenFactory.sol";
import {LimitedFeeCollectModule} from "../../../contracts/core/profileless/modules/LimitedFeeCollectModule.sol";
import {FreeCollectModule} from "../../../contracts/core/profileless/modules/FreeCollectModule.sol";
import {LimitedTimedFeeCollectModule} from
    "../../../contracts/core/profileless/modules/LimitedTimedFeeCollectModule.sol";
import {Config} from "../../Config.sol";

contract DeployProfilelessDataTokenModules is Script, Config {
    function run(address dataTokenHub, address profilelessDataTokenFactory) public {
        _baseSetUp();
        _privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(_privateKey);
        new LimitedFeeCollectModule(dataTokenHub, profilelessDataTokenFactory);
        new FreeCollectModule(dataTokenHub, profilelessDataTokenFactory);
        new LimitedTimedFeeCollectModule(dataTokenHub, profilelessDataTokenFactory);
        vm.stopBroadcast();
    }
}
