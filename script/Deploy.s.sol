// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {Config} from "./Config.sol";
import {DeployDataTokenHub} from "./DataTokenHub/01_DeployDataTokenHub.s.sol";
import {DeployLensDataTokenFactory} from "./Lens/01_DeployLensDataTokenFactory.s.sol";
import {DeployCyberDataTokenFactory} from "./Cyber/01_DeployCyberDataTokenFactory.s.sol";
import {DeployProfilelessDataTokenFactory} from "./Profileless/01_DeployProfilelessDataTokenFactory.s.sol";
import {DeployProfilelessDataTokenModules} from "./Profileless/02_DeployProfilelessDataTokenModules.s.sol";
import {WhitelistDataTokenFactory} from "./DataTokenHub/02_WhitelistDataTokenFactory.s.sol";

contract Deploy is Script, Config {
    DeployDataTokenHub deployDataTokenHub;
    DeployLensDataTokenFactory deployLensDataTokenFactory;
    DeployCyberDataTokenFactory deployCyberDataTokenFactory;
    DeployProfilelessDataTokenFactory deployProfilelessDataTokenFactory;
    DeployProfilelessDataTokenModules deployProfilelessDataTokenModules;

    WhitelistDataTokenFactory whitelistDataTokenFactory;

    function run() public {
        _setUp();
        address dataTokenHub = deployDataTokenHub.run();

        address lensDataTokenFactory = deployLensDataTokenFactory.run(dataTokenHub);
        address cyberDataTokenFactory = deployCyberDataTokenFactory.run(dataTokenHub);
        address profilelessDataTokenFactory = deployProfilelessDataTokenFactory.run(dataTokenHub);

        address[] memory factories = new address[](3);
        factories[0] = lensDataTokenFactory;
        factories[1] = cyberDataTokenFactory;
        factories[2] = profilelessDataTokenFactory;

        whitelistDataTokenFactory.run(dataTokenHub, factories);

        deployProfilelessDataTokenModules.run(dataTokenHub, profilelessDataTokenFactory);
    }

    function _setUp() internal {
        deployDataTokenHub = new DeployDataTokenHub();

        deployLensDataTokenFactory = new DeployLensDataTokenFactory();
        deployCyberDataTokenFactory = new DeployCyberDataTokenFactory();
        deployProfilelessDataTokenFactory = new DeployProfilelessDataTokenFactory();

        deployProfilelessDataTokenModules = new DeployProfilelessDataTokenModules();

        whitelistDataTokenFactory = new WhitelistDataTokenFactory();
    }
}
