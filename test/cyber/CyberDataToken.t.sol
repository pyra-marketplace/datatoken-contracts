// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {DataTypes} from "cybercontracts/src/libraries/DataTypes.sol";
import {TestLib712} from "cybercontracts/test/utils/TestLib712.sol";
import {Constants} from "cybercontracts/src/libraries/Constants.sol";

import {CyberDataToken} from "../../contracts/core/cyber/CyberDataToken.sol";
import {CyberDataTokenFactory} from "../../contracts/core/cyber/CyberDataTokenFactory.sol";
import {DataTokenHub} from "../../contracts/DataTokenHub.sol";
import {CurrencyMock} from "../../contracts/mocks/CurrencyMock.sol";
import {DataTypes as DataTokenDataTypes} from "../../contracts/libraries/DataTypes.sol";
import {IDataToken} from "../../contracts/interfaces/IDataToken.sol";
import {CyberBaseTest} from "./Base.t.sol";

contract CyberDataTokenTest is CyberBaseTest {
    CurrencyMock currency;
    DataTokenHub dataTokenHub;
    CyberDataTokenFactory cyberDataTokenFactory;
    CyberDataToken cyberDataToken;
    address governor;
    address dataTokenOwner;
    address notDataTokenOwner;
    address collector;

    string contentURI;

    function setUp() public {
        // create an engine
        _setUp();
        _setupCyberEnv();

        governor = makeAddr("governor");
        dataTokenOwner = makeAddr("dataTokenOwner");
        notDataTokenOwner = makeAddr("notDataTokenOwner");
        collector = makeAddr("collector");
        contentURI = "https://dataverse-os.com";
        _setUpDataToken();
    }

    function test_Collect() public {
        vm.prank(address(cyberDataTokenFactory));
        dataTokenHub.registerDataToken(bob, address(link5Profile), address(cyberDataToken));

        uint256 deadline = 100;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            bobPk,
            TestLib712.hashTypedDataV4(
                address(link5Profile),
                keccak256(
                    abi.encode(
                        Constants._COLLECT_TYPEHASH,
                        bob,
                        profileIdBob,
                        bobEssenceId,
                        keccak256(new bytes(0)),
                        keccak256(new bytes(0)),
                        link5Profile.nonces(bob),
                        deadline
                    )
                ),
                link5Profile.name(),
                "1"
            )
        );

        DataTypes.CollectParams memory collectParam = DataTypes.CollectParams(bob, profileIdBob, bobEssenceId);

        bytes memory initData =
            abi.encode(collectParam, new bytes(0), new bytes(0), bob, DataTypes.EIP712Signature(v, r, s, deadline));

        vm.prank(bob);
        cyberDataToken.collect(initData);
    }

    function test_CreateCyberDataToken() public {
        vm.prank(bob);
        bobEssenceId = link5Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileIdBob, BOB_ESSENCE_NAME, BOB_ESSENCE_SYMBOL, "uri", essenceMw, true, false
            ),
            dataBobEssence
        );

        CyberDataToken dataToken = _createCyberDataToken(bobEssenceId);
        DataTokenDataTypes.Metadata memory metadata = dataToken.getMetadata();
        assertEq(metadata.originalContract, address(link5Profile));
        assertEq(metadata.profileId, profileIdBob);
        assertEq(metadata.pubId, bobEssenceId);
    }

    function test_IsCollected() public {
        vm.prank(address(cyberDataTokenFactory));
        dataTokenHub.registerDataToken(bob, address(link5Profile), address(cyberDataToken));

        uint256 deadline = 100;
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            bobPk,
            TestLib712.hashTypedDataV4(
                address(link5Profile),
                keccak256(
                    abi.encode(
                        Constants._COLLECT_TYPEHASH,
                        bob,
                        profileIdBob,
                        bobEssenceId,
                        keccak256(new bytes(0)),
                        keccak256(new bytes(0)),
                        link5Profile.nonces(bob),
                        deadline
                    )
                ),
                link5Profile.name(),
                "1"
            )
        );

        DataTypes.CollectParams memory collectParam = DataTypes.CollectParams(bob, profileIdBob, bobEssenceId);

        bytes memory initData =
            abi.encode(collectParam, new bytes(0), new bytes(0), bob, DataTypes.EIP712Signature(v, r, s, deadline));

        vm.prank(bob);
        cyberDataToken.collect(initData);

        assertEq(cyberDataToken.isCollected(bob), true);
    }

    function test_GetDataTokenOwner() public {
        assertEq(bob, cyberDataToken.getDataTokenOwner());
    }

    function test_GetContentURI() public {
        assertEq(contentURI, cyberDataToken.getContentURI());
    }

    function test_GetMetadata() public {
        DataTokenDataTypes.Metadata memory metadata = cyberDataToken.getMetadata();
        assertEq(metadata.profileId, profileIdBob);
        assertEq(metadata.originalContract, address(link5Profile));
        assertEq(metadata.pubId, bobEssenceId);
    }

    function _setUpDataToken() internal {
        vm.startPrank(governor);
        _createCurrency();
        _createDataTokenHub();
        _createDataTokenFactory();
        dataTokenHub.whitelistDataTokenFactory(address(cyberDataTokenFactory), true);
        currency.mint(collector, 10 ether);
        vm.stopPrank();

        vm.prank(bob);
        bobEssenceId = link5Profile.registerEssence(
            DataTypes.RegisterEssenceParams(
                profileIdBob, BOB_ESSENCE_NAME, BOB_ESSENCE_SYMBOL, contentURI, essenceMw, true, false
            ),
            dataBobEssence
        );
        cyberDataToken = _createCyberDataToken(bobEssenceId);
    }

    function _createCyberDataToken(uint256 bobEssenceId) internal returns (CyberDataToken) {
        DataTokenDataTypes.Metadata memory metadata =
            DataTokenDataTypes.Metadata(address(link5Profile), profileIdBob, bobEssenceId, essenceMw);
        vm.prank(bob);
        cyberDataToken = new CyberDataToken(address(dataTokenHub), contentURI, metadata);
        return cyberDataToken;
    }

    function _createDataTokenFactory() internal {
        cyberDataTokenFactory = new CyberDataTokenFactory(address(link5Profile), address(dataTokenHub));
    }

    function _createCurrency() internal {
        currency = new CurrencyMock("Currency-Mock", "CUR");
    }

    function _createDataTokenHub() internal {
        dataTokenHub = new DataTokenHub();
        dataTokenHub.initialize();
    }
}
