// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ProfilelessCollectModuleBaseTest} from "./Base.t.sol";
import {
    LimitedFeeCollectModule,
    ProfilePublicationData
} from "../../../contracts/core/profileless/modules/LimitedFeeCollectModule.sol";
import {ProfilelessDataToken} from "../../../contracts/core/profileless/ProfilelessDataToken.sol";
import {DataTypes} from "../../../contracts/libraries/DataTypes.sol";

contract LimitedFeeCollectModuleTest is ProfilelessCollectModuleBaseTest {
    LimitedFeeCollectModule collectModule;

    function setUp() public {
        baseSetUp();
        collectModule = new LimitedFeeCollectModule(
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
        assertEq(profilePublicationData.amount, amount);
        assertEq(profilePublicationData.currency, address(currency));
        assertEq(profilePublicationData.recipient, dataTokenOwner);
        assertEq(profilePublicationData.dataToken, address(dataToken));
    }

    function test_Collect() public {
        dataToken = _createDataverseDataToken();

        bytes memory validataData = abi.encode(address(currency), amount);
        bytes memory data = abi.encode(collector, validataData);

        vm.startPrank(collector);
        currency.approve(address(collectModule), balance);
        dataToken.collect(data);
        vm.stopPrank();

        uint256 dataTokenHubTreasuryAmount = 0;
        assertEq(currency.balanceOf(dataTokenHubTreasury), dataTokenHubTreasuryAmount);
        assertEq(currency.balanceOf(dataTokenOwner), amount - dataTokenHubTreasuryAmount);

        DataTypes.Metadata memory metadata = dataToken.getMetadata();
        ProfilePublicationData memory profilePublicationData = collectModule.getPublicationData(metadata.pubId);
        assertEq(profilePublicationData.currentCollects, 1);
    }

    function _createDataverseDataToken() internal returns (ProfilelessDataToken) {
        DataTypes.ProfilelessPostData memory postData;
        postData.contentURI = contentURI;
        postData.collectModule = address(collectModule);
        postData.collectModuleInitData = abi.encode(collectLimit, amount, currency, dataTokenOwner);
        bytes memory initVars = abi.encode(postData);

        vm.prank(dataTokenOwner);
        address dataTokenAddress = dataTokenFactory.createDataToken(initVars);
        return ProfilelessDataToken(dataTokenAddress);
    }
}
