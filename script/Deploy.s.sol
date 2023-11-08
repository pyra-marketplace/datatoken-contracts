// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {Config} from "./Config.sol";
import {DeployProfilelessHub} from "./Graph/Profileless/01.DeployProfilelessHub.s.sol";
import {DeployCollectModules} from "./Graph/Profileless/02.DeployCollectModules.s.sol";
import {WhitelistCollectModules} from "./Graph/Profileless/03.WhitelistCollectModules.s.sol";
import {WhitelistCurrencys} from "./Graph/Profileless/04.WhitelistCurrencys.s.sol";
import {DeployDataTokenHub} from "./DataTokenHub/01_DeployDataTokenHub.s.sol";
import {WhitelistDataTokenFactory} from "./DataTokenHub/02_WhitelistDataTokenFactory.s.sol";
import {DeployLensDataTokenFactory} from "./DataTokenFactory/Lens/01_DeployLensDataTokenFactory.s.sol";
import {DeployCyberDataTokenFactory} from "./DataTokenFactory/Cyber/01_DeployCyberDataTokenFactory.s.sol";
import {DeployProfilelessDataTokenFactory} from
    "./DataTokenFactory/Profileless/01_DeployProfilelessDataTokenFactory.s.sol";

contract Deploy is Script, Config {
    DeployProfilelessHub deployProfilelessHub;
    DeployCollectModules deployCollectModules;
    WhitelistCollectModules whitelistCollectModules;
    WhitelistCurrencys whitelistCurrencys;

    DeployDataTokenHub deployDataTokenHub;
    DeployLensDataTokenFactory deployLensDataTokenFactory;
    DeployCyberDataTokenFactory deployCyberDataTokenFactory;
    DeployProfilelessDataTokenFactory deployProfilelessDataTokenFactory;

    WhitelistDataTokenFactory whitelistDataTokenFactory;

    function run() public {
        _setUp();

        deployProfilelessHub.run();
        address[] memory collectModules = deployCollectModules.run();
        whitelistCollectModules.run(collectModules);
        whitelistCurrencys.run();

        address dataTokenHub = deployDataTokenHub.run();
        address lensDataTokenFactory = deployLensDataTokenFactory.run(dataTokenHub);
        address cyberDataTokenFactory = deployCyberDataTokenFactory.run(dataTokenHub);
        address profilelessDataTokenFactory = deployProfilelessDataTokenFactory.run(dataTokenHub);
        address[] memory factories = new address[](3);
        factories[0] = lensDataTokenFactory;
        factories[1] = cyberDataTokenFactory;
        factories[2] = profilelessDataTokenFactory;

        whitelistDataTokenFactory.run(dataTokenHub, factories);
    }

    function _setUp() internal {
        deployProfilelessHub = new DeployProfilelessHub();
        deployCollectModules = new DeployCollectModules();
        whitelistCollectModules = new WhitelistCollectModules();
        whitelistCurrencys = new WhitelistCurrencys();

        deployDataTokenHub = new DeployDataTokenHub();

        deployLensDataTokenFactory = new DeployLensDataTokenFactory();
        deployCyberDataTokenFactory = new DeployCyberDataTokenFactory();
        deployProfilelessDataTokenFactory = new DeployProfilelessDataTokenFactory();

        whitelistDataTokenFactory = new WhitelistDataTokenFactory();
    }
}
