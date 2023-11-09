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

    address essenceMw = address(0); //change this
    uint256 profileIdBob;
    ProfileNFT link5Profile;

    function _setupCyberEnv() internal {
        (address link5Namespace,,) = LibDeploy.createNamespace(
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
        engine.allowEssenceMw(address(collectMw), true);

        vm.startPrank(bob);
        bytes memory dataBob = new bytes(0);
        profileIdBob = link5Profile.createProfile(
            DataTypes.CreateProfileParams(bob, "bob", "bob'avatar", "bob's metadata", address(0)), dataBob, dataBob
        );
        vm.stopPrank();
    }
}
