// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {ProfilelessDataTokenFactory} from "../../../contracts/core/profileless/ProfilelessDataTokenFactory.sol";
import {Config} from "../../Config.sol";

contract DeployProfilelessDataTokenFactory is Script, Config {
    function run(address dataTokenHub) public returns (address) {
        _baseSetUp();
        _privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(_privateKey);
        ProfilelessDataTokenFactory factory = new ProfilelessDataTokenFactory(dataTokenHub);
        vm.stopBroadcast();

        return address(factory);
    }
}
