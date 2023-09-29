// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {DataTokenHub} from "../src/DataTokenHub.sol";
import {ProfilelessDataTokenFactory} from "../src/core/profileless/ProfilelessDataTokenFactory.sol";
import {DataTokenHubMock} from "../src/mocks/DataTokenHubMock.sol";
import {IDataTokenHub} from "../src/interfaces/IDataTokenHub.sol";
import {DataTypes} from "../src/libraries/DataTypes.sol";
import {Errors} from "../src/libraries/Errors.sol";
import {Events} from "../src/libraries/Events.sol";
import {ERC1967Proxy} from "../src/upgradeability/ERC1967Proxy.sol";
import {Test} from "forge-std/Test.sol";

contract DataTokenHubTest is Test {
    ERC1967Proxy dataTokenHubProxy;

    DataTokenHub dataTokenHub;
    ProfilelessDataTokenFactory profilelessDataTokenFactory;
    address unwhitelistedDataTokenFactory;
    address governor;
    address newGovernor;
    address prevTreasury;
    address treasury;
    uint256 prevTreasuryFeeRate;
    uint256 treasuryFeeRate;

    address notGovernor;
    address dataTokenOwner;
    address originalContract;
    address dataToken;

    function setUp() public {
        governor = makeAddr("governor");
        newGovernor = makeAddr("newGovernor");

        notGovernor = makeAddr("notGovernor");
        dataTokenOwner = makeAddr("dataTokenOwner");
        originalContract = makeAddr("originalContract");
        dataToken = makeAddr("dataToken");
        unwhitelistedDataTokenFactory = makeAddr("unwhitelistedDataTokenFactory");

        vm.startPrank(governor);
        dataTokenHub = new DataTokenHub();

        dataTokenHubProxy = new ERC1967Proxy(address(dataTokenHub), new bytes(0));
        IDataTokenHub(address(dataTokenHubProxy)).initialize();
        profilelessDataTokenFactory = new ProfilelessDataTokenFactory(address(dataTokenHubProxy));

        IDataTokenHub(address(dataTokenHubProxy)).whitelistDataTokenFactory(address(profilelessDataTokenFactory), true);
        vm.stopPrank();
    }

    function test_Upgradeable() public {
        string memory version;
        address implementation;

        version = IDataTokenHub(address(dataTokenHubProxy)).version();
        implementation = dataTokenHubProxy.getImplementation();
        assertEq(implementation, address(dataTokenHub));
        assertEq(version, "1.0");

        DataTokenHubMock dataTokenHubMock = new DataTokenHubMock();
        vm.prank(governor);
        dataTokenHubProxy.upgradeTo(address(dataTokenHubMock));
        version = IDataTokenHub(address(dataTokenHubProxy)).version();
        implementation = dataTokenHubProxy.getImplementation();
        assertEq(implementation, address(dataTokenHubMock));
        assertEq(version, "2.0");
    }

    function testRevert_Upgradeable_WhenCallerNotAdmin() public {
        DataTokenHubMock dataTokenHubMock = new DataTokenHubMock();
        vm.expectRevert();
        vm.prank(notGovernor);
        dataTokenHubProxy.upgradeTo(address(dataTokenHubMock));
    }

    function testRevert_Initialize_WhenInitialized() public {
        vm.prank(governor);
        vm.expectRevert("Initializable: contract is already initialized");
        IDataTokenHub(address(dataTokenHubProxy)).initialize();
    }

    function test_RegisterDataToken() public {
        vm.expectEmit(true, true, true, true);
        emit Events.DataTokenRegistered(dataTokenOwner, originalContract, dataToken);
        vm.prank(address(profilelessDataTokenFactory));
        IDataTokenHub(address(dataTokenHubProxy)).registerDataToken(dataTokenOwner, originalContract, dataToken);

        bool isRegistered = IDataTokenHub(address(dataTokenHubProxy)).isDataTokenRegistered(dataToken);
        assertEq(isRegistered, true);
    }

    function testRevert_RegisterDataToken_WhenFactoryNotWhitelisted() public {
        vm.expectRevert(Errors.DataTokenFactoryNotWhitelisted.selector);
        vm.prank(unwhitelistedDataTokenFactory);
        IDataTokenHub(address(dataTokenHubProxy)).registerDataToken(dataTokenOwner, originalContract, dataToken);
    }

    function test_WhitelistDataTokenFactory() public {
        bool isWhitelisted;
        isWhitelisted =
            IDataTokenHub(address(dataTokenHubProxy)).isDataTokenFactoryWhitelisted(unwhitelistedDataTokenFactory);
        assertEq(isWhitelisted, false);

        vm.expectEmit(true, true, false, true);
        emit Events.DataTokenFactoryWhitelisted(unwhitelistedDataTokenFactory, true);
        vm.prank(governor);
        IDataTokenHub(address(dataTokenHubProxy)).whitelistDataTokenFactory(unwhitelistedDataTokenFactory, true);
        isWhitelisted =
            IDataTokenHub(address(dataTokenHubProxy)).isDataTokenFactoryWhitelisted(unwhitelistedDataTokenFactory);
        assertEq(isWhitelisted, true);
    }

    function testRevert_WhitelistDataTokenFactory_WhenNotGovernor() public {
        vm.expectRevert(Errors.NotGovernor.selector);
        vm.prank(notGovernor);
        IDataTokenHub(address(dataTokenHubProxy)).whitelistDataTokenFactory(unwhitelistedDataTokenFactory, true);
    }

    function test_SetGovernor() public {
        address currentGovernor = IDataTokenHub(address(dataTokenHubProxy)).getGovernor();
        assertEq(currentGovernor, governor);

        vm.expectEmit(true, true, true, true);
        emit Events.GovernorSet(governor, newGovernor, block.timestamp);
        vm.prank(governor);
        IDataTokenHub(address(dataTokenHubProxy)).setGovernor(newGovernor);

        currentGovernor = IDataTokenHub(address(dataTokenHubProxy)).getGovernor();
        assertEq(currentGovernor, newGovernor);
    }

    function testRevert_SetGovernor_WhenCallerNotGovernor() public {
        vm.expectRevert(Errors.NotGovernor.selector);
        vm.prank(notGovernor);
        IDataTokenHub(address(dataTokenHubProxy)).setGovernor(newGovernor);
    }

    function test_EmitCollected() public {
        vm.prank(address(profilelessDataTokenFactory));
        IDataTokenHub(address(dataTokenHubProxy)).registerDataToken(dataTokenOwner, originalContract, dataToken);

        address collector = makeAddr("collector");
        address collectNFT = makeAddr("collectNFT");
        uint256 tokenId = 1;

        vm.expectEmit(true, true, true, true);
        emit Events.Collected(dataToken, collector, collectNFT, tokenId);
        vm.prank(dataToken);
        IDataTokenHub(address(dataTokenHubProxy)).emitCollected(collector, collectNFT, tokenId);
    }

    function testRevert_EmitCollected_WhenDataTokenNotRegistered() public {
        address collector = makeAddr("collector");
        address collectNFT = makeAddr("collectNFT");
        uint256 tokenId = 1;

        vm.expectRevert(abi.encodeWithSelector(Errors.DataTokenNotRegistered.selector, dataToken));
        vm.prank(dataToken);
        IDataTokenHub(address(dataTokenHubProxy)).emitCollected(collector, collectNFT, tokenId);
    }
}
