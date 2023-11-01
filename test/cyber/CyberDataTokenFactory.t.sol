// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {CyberTypes} from "../../contracts/vendor/cyber/CyberTypes.sol";
import {TestLib712} from "cybercontracts/test/utils/TestLib712.sol";
import {Constants} from "cybercontracts/src/libraries/Constants.sol";

import {CyberDataToken} from "../../contracts/core/cyber/CyberDataToken.sol";
import {CyberDataTokenFactory} from "../../contracts/core/cyber/CyberDataTokenFactory.sol";
import {DataTokenHub} from "../../contracts/DataTokenHub.sol";
import {CurrencyMock} from "../../contracts/mocks/CurrencyMock.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {IDataToken} from "../../contracts/interfaces/IDataToken.sol";

import {CyberBaseTest} from "./Base.t.sol";

contract CyberDataTokenFactoryTest is CyberBaseTest {
    DataTokenHub dataTokenHub;
    CyberDataTokenFactory cyberDataTokenFactory;
    address governor;

    string contentURI;
    uint256 deadline;

    function setUp() public {
        _setUp();
        _setupCyberEnv();

        governor = makeAddr("governor");
        contentURI = "https://dataverse-os.com";
        deadline = block.timestamp + 1 days;
        vm.startPrank(governor);
        dataTokenHub = new DataTokenHub();
        dataTokenHub.initialize();
        cyberDataTokenFactory = new CyberDataTokenFactory(address(dataTokenHub), address(link5Profile));

        dataTokenHub.whitelistDataTokenFactory(address(cyberDataTokenFactory), true);
        vm.stopPrank();
    }

    function test_CreateDataToken() public {
        CyberTypes.RegisterEssenceParams memory params = CyberTypes.RegisterEssenceParams(
            profileIdBob, BOB_ESSENCE_NAME, BOB_ESSENCE_SYMBOL, contentURI, essenceMw, true, false
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
                        deadline
                    )
                ),
                link5Profile.name(),
                "1"
            )
        );

        CyberTypes.EIP712Signature memory signature = CyberTypes.EIP712Signature(v, r, s, deadline);

        bytes memory initVars = abi.encode(params, new bytes(0), signature);
        vm.prank(bob);
        address dataToken = cyberDataTokenFactory.createDataToken(initVars);

        DataTypes.Metadata memory metadata = IDataToken(dataToken).getMetadata();
        assertEq(metadata.profileId, params.profileId);
    }

    function test_CreateDataTokenWithSig() public {
        CyberTypes.RegisterEssenceParams memory params = CyberTypes.RegisterEssenceParams(
            profileIdBob, BOB_ESSENCE_NAME, BOB_ESSENCE_SYMBOL, contentURI, essenceMw, true, false
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
                        deadline
                    )
                ),
                link5Profile.name(),
                "1"
            )
        );

        CyberTypes.EIP712Signature memory signature = CyberTypes.EIP712Signature(v, r, s, deadline);

        bytes memory initVars = abi.encode(params, new bytes(0), signature);
        vm.prank(bob);
        address dataToken = cyberDataTokenFactory.createDataTokenWithSig(initVars);

        DataTypes.Metadata memory metadata = IDataToken(dataToken).getMetadata();
        assertEq(metadata.profileId, params.profileId);
        assertEq(metadata.collectMiddleware, essenceMw);
    }
}
