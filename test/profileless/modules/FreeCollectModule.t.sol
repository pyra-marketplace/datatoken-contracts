// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {
    FreeCollectModule,
    ProfilePublicationData
} from "../../../contracts/core/profileless/modules/FreeCollectModule.sol";
import {ProfilelessDataToken} from "../../../contracts/core/profileless/ProfilelessDataToken.sol";
import {ProfilelessCollectModuleBaseTest} from "./Base.t.sol";
import {DataTypes} from "../../../contracts/libraries/DataTypes.sol";
import {Constants} from "../../../contracts/libraries/Constants.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";

contract FreeCollectModuleTest is ProfilelessCollectModuleBaseTest {
    FreeCollectModule collectModule;

    function setUp() public {
        baseSetUp();
        collectModule = new FreeCollectModule(
            address(dataTokenHub), 
            address(dataTokenFactory)
        );
    }

    function test_InitializePublicationCollectModule() public {
        dataToken = _createDataverseDataToken();
        DataTypes.Metadata memory metadata = dataToken.getMetadata();
        ProfilePublicationData memory profilePublicationData = collectModule.getPublicationData(metadata.pubId);
        assertEq(profilePublicationData.collectLimit, 10000);
        assertEq(profilePublicationData.currentCollects, 0);
        assertEq(profilePublicationData.dataToken, address(dataToken));
    }

    function test_Collect() public {
        dataToken = _createDataverseDataToken();

        bytes memory data = abi.encode(collector, new bytes(0));

        vm.startPrank(collector);
        currency.approve(address(collectModule), balance);
        dataToken.collect(data);
        vm.stopPrank();

        assertEq(currency.balanceOf(dataTokenHubTreasury), 0);
        assertEq(currency.balanceOf(collector), balance);
        assertEq(currency.balanceOf(dataTokenOwner), 0);

        DataTypes.Metadata memory metadata = dataToken.getMetadata();
        ProfilePublicationData memory profilePublicationData = collectModule.getPublicationData(metadata.pubId);
        assertEq(profilePublicationData.currentCollects, 1);
    }

    function _createDataverseDataToken() internal returns (ProfilelessDataToken) {
        DataTypes.ProfilelessPostData memory postData;
        postData.contentURI = contentURI;
        postData.collectModule = address(collectModule);
        postData.collectModuleInitData = abi.encode(collectLimit);
        bytes memory initVars = abi.encode(postData);

        vm.prank(dataTokenOwner);
        address dataTokenAddress = dataTokenFactory.createDataToken(initVars);
        return ProfilelessDataToken(dataTokenAddress);
    }
}
