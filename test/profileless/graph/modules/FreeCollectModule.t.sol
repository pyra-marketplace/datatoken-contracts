// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {FreeCollectModule, ProfilePublicationData} from "../../../../contracts/graph/profileless/modules/FreeCollectModule.sol";
import {Test} from "forge-std/Test.sol";

contract FreeCollectModuleTest is Test {
    address profilelessHub;
    address collector;
    FreeCollectModule freeCollectModule;

    uint256 collectLimit;

    function setUp() public {
        profilelessHub = makeAddr("profilelessHub");
        collector = makeAddr("collector");
        freeCollectModule = new FreeCollectModule(profilelessHub);
        collectLimit = 2;
    }

    function test_InitializePublicationCollectModule() public {
        uint256 pubId = 0;
        bytes memory data = abi.encode(collectLimit);

        vm.prank(profilelessHub);
        freeCollectModule.initializePublicationCollectModule(pubId, data);

        ProfilePublicationData memory publicationData = freeCollectModule.getPublicationData(0);
        assertEq(publicationData.collectLimit, collectLimit);
        assertEq(publicationData.currentCollects, 0);
    }

    function test_ProcessCollect() public {
        uint256 pubId = 0;
        bytes memory data = abi.encode(collectLimit);

        vm.startPrank(profilelessHub);
        freeCollectModule.initializePublicationCollectModule(pubId, data);
        freeCollectModule.processCollect(pubId, collector, new bytes(0));
        vm.stopPrank();

        ProfilePublicationData memory publicationData = freeCollectModule.getPublicationData(0);
        assertEq(publicationData.currentCollects, 1);
    }
}