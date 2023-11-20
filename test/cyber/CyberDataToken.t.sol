// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {CyberTypes} from "../../contracts/graph/cyber/CyberTypes.sol";
import {Constants} from "../../contracts/graph/cyber/Constants.sol";

import {CyberDataTokenFactory} from "../../contracts/core/cyber/CyberDataTokenFactory.sol";
import {CyberDataToken} from "../../contracts/core/cyber/CyberDataToken.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {CyberBaseTest} from "./Base.t.sol";

contract CyberDataTokenTest is CyberBaseTest {
    address dataTokenOwner;
    uint256 dataTokenOwnerPK;
    uint256 dataTokenOwnerProfileId;
    address collector;
    uint256 collectorPK;
    CyberDataTokenFactory cyberDataTokenFactory;
    CyberDataToken cyberDataToken;
    address governor;

    string contentURI;
    uint256 deadline;

    uint256 totalSupply;
    address currency;
    uint256 amount;
    bool subscribeRequired;

    function setUp() public {
        _setUp();
        governor = makeAddr("governor");
        dataTokenOwnerPK = vm.envUint("PRIVATE_KEY");
        dataTokenOwner = vm.addr(dataTokenOwnerPK);
        collectorPK = vm.envUint("PRIVATE_KEY");
        collector = vm.addr(collectorPK);

        contentURI = "https://dataverse-os.com";
        deadline = block.timestamp + 1 days;

        totalSupply = 100;
        currency = CYBER_CONTRACTS.LINK;
        amount = 1e5;
        subscribeRequired = false;

        vm.startPrank(governor);
        _createDataTokenHub();
        cyberDataTokenFactory = new CyberDataTokenFactory(address(dataTokenHub), address(CYBER_CONTRACTS.profileNFT));
        dataTokenHub.whitelistDataTokenFactory(address(cyberDataTokenFactory), true);
        vm.stopPrank();

        dataTokenOwnerProfileId = _createCyberProfile(dataTokenOwner);
        cyberDataToken = _createDataToken();
    }

    function test_GraphType() public {
        assertTrue(cyberDataToken.graphType() == DataTypes.GraphType.Cyber);
    }

    function test_Collect() public {
        uint256 collectTokenId = _collectDataToken();

        assertEq(collector, IERC721(cyberDataToken.getCollectNFT()).ownerOf(collectTokenId));
    }

    function test_GetCollectNFT() public {
        address collectNFTAddr = cyberDataToken.getCollectNFT();
        assertTrue(collectNFTAddr == address(0));

        uint256 collectTokenId = _collectDataToken();

        collectNFTAddr = cyberDataToken.getCollectNFT();
        assertEq(IERC721(collectNFTAddr).ownerOf(collectTokenId), collector);
    }

    function test_IsCollected() public {
        _collectDataToken();
        assertEq(cyberDataToken.isCollected(collector), true);
    }

    function test_GetDataTokenOwner() public {
        assertEq(collector, cyberDataToken.getDataTokenOwner());
    }

    function test_GetContentURI() public {
        assertEq(contentURI, cyberDataToken.getContentURI());
    }

    function test_GetMetadata() public {
        DataTypes.Metadata memory metadata = cyberDataToken.getMetadata();
        assertEq(metadata.profileId, dataTokenOwnerProfileId);
        assertEq(metadata.collectMiddleware, CYBER_CONTRACTS.collectPaidMw);
    }

    function _createDataToken() internal returns (CyberDataToken) {
        CyberTypes.RegisterEssenceParams memory postParams = CyberTypes.RegisterEssenceParams(
            dataTokenOwnerProfileId,
            "ESSENCE NAME",
            "ESSENCE SYMBOL",
            contentURI,
            CYBER_CONTRACTS.collectPaidMw,
            true,
            false
        );

        bytes memory collectMwInitData = abi.encode(totalSupply, amount, dataTokenOwner, currency, subscribeRequired);

        CyberTypes.EIP712Signature memory signature =
            _generateEIP721PostSignature(postParams, collectMwInitData, dataTokenOwner, dataTokenOwnerPK);

        bytes memory initVars = abi.encode(postParams, collectMwInitData, signature);

        vm.prank(dataTokenOwner);
        return CyberDataToken(cyberDataTokenFactory.createDataToken(initVars));
    }

    function _collectDataToken() internal returns (uint256) {
        DataTypes.Metadata memory metadata = cyberDataToken.getMetadata();

        CyberTypes.CollectParams memory collectParam =
            CyberTypes.CollectParams(collector, metadata.profileId, metadata.pubId);

        CyberTypes.EIP712Signature memory signature =
            _generateEIP712CollectSignature(collectParam, collector, collectorPK);

        bytes memory preData = new bytes(0);
        bytes memory postData = new bytes(0);
        bytes memory initData = abi.encode(collectParam, preData, postData, collector, signature);

        vm.startPrank(collector, collector);
        IERC20(currency).approve(CYBER_CONTRACTS.collectPaidMw, amount);
        uint256 collectTokenId = cyberDataToken.collect(initData);
        vm.stopPrank();

        return collectTokenId;
    }

    function _generateEIP721PostSignature(
        CyberTypes.RegisterEssenceParams memory postParams,
        bytes memory collectMwInitData,
        address signer,
        uint256 signerPK
    ) internal view returns (CyberTypes.EIP712Signature memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            signerPK,
            _hashTypedDataV4(
                address(CYBER_CONTRACTS.profileNFT),
                keccak256(
                    abi.encode(
                        Constants._REGISTER_ESSENCE_TYPEHASH,
                        postParams.profileId,
                        keccak256(bytes(postParams.name)),
                        keccak256(bytes(postParams.symbol)),
                        keccak256(bytes(postParams.essenceTokenURI)),
                        postParams.essenceMw,
                        postParams.transferable,
                        keccak256(collectMwInitData),
                        CYBER_CONTRACTS.profileNFT.nonces(signer),
                        deadline
                    )
                ),
                CYBER_CONTRACTS.profileNFT.name(),
                "1"
            )
        );
        return CyberTypes.EIP712Signature(v, r, s, deadline);
    }

    function _generateEIP712CollectSignature(
        CyberTypes.CollectParams memory collectParams,
        address signer,
        uint256 signerPK
    ) internal view returns (CyberTypes.EIP712Signature memory) {
        bytes memory preData = new bytes(0);
        bytes memory postData = new bytes(0);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(
            signerPK,
            _hashTypedDataV4(
                address(CYBER_CONTRACTS.profileNFT),
                keccak256(
                    abi.encode(
                        Constants._COLLECT_TYPEHASH,
                        collectParams.collector,
                        collectParams.profileId,
                        collectParams.essenceId,
                        keccak256(preData),
                        keccak256(postData),
                        CYBER_CONTRACTS.profileNFT.nonces(signer),
                        deadline
                    )
                ),
                CYBER_CONTRACTS.profileNFT.name(),
                "1"
            )
        );
        return CyberTypes.EIP712Signature(v, r, s, deadline);
    }
}
