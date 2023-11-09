// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {ProfilelessHub} from "../../../contracts/graph/profileless/ProfilelessHub.sol";
import {Config} from "../../Config.sol";

contract DeployProfilelessHub is Script, Config {
    function run() public returns (address) {
        _baseSetUp();
        _privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(_privateKey);
        ProfilelessHub profilelessHub = new ProfilelessHub(vm.addr(_privateKey));
        vm.stopBroadcast();

        return address(profilelessHub);
    }
}
