// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {ProfilelessDataTokenFactory} from "../../contracts/core/profileless/ProfilelessDataTokenFactory.sol";
import {FeeCollectModule} from "../../contracts/core/profileless/modules/FeeCollectModule.sol";
import {FreeCollectModule} from "../../contracts/core/profileless/modules/FreeCollectModule.sol";
import {LimitedTimedFeeCollectModule} from "../../contracts/core/profileless/modules/LimitedTimedFeeCollectModule.sol";
import {Config} from "../Config.sol";

contract DeployProfilelessDataTokenModules is Script, Config {
    function run(address dataTokenHub, address profilelessDataTokenFactory) public {
        _baseSetUp();
        _privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(_privateKey);
        new FeeCollectModule(dataTokenHub, profilelessDataTokenFactory);
        new FreeCollectModule(dataTokenHub, profilelessDataTokenFactory);
        new LimitedTimedFeeCollectModule(dataTokenHub, profilelessDataTokenFactory);
        vm.stopBroadcast();
    }
}
