// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {
    LimitedTimedFeeCollectModule,
    ProfilePublicationData
} from "../../../contracts/core/profileless/modules/LimitedTimedFeeCollectModule.sol";
import {ProfilelessDataToken} from "../../../contracts/core/profileless/ProfilelessDataToken.sol";
import {ProfilelessCollectModuleBaseTest} from "./Base.t.sol";
import {DataTypes} from "../../../contracts/libraries/DataTypes.sol";
import {Constants} from "../../../contracts/libraries/Constants.sol";
import {Errors} from "../../../contracts/libraries/Errors.sol";

contract LimitedTimedFeeCollectModuleTest is ProfilelessCollectModuleBaseTest {
    uint40 constant ONE_DAY = 24 hours;
    LimitedTimedFeeCollectModule collectModule;

    function setUp() public {
        baseSetUp();
        collectModule = new LimitedTimedFeeCollectModule(
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

        //        uint256 dataTokenHubTreasuryAmount = amount * dataTokenHubTreasuryFeeRate / Constants.FEE_RATE_BPS;
        uint256 dataTokenHubTreasuryAmount = 0;
        assertEq(currency.balanceOf(dataTokenHubTreasury), dataTokenHubTreasuryAmount);
        assertEq(currency.balanceOf(dataTokenOwner), amount - dataTokenHubTreasuryAmount);

        DataTypes.Metadata memory metadata = dataToken.getMetadata();
        ProfilePublicationData memory profilePublicationData = collectModule.getPublicationData(metadata.pubId);
        assertEq(profilePublicationData.currentCollects, 1);
    }

    function testRevert_Collect_WhenExpired() public {
        dataToken = _createDataverseDataToken();

        bytes memory validataData = abi.encode(address(currency), amount);
        bytes memory data = abi.encode(collector, validataData);
        uint40 twoDaysLaterTimestamp = uint40(block.timestamp) + 2 * ONE_DAY;

        vm.warp(twoDaysLaterTimestamp);

        vm.startPrank(collector);
        currency.approve(address(collectModule), balance);
        vm.expectRevert(Errors.CollectExpired.selector);
        dataToken.collect(data);
        vm.stopPrank();
    }

    function _createDataverseDataToken() internal returns (ProfilelessDataToken) {
        uint40 endTimestamp = uint40(block.timestamp) + ONE_DAY;
        DataTypes.ProfilelessPostData memory postData;
        postData.contentURI = contentURI;
        postData.collectModule = address(collectModule);
        postData.collectModuleInitData = abi.encode(collectLimit, amount, currency, dataTokenOwner, endTimestamp);
        bytes memory initVars = abi.encode(postData);

        vm.prank(dataTokenOwner);
        address dataTokenAddress = dataTokenFactory.createDataToken(initVars);
        return ProfilelessDataToken(dataTokenAddress);
    }
}
