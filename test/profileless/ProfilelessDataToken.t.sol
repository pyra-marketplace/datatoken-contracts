// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {DataTokenHub} from "../../src/DataTokenHub.sol";
import {ProfilelessDataTokenFactory} from "../../src/core/profileless/ProfilelessDataTokenFactory.sol";
import {ProfilelessDataToken} from "../../src/core/profileless/ProfilelessDataToken.sol";
import {FeeCollectModule} from "../../src/core/profileless/modules/FeeCollectModule.sol";
import {CurrencyMock} from "../../src/mocks/CurrencyMock.sol";
import {DataTypes} from "../../src/libraries/DataTypes.sol";
import {Errors} from "../../src/libraries/Errors.sol";
import {Constants} from "../../src/libraries/Constants.sol";
import {Test} from "forge-std/Test.sol";

contract ProfilelessDataTokenTest is Test {
    address governor;
    address dataTokenOwner;
    address notDataTokenOwner;
    address collector;

    CurrencyMock currency;
    DataTokenHub dataTokenHub;
    ProfilelessDataTokenFactory dataTokenFactory;
    FeeCollectModule collectModule;
    ProfilelessDataToken dataToken;

    string contentURI;
    string newContentURI;

    uint256 collectLimit;
    uint256 amount;
    uint256 balance; // collector

    function setUp() public {
        governor = makeAddr("governor");
        dataTokenOwner = makeAddr("dataTokenOwner");
        notDataTokenOwner = makeAddr("notDataTokenOwner");
        collector = makeAddr("collector");
        contentURI = "https://dataverse-os.com";
        newContentURI = "https://github.com/dataverse-os";

        collectLimit = 10000;
        amount = 10e8;
        balance = 10e18;

        vm.startPrank(governor);
        currency = _createCurrency();
        _createDataTokenHub();
        dataTokenFactory = _createDataTokenFactory();
        dataTokenHub.whitelistDataTokenFactory(address(dataTokenFactory), true);
        collectModule = _createCollectModule();
        currency.mint(collector, balance);
        vm.stopPrank();

        vm.prank(dataTokenOwner);
        dataToken = _createDataverseDataToken();
    }

    function test_SetRoyalty() public {
        uint256 salePrice = 10e18;
        uint256 royaltyRate = 100; // 100/10000 = 1%
        vm.prank(dataTokenOwner);
        dataToken.setRoyalty(royaltyRate);

        (address receiver, uint256 royaltyAmount) = dataToken.getRoyaltyInfo(0, salePrice);
        assertEq(receiver, dataTokenOwner);
        assertEq(royaltyAmount, salePrice * royaltyRate / Constants.BASIS_POINTS);
    }

    function testRevert_SetRoyalty_WhenNotDataTokenOwner() public {
        uint256 royaltyRate = 100; // 100/10000 = 1%

        vm.expectRevert(Errors.NotDataTokenOwner.selector);
        vm.prank(notDataTokenOwner);
        dataToken.setRoyalty(royaltyRate);
    }

    function testRevert_SetRoyalty_WhenInvalidRoyaltyRate() public {
        uint256 royaltyRate = 11000; // 11000/10000 = 110%

        vm.expectRevert(abi.encodeWithSelector(Errors.InvalidRoyaltyRate.selector, royaltyRate, Constants.BASIS_POINTS));
        vm.prank(dataTokenOwner);
        dataToken.setRoyalty(royaltyRate);
    }

    function test_SupportsInterface() public {
        bytes4 interfaceId;
        bool isSupported;

        interfaceId = 0x2a55205a;
        isSupported = dataToken.supportsInterface(interfaceId);
        assertEq(isSupported, true);

        interfaceId = 0x11111111;
        isSupported = dataToken.supportsInterface(interfaceId);
        assertEq(isSupported, false);
    }

    function test_Collect() public {
        bytes memory validataData = abi.encode(address(currency), amount);
        bytes memory data = abi.encode(collector, validataData);

        vm.startPrank(collector);
        currency.approve(address(collectModule), balance);
        dataToken.collect(data);
        vm.stopPrank();
    }

    function test_IsCollected() public {
        bytes memory validataData = abi.encode(address(currency), amount);
        bytes memory data = abi.encode(collector, validataData);

        vm.startPrank(collector);
        currency.approve(address(collectModule), balance);
        dataToken.collect(data);
        vm.stopPrank();

        assertEq(dataToken.isCollected(collector), true);
    }

    function test_GetDataTokenOwner() public {
        assertEq(dataTokenOwner, dataToken.getDataTokenOwner());
    }

    function test_GetContentURI() public {
        assertEq(contentURI, dataToken.getContentURI());
    }

    function test_GetMetadata() public {
        DataTypes.Metadata memory metadata = dataToken.getMetadata();
        assertEq(metadata.profileId, 0);
        assertEq(metadata.originalContract, address(dataTokenFactory));
        assertEq(metadata.pubId, 0);
    }

    function testRevert_Collect_WhenInvalidData() public {
        bytes memory validataData = abi.encode(address(currency), amount);
        bytes memory data = abi.encode(validataData);

        vm.startPrank(collector);
        currency.approve(address(collectModule), balance);
        vm.expectRevert();
        dataToken.collect(data);
        vm.stopPrank();
    }

    function _createCurrency() internal returns (CurrencyMock) {
        return new CurrencyMock("Currency-Mock", "CUR");
    }

    function _createDataTokenHub() internal {
        dataTokenHub = new DataTokenHub();
        dataTokenHub.initialize();
    }

    function _createDataTokenFactory() internal returns (ProfilelessDataTokenFactory) {
        return new ProfilelessDataTokenFactory(address(dataTokenHub));
    }

    function _createCollectModule() internal returns (FeeCollectModule) {
        return new FeeCollectModule(address(dataTokenHub), address(dataTokenFactory));
    }

    function _createDataverseDataToken() internal returns (ProfilelessDataToken) {
        DataTypes.ProfilelessPostData memory postData;
        postData.contentURI = contentURI;
        postData.collectModule = address(collectModule);
        postData.collectModuleInitData = abi.encode(collectLimit, amount, currency, dataTokenOwner);
        bytes memory initVars = abi.encode(postData);
        return ProfilelessDataToken(dataTokenFactory.createDataToken(initVars));
    }
}
