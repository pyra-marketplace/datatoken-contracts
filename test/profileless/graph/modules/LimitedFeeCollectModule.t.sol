// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ProfilelessHub} from "../../../../contracts/graph/profileless/ProfilelessHub.sol";
import {
    LimitedFeeCollectModule,
    ProfilePublicationData
} from "../../../../contracts/graph/profileless/modules/LimitedFeeCollectModule.sol";
import {CurrencyMock} from "../../../../contracts/mocks/CurrencyMock.sol";
import {Test} from "forge-std/Test.sol";

contract LimitedFeeCollectModuleTest is Test {
    address governor;
    address profilelessHub;
    address collector;
    LimitedFeeCollectModule limitedFeeCollectModule;

    uint256 collectLimit;
    uint256 amount;
    CurrencyMock currency;
    address recipient;

    function setUp() public {
        governor = makeAddr("governor");
        collector = makeAddr("collector");

        ProfilelessHub profilelessHubInstance = new ProfilelessHub(governor);
        profilelessHub = address(profilelessHubInstance);

        limitedFeeCollectModule = new LimitedFeeCollectModule(profilelessHub);

        currency = new CurrencyMock("Test Currency", "TC");
        currency.mint(collector, 100 ether);

        vm.prank(governor);
        profilelessHubInstance.whitelistCurrency(address(currency), true);

        collectLimit = 2;
        amount = 1e8;
        recipient = makeAddr("recipient");
    }

    function test_InitializePublicationCollectModule() public {
        uint256 pubId = 0;
        bytes memory initData = abi.encode(collectLimit, amount, address(currency), recipient);

        vm.prank(profilelessHub);
        limitedFeeCollectModule.initializePublicationCollectModule(pubId, initData);

        ProfilePublicationData memory publicationData = limitedFeeCollectModule.getPublicationData(0);
        assertEq(publicationData.collectLimit, collectLimit);
        assertEq(publicationData.currentCollects, 0);
        assertEq(publicationData.amount, amount);
        assertEq(publicationData.currency, address(currency));
        assertEq(publicationData.recipient, recipient);
    }

    function test_ProcessCollect() public {
        uint256 pubId = 0;
        bytes memory initData = abi.encode(collectLimit, amount, address(currency), recipient);
        bytes memory validateData = abi.encode(address(currency), amount);

        vm.prank(collector);
        currency.approve(address(limitedFeeCollectModule), amount);

        vm.startPrank(profilelessHub);
        limitedFeeCollectModule.initializePublicationCollectModule(pubId, initData);
        limitedFeeCollectModule.processCollect(pubId, collector, validateData);
        vm.stopPrank();

        ProfilePublicationData memory publicationData = limitedFeeCollectModule.getPublicationData(0);
        assertEq(publicationData.currentCollects, 1);

        assertEq(currency.balanceOf(collector), 100 ether - amount);
        assertEq(currency.balanceOf(recipient), amount);
    }
}
