// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {ProfileNFTStorage} from "cybercontracts/src/storages/ProfileNFTStorage.sol";
import {IProfileNFTEvents} from "cybercontracts/src/interfaces/IProfileNFTEvents.sol";
import {ICyberEngineEvents} from "cybercontracts/src/interfaces/ICyberEngineEvents.sol";
import {TestIntegrationBase} from "cybercontracts/test/utils/TestIntegrationBase.sol";
import {ProfileNFT} from "cybercontracts/src/core/ProfileNFT.sol";
import {LibDeploy} from "cybercontracts/script/libraries/LibDeploy.sol";
import {CollectOnlySubscribedMw} from "cybercontracts/src/middlewares/essence/CollectOnlySubscribedMw.sol";
import {EssenceNFT} from "cybercontracts/src/core/EssenceNFT.sol";
import {DataTypes} from "cybercontracts/src/libraries/DataTypes.sol";

contract CyberBaseTest is TestIntegrationBase, IProfileNFTEvents, ICyberEngineEvents, ProfileNFTStorage {
    address namespaceOwner = alice;
    string constant LINK5_NAME = "Link5";
    string constant LINK5_SYMBOL = "L5";
    bytes32 constant LINK5_SALT = keccak256(bytes(LINK5_NAME));
    string constant BOB_ESSENCE_NAME = "Arzuros Carapace";
    string constant BOB_ESSENCE_SYMBOL = "AC";
    string constant BOB_ESSENCEMW_NAME = "Super Fan";
    string constant BOB_ESSENCEMW_SYMBOL = "SF";

    address essenceMw = address(0); //change this
    uint256 profileIdBob;
    uint256 profileIdCarly;
    ProfileNFT link5Profile;
    bytes returnData = new bytes(111);
    bytes dataBobEssence = new bytes(0);
    address link5SubBeacon;
    address link5EssBeacon;

    uint256 bobEssenceId;
    uint256 bobEssenceMWId;

    string constant CARLY_ESSENCE_1_NAME = "Malzeno Fellwing";
    string constant CARLY_ESSENCE_1_SYMBOL = "MF";
    string constant CARLY_ESSENCE_1_URL = "mf.com";
    bool constant CARLY_ESSENCE_1_TRANSFERABLE = true;
    bool constant CARLY_ESSENCE_1_DEPLOYATREGISTER = false;

    string constant CARLY_ESSENCE_2_NAME = "Nargacuga Tail";
    string constant CARLY_ESSENCE_2_SYMBOL = "NFT";
    string constant CARLY_ESSENCE_2_URL = "nt.com";
    bool constant CARLY_ESSENCE_2_TRANSFERABLE = false;
    bool constant CARLY_ESSENCE_2_DEPLOYATREGISTER = false;
    uint256 carlyFirstEssenceId;
    uint256 carlyFirstEssenceTokenId; // bob mint this
    address carlyTransferableEssenceAddr;
    uint256 carlySecondEssenceId;
    uint256 carlySecondEssenceTokenId; // bob mint this
    address carlyNontransferableEssenceAddr;

    function _setupCyberEnv() internal {
        address link5Namespace;
        (link5Namespace, link5SubBeacon, link5EssBeacon) = LibDeploy.createNamespace(
            addrs.engineProxyAddress,
            namespaceOwner,
            LINK5_NAME,
            LINK5_SYMBOL,
            LINK5_SALT,
            addrs.profileFac,
            addrs.subFac,
            addrs.essFac
        );

        link5Profile = ProfileNFT(link5Namespace);

        collectMw = new CollectOnlySubscribedMw();

        vm.expectEmit(false, false, false, true);
        emit AllowEssenceMw(address(collectMw), false, true);
        engine.allowEssenceMw(address(collectMw), true);

        // create dixon's profile
        vm.startPrank(dixon);
        vm.expectEmit(true, true, false, true);
        emit CreateProfile(dixon, 1, "dixon", "dixon'avatar", "dixon's metadata");
        vm.expectEmit(true, true, false, false);
        emit SetPrimaryProfile(dixon, 1);

        bytes memory dataDixon = new bytes(0);
        profileIdBob = link5Profile.createProfile(
            DataTypes.CreateProfileParams(dixon, "dixon", "dixon'avatar", "dixon's metadata", address(0)),
            dataDixon,
            dataDixon
        );
        vm.stopPrank();

        // create bob's profile
        vm.startPrank(bob);
        bytes memory dataBob = new bytes(0);
        profileIdBob = link5Profile.createProfile(
            DataTypes.CreateProfileParams(bob, "bob", "bob'avatar", "bob's metadata", address(0)), dataBob, dataBob
        );

        // bob registers an essence without a middleware
        vm.expectEmit(true, true, false, false);
        emit RegisterEssence(profileIdBob, 1, BOB_ESSENCE_NAME, BOB_ESSENCE_SYMBOL, "uri", essenceMw, returnData);

        bobEssenceId = link5Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileIdBob, BOB_ESSENCE_NAME, BOB_ESSENCE_SYMBOL, "uri", essenceMw, true, false
            ),
            dataBobEssence
        );

        assertEq(link5Profile.getEssenceNFTTokenURI(profileIdBob, bobEssenceId), "uri");

        //  bob register essence with collect only subscribed middleware
        vm.expectEmit(true, true, false, false);
        emit RegisterEssence(
            profileIdBob, 2, BOB_ESSENCEMW_NAME, BOB_ESSENCEMW_SYMBOL, "uriMW", address(collectMw), returnData
        );

        // register essence with collect only subscribed middleware
        bobEssenceMWId = link5Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileIdBob, BOB_ESSENCEMW_NAME, BOB_ESSENCEMW_SYMBOL, "uriMW", address(collectMw), true, false
            ),
            dataBobEssence
        );

        assertEq(link5Profile.getEssenceNFTTokenURI(profileIdBob, bobEssenceMWId), "uriMW");

        vm.stopPrank();

        // create carly's profile
        vm.startPrank(carly);
        bytes memory dataCarly = new bytes(0);
        profileIdCarly = link5Profile.createProfile(
            DataTypes.CreateProfileParams(carly, "realCarly", "carly'avatar", "carly's metadata", address(0)),
            dataCarly,
            dataCarly
        );
        // carly registers a transferable essence
        carlyFirstEssenceId = link5Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileIdCarly,
                CARLY_ESSENCE_1_NAME,
                CARLY_ESSENCE_1_SYMBOL,
                CARLY_ESSENCE_1_URL,
                address(0),
                CARLY_ESSENCE_1_TRANSFERABLE,
                CARLY_ESSENCE_1_DEPLOYATREGISTER
            ),
            new bytes(0)
        );
        // carly registers a non-transferable essence
        carlySecondEssenceId = link5Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileIdCarly,
                CARLY_ESSENCE_2_NAME,
                CARLY_ESSENCE_2_SYMBOL,
                CARLY_ESSENCE_2_URL,
                address(0),
                CARLY_ESSENCE_2_TRANSFERABLE,
                CARLY_ESSENCE_2_DEPLOYATREGISTER
            ),
            new bytes(0)
        );
        vm.stopPrank();

        // bob collects carly's essences #1
        vm.startPrank(bob);
        address essenceProxy;
        essenceProxy = getDeployedEssProxyAddress(
            link5EssBeacon,
            profileIdCarly,
            carlyFirstEssenceId,
            address(link5Profile),
            CARLY_ESSENCE_1_NAME,
            CARLY_ESSENCE_1_SYMBOL,
            CARLY_ESSENCE_1_TRANSFERABLE
        );
        carlyFirstEssenceTokenId = link5Profile.collect(
            DataTypes.CollectParams(bob, profileIdCarly, carlyFirstEssenceId), new bytes(0), new bytes(0)
        );
        carlyTransferableEssenceAddr = link5Profile.getEssenceNFT(profileIdCarly, carlyFirstEssenceId);
        assertEq(carlyTransferableEssenceAddr, essenceProxy);
        assertEq(EssenceNFT(carlyTransferableEssenceAddr).name(), CARLY_ESSENCE_1_NAME);
        assertEq(EssenceNFT(carlyTransferableEssenceAddr).symbol(), CARLY_ESSENCE_1_SYMBOL);
        assertEq(EssenceNFT(carlyTransferableEssenceAddr).isTransferable(), CARLY_ESSENCE_1_TRANSFERABLE);
        assertEq(EssenceNFT(carlyTransferableEssenceAddr).ownerOf(carlyFirstEssenceTokenId), bob);
        assertEq(EssenceNFT(carlyTransferableEssenceAddr).balanceOf(bob), 1);

        // bob collects carly's essences #2
        essenceProxy = getDeployedEssProxyAddress(
            link5EssBeacon,
            profileIdCarly,
            carlySecondEssenceId,
            address(link5Profile),
            CARLY_ESSENCE_2_NAME,
            CARLY_ESSENCE_2_SYMBOL,
            CARLY_ESSENCE_2_TRANSFERABLE
        );
        carlySecondEssenceTokenId = link5Profile.collect(
            DataTypes.CollectParams(bob, profileIdCarly, carlySecondEssenceId), new bytes(0), new bytes(0)
        );
        carlyNontransferableEssenceAddr = link5Profile.getEssenceNFT(profileIdCarly, carlySecondEssenceId);
        assertEq(carlyNontransferableEssenceAddr, essenceProxy);
        assertEq(EssenceNFT(carlyNontransferableEssenceAddr).name(), CARLY_ESSENCE_2_NAME);
        assertEq(EssenceNFT(carlyNontransferableEssenceAddr).symbol(), CARLY_ESSENCE_2_SYMBOL);
        assertEq(EssenceNFT(carlyNontransferableEssenceAddr).isTransferable(), CARLY_ESSENCE_2_TRANSFERABLE);
        assertEq(EssenceNFT(carlyNontransferableEssenceAddr).ownerOf(carlySecondEssenceTokenId), bob);
        assertEq(EssenceNFT(carlyNontransferableEssenceAddr).balanceOf(bob), 1);

        vm.stopPrank();
    }
}
