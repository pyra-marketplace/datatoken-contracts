// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "forge-std/Script.sol";
import {Config} from "./Config.sol";
import {DeployProfilelessHub} from "./Graph/Profileless/01_DeployProfilelessHub.s.sol";
import {DeployCollectModules} from "./Graph/Profileless/02_DeployCollectModules.s.sol";
import {WhitelistCollectModules} from "./Graph/Profileless/03_WhitelistCollectModules.s.sol";
import {WhitelistCurrencys} from "./Graph/Profileless/04_WhitelistCurrencys.s.sol";
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

        address profilelessHub = deployProfilelessHub.run();
        address[] memory collectModules = deployCollectModules.run(profilelessHub);
        whitelistCollectModules.run(profilelessHub, collectModules);
        whitelistCurrencys.run(profilelessHub);

        address dataTokenHub = deployDataTokenHub.run();
        address lensDataTokenFactory = deployLensDataTokenFactory.run(dataTokenHub);
        address cyberDataTokenFactory = deployCyberDataTokenFactory.run(dataTokenHub);
        address profilelessDataTokenFactory = deployProfilelessDataTokenFactory.run(dataTokenHub, profilelessHub);
        address[] memory factories = new address[](3);
        factories[0] = lensDataTokenFactory;
        factories[1] = cyberDataTokenFactory;
        factories[2] = profilelessDataTokenFactory;

        whitelistDataTokenFactory.run(dataTokenHub, factories);

        console.log("\"%s\": \"%s\",", "DataTokenHub", dataTokenHub);

        if (lensDataTokenFactory != address(0)) {
            console.log("\"Lens\": {");
            console.log("   \"%s\": \"%s\",", "DataTokenFactory", lensDataTokenFactory);
            console.log("   \"%s\": \"%s\",", "LensHubProxy", _lensHubProxy);
            console.log("   \"%s\": \"%s\",", "CollectPublicationAction", _collectPublicationAction);
            console.log("   \"%s\": \"%s\",", "SimpleFeeCollectModule", _simpleFeeCollectModule);
            console.log("   \"%s\": \"%s\"", "MultirecipientFeeCollectModule", _multirecipientFeeCollectModule);
            console.log("},");
        }
        if (cyberDataTokenFactory != address(0)) {
            console.log("\"Cyber\": {");
            console.log("   \"%s\": \"%s\",", "DataTokenFactory", cyberDataTokenFactory);
            console.log("   \"%s\": \"%s\",", "CyberProfileProxy", _cyberProfileProxy);
            console.log("   \"%s\": \"%s\"", "CollectPaidMw", _collectPaidMw);
            console.log("},");
        }

        console.log("\"Profileless\": {");
        console.log("   \"%s\": \"%s\",", "DataTokenFactory", profilelessDataTokenFactory);
        console.log("   \"%s\": \"%s\",", "ProfilelessHub", profilelessHub);
        console.log("   \"%s\": \"%s\",", "FreeCollectModule", collectModules[0]);
        console.log("   \"%s\": \"%s\",", "LimitedFeeCollectModule", collectModules[1]);
        console.log("   \"%s\": \"%s\"", "LimitedTimedFeeCollectModule", collectModules[2]);
        console.log("}");
    }

    function _setUp() internal {
        _baseSetUp();
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
