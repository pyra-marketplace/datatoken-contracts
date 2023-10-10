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

contract CyberDataTokenFactoryTest is CyberBaseTest {
    CurrencyMock currency;
    DataTokenHub dataTokenHub;
    CyberDataTokenFactory cyberDataTokenFactory;
    CyberDataToken cyberDataToken;
    address governor;
    address dataTokenOwner;
    address notDataTokenOwner;
    address collector;
    address dataTokenHubTreasury;
    uint256 dataTokenHubTreasuryFeeRate;

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

    function _setUpDataToken() internal {
        vm.startPrank(governor);
        _createCurrency();
        _createDataTokenHub();
        _createDataTokenFactory();
        dataTokenHub.whitelistDataTokenFactory(address(cyberDataTokenFactory), true);

        currency.mint(collector, 10 ether);
        vm.stopPrank();

        vm.prank(dataTokenOwner);
        cyberDataToken = _createCyberDataToken();
    }

    function test_Collect() public {
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

    function testCreateDataToken() public {
        DataTypes.RegisterEssenceParams memory params = DataTypes.RegisterEssenceParams(
            profileIdBob, BOB_ESSENCE_NAME, BOB_ESSENCE_SYMBOL, "uri", essenceMw, true, false
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            bobPk,
            TestLib712.hashTypedDataV4(
                address(link5Profile),
                keccak256(
                    abi.encode(
                        Constants._REGISTER_ESSENCE_TYPEHASH,
                        params.profileId,
                        keccak256(bytes(params.name)),
                        keccak256(bytes(params.symbol)),
                        keccak256(bytes(params.essenceTokenURI)),
                        params.essenceMw,
                        params.transferable,
                        keccak256(new bytes(0)),
                        link5Profile.nonces(bob),
                        100
                    )
                ),
                link5Profile.name(),
                "1"
            )
        );

        DataTypes.EIP712Signature memory _sig = DataTypes.EIP712Signature(v, r, s, 100);

        bytes memory initVars = abi.encode(params, new bytes(0), _sig);
        vm.prank(bob);
        address dataToken = cyberDataTokenFactory.createDataToken(initVars);

        DataTokenDataTypes.Metadata memory metadata = IDataToken(dataToken).getMetadata();
        assertEq(metadata.originalContract, address(link5Profile));
        assertEq(metadata.profileId, params.profileId);
    }

    function testCreateDataTokenWithSig() public {
        DataTypes.RegisterEssenceParams memory params = DataTypes.RegisterEssenceParams(
            profileIdBob, BOB_ESSENCE_NAME, BOB_ESSENCE_SYMBOL, "uri", essenceMw, true, false
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            bobPk,
            TestLib712.hashTypedDataV4(
                address(link5Profile),
                keccak256(
                    abi.encode(
                        Constants._REGISTER_ESSENCE_TYPEHASH,
                        params.profileId,
                        keccak256(bytes(params.name)),
                        keccak256(bytes(params.symbol)),
                        keccak256(bytes(params.essenceTokenURI)),
                        params.essenceMw,
                        params.transferable,
                        keccak256(new bytes(0)),
                        link5Profile.nonces(bob),
                        100
                    )
                ),
                link5Profile.name(),
                "1"
            )
        );

        DataTypes.EIP712Signature memory _sig = DataTypes.EIP712Signature(v, r, s, 100);

        bytes memory initVars = abi.encode(params, new bytes(0), _sig);
        vm.prank(bob);
        address dataToken = cyberDataTokenFactory.createDataTokenWithSig(initVars);

        DataTokenDataTypes.Metadata memory metadata = IDataToken(dataToken).getMetadata();
        assertEq(metadata.originalContract, address(link5Profile));
        assertEq(metadata.profileId, params.profileId);
    }

    function _createCyberDataToken() internal returns (CyberDataToken) {
        DataTypes.RegisterEssenceParams memory params = DataTypes.RegisterEssenceParams(
            profileIdBob, BOB_ESSENCE_NAME, BOB_ESSENCE_SYMBOL, "uri", essenceMw, true, false
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            bobPk,
            TestLib712.hashTypedDataV4(
                address(link5Profile),
                keccak256(
                    abi.encode(
                        Constants._REGISTER_ESSENCE_TYPEHASH,
                        params.profileId,
                        keccak256(bytes(params.name)),
                        keccak256(bytes(params.symbol)),
                        keccak256(bytes(params.essenceTokenURI)),
                        params.essenceMw,
                        params.transferable,
                        keccak256(new bytes(0)),
                        link5Profile.nonces(bob),
                        100
                    )
                ),
                link5Profile.name(),
                "1"
            )
        );

        DataTypes.EIP712Signature memory _sig = DataTypes.EIP712Signature(v, r, s, 100);

        bytes memory initVars = abi.encode(params, new bytes(0), _sig);
        vm.prank(bob);
        return CyberDataToken(cyberDataTokenFactory.createDataToken(initVars));
        //        return CyberDataToken(cyberDataTokenFactory.createDataTokenWithSig(initVars));
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
