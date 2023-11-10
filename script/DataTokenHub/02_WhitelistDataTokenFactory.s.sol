// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {IDataTokenHub} from "../../contracts/interfaces/IDataTokenHub.sol";
import {Config} from "../Config.sol";

contract WhitelistDataTokenFactory is Script, Config {
    function run(address dataTokenHub, address[] memory factories) public {
        _privateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(_privateKey);
        for (uint256 i = 0; i < factories.length; ++i) {
            if (factories[i] == address(0)) {
                continue;
            }
            IDataTokenHub(dataTokenHub).whitelistDataTokenFactory(factories[i], true);
            require(IDataTokenHub(dataTokenHub).isDataTokenFactoryWhitelisted(factories[i]));
        }
        vm.stopBroadcast();
    }
}
