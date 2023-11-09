// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ProfilelessHub} from "../../../../contracts/graph/profileless/ProfilelessHub.sol";
import {
    LimitedTimedFeeCollectModule,
    ProfilePublicationData
} from "../../../../contracts/graph/profileless/modules/LimitedTimedFeeCollectModule.sol";
import {CurrencyMock} from "../../../../contracts/mocks/CurrencyMock.sol";
import {Test} from "forge-std/Test.sol";

contract LimitedTimedFeeCollectModuleTest is Test {
    error CollectExpired();

    address governor;
    address profilelessHub;
    address collector;
    LimitedTimedFeeCollectModule limitedTimedFeeCollectModule;

    uint256 collectLimit;
    uint256 amount;
    CurrencyMock currency;
    address recipient;
    uint40 endTimestamp;

    function setUp() public {
        governor = makeAddr("governor");
        collector = makeAddr("collector");

        ProfilelessHub profilelessHubInstance = new ProfilelessHub(governor);
        profilelessHub = address(profilelessHubInstance);

        limitedTimedFeeCollectModule = new LimitedTimedFeeCollectModule(profilelessHub);

        currency = new CurrencyMock("Test Currency", "TC");
        currency.mint(collector, 100 ether);

        vm.prank(governor);
        profilelessHubInstance.whitelistCurrency(address(currency), true);

        collectLimit = 2;
        amount = 1e8;
        recipient = makeAddr("recipient");
        endTimestamp = uint40(block.timestamp + 1 days);
    }

    function test_InitializePublicationCollectModule() public {
        uint256 pubId = 0;
        bytes memory initData = abi.encode(collectLimit, amount, address(currency), recipient, endTimestamp);

        vm.prank(profilelessHub);
        limitedTimedFeeCollectModule.initializePublicationCollectModule(pubId, initData);

        ProfilePublicationData memory publicationData = limitedTimedFeeCollectModule.getPublicationData(0);
        assertEq(publicationData.collectLimit, collectLimit);
        assertEq(publicationData.currentCollects, 0);
        assertEq(publicationData.amount, amount);
        assertEq(publicationData.currency, address(currency));
        assertEq(publicationData.recipient, recipient);
        assertEq(publicationData.endTimestamp, endTimestamp);
    }

    function test_ProcessCollect() public {
        uint256 pubId = 0;
        bytes memory initData = abi.encode(collectLimit, amount, address(currency), recipient, endTimestamp);
        bytes memory validateData = abi.encode(address(currency), amount);

        vm.prank(collector);
        currency.approve(address(limitedTimedFeeCollectModule), amount);

        vm.startPrank(profilelessHub);
        limitedTimedFeeCollectModule.initializePublicationCollectModule(pubId, initData);
        limitedTimedFeeCollectModule.processCollect(pubId, collector, validateData);
        vm.stopPrank();

        ProfilePublicationData memory publicationData = limitedTimedFeeCollectModule.getPublicationData(0);
        assertEq(publicationData.currentCollects, 1);

        assertEq(currency.balanceOf(collector), 100 ether - amount);
        assertEq(currency.balanceOf(recipient), amount);
    }

    function testRevert_ProcessCollect_WhenCollectExpired() public {
        uint256 pubId = 0;
        bytes memory initData = abi.encode(collectLimit, amount, address(currency), recipient, endTimestamp);
        bytes memory validateData = abi.encode(address(currency), amount);

        vm.prank(collector);
        currency.approve(address(limitedTimedFeeCollectModule), amount);

        vm.prank(profilelessHub);
        limitedTimedFeeCollectModule.initializePublicationCollectModule(pubId, initData);

        vm.expectRevert(CollectExpired.selector);
        vm.warp(endTimestamp + 1 days);
        vm.prank(profilelessHub);
        limitedTimedFeeCollectModule.processCollect(pubId, collector, validateData);
    }
}
