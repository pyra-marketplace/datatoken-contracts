// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {DataTokenHub} from "../../../contracts/DataTokenHub.sol";
import {ProfilelessDataTokenFactory} from "../../../contracts/core/profileless/ProfilelessDataTokenFactory.sol";
import {ProfilelessDataToken} from "../../../contracts/core/profileless/ProfilelessDataToken.sol";
import {CurrencyMock} from "../../../contracts/mocks/CurrencyMock.sol";
import {Test} from "forge-std/Test.sol";

contract ProfilelessCollectModuleBaseTest is Test {
    address governor;
    address dataTokenOwner;
    address collector;

    CurrencyMock currency;
    ProfilelessDataToken dataToken;
    DataTokenHub dataTokenHub;
    ProfilelessDataTokenFactory dataTokenFactory;

    address dataTokenHubTreasury;
    uint256 dataTokenHubTreasuryFeeRate;

    string contentURI;

    uint256 collectLimit;
    uint256 amount;
    uint256 balance; // collector

    function baseSetUp() public {
        governor = makeAddr("governor");
        dataTokenOwner = makeAddr("dataTokenOwner");
        collector = makeAddr("collector");

        contentURI = "https://dataverse-os.com";

        collectLimit = 10000;
        amount = 10e8;
        balance = 10e18;

        vm.startPrank(governor);
        currency = _createCurrency();
        _createDataTokenHub();
        dataTokenFactory = _createDataTokenFactory();
        dataTokenHub.whitelistDataTokenFactory(address(dataTokenFactory), true);

        currency.mint(collector, balance);
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
}
