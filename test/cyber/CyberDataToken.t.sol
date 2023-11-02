// SPDX-License-Identifier: MIT
pragma solidity 0.8.14;

import {IERC721} from "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
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

contract CyberDataTokenTest is CyberBaseTest {
    CurrencyMock currency;
    DataTokenHub dataTokenHub;
    CyberDataTokenFactory cyberDataTokenFactory;
    CyberDataToken cyberDataToken;
    address governor;
    address collector;

    string contentURI;
    uint256 deadline;

    function setUp() public {
        _setUp();
        _setupCyberEnv();

        governor = makeAddr("governor");
        collector = makeAddr("collector");
        contentURI = "https://dataverse-os.com";
        deadline = block.timestamp + 1 days;

        vm.startPrank(governor);
        currency = new CurrencyMock("Currency-Mock", "CUR");
        dataTokenHub = new DataTokenHub();
        dataTokenHub.initialize();
        cyberDataTokenFactory = new CyberDataTokenFactory(address(dataTokenHub), address(link5Profile));

        dataTokenHub.whitelistDataTokenFactory(address(cyberDataTokenFactory), true);
        currency.mint(collector, 10 ether);
        vm.stopPrank();

        cyberDataToken = _createCyberDataToken();
    }

    function test_GraphType() public {
        assertTrue(cyberDataToken.graphType() == DataTypes.GraphType.Cyber);
    }

    function test_Collect() public {
        DataTypes.Metadata memory metadata = cyberDataToken.getMetadata();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            bobPk,
            TestLib712.hashTypedDataV4(
                address(link5Profile),
                keccak256(
                    abi.encode(
                        Constants._COLLECT_TYPEHASH,
                        bob,
                        metadata.profileId,
                        metadata.pubId,
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

        CyberTypes.CollectParams memory collectParam = CyberTypes.CollectParams(bob, metadata.profileId, metadata.pubId);

        bytes memory initData =
            abi.encode(collectParam, new bytes(0), new bytes(0), bob, CyberTypes.EIP712Signature(v, r, s, deadline));

        vm.prank(bob);
        uint256 collectTokenId = cyberDataToken.collect(initData);

        assertEq(bob, IERC721(cyberDataToken.getCollectNFT()).ownerOf(collectTokenId));
    }

    function test_GetCollectNFT() public {
        address collectNFTAddr = cyberDataToken.getCollectNFT();
        assertTrue(collectNFTAddr == address(0));

        DataTypes.Metadata memory metadata = cyberDataToken.getMetadata();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            bobPk,
            TestLib712.hashTypedDataV4(
                address(link5Profile),
                keccak256(
                    abi.encode(
                        Constants._COLLECT_TYPEHASH,
                        bob,
                        metadata.profileId,
                        metadata.pubId,
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

        CyberTypes.CollectParams memory collectParam = CyberTypes.CollectParams(bob, metadata.profileId, metadata.pubId);

        bytes memory initData =
            abi.encode(collectParam, new bytes(0), new bytes(0), bob, CyberTypes.EIP712Signature(v, r, s, deadline));

        vm.prank(bob);
        cyberDataToken.collect(initData);

        collectNFTAddr = cyberDataToken.getCollectNFT();
        assertFalse(collectNFTAddr == address(0));
    }

    function test_IsCollected() public {
        DataTypes.Metadata memory metadata = cyberDataToken.getMetadata();

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            bobPk,
            TestLib712.hashTypedDataV4(
                address(link5Profile),
                keccak256(
                    abi.encode(
                        Constants._COLLECT_TYPEHASH,
                        bob,
                        metadata.profileId,
                        metadata.pubId,
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

        CyberTypes.CollectParams memory collectParam = CyberTypes.CollectParams(bob, metadata.profileId, metadata.pubId);

        bytes memory initData =
            abi.encode(collectParam, new bytes(0), new bytes(0), bob, CyberTypes.EIP712Signature(v, r, s, deadline));

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
        DataTypes.Metadata memory metadata = cyberDataToken.getMetadata();
        assertEq(metadata.profileId, profileIdBob);
        assertEq(metadata.collectMiddleware, essenceMw);
    }

    function _createCyberDataToken() internal returns (CyberDataToken) {
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
        return CyberDataToken(cyberDataTokenFactory.createDataToken(initVars));
    }
}
