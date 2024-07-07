// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {CyberTypes} from "../../contracts/graph/cyber/CyberTypes.sol";
import {Constants} from "../../contracts/graph/cyber/Constants.sol";

import {CyberDataTokenFactory} from "../../contracts/core/cyber/CyberDataTokenFactory.sol";
import {CyberDataToken} from "../../contracts/core/cyber/CyberDataToken.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {CyberBaseTest} from "./Base.t.sol";

contract CyberDataTokenFactoryTest is CyberBaseTest {
    address governor;
    address dataTokenOwner;
    uint256 dataTokenOwnerPK;
    uint256 dataTokenOwnerProfileId;

    CyberDataTokenFactory cyberDataTokenFactory;

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
    }

    function test_CreateDataToken() public {
        bytes memory collectMwInitData = abi.encode(totalSupply, amount, dataTokenOwner, currency, subscribeRequired);

        CyberTypes.RegisterEssenceParams memory postParams = CyberTypes.RegisterEssenceParams(
            dataTokenOwnerProfileId,
            "ESSENCE NAME",
            "ESSENCE SYMBOL",
            contentURI,
            CYBER_CONTRACTS.collectPaidMw,
            true,
            false
        );

        CyberTypes.EIP712Signature memory signature =
            _generateEIP712PostSignature(postParams, collectMwInitData, dataTokenOwner, dataTokenOwnerPK);

        bytes memory initVars = abi.encode(postParams, collectMwInitData, signature);
        vm.prank(dataTokenOwner);
        address dataToken = cyberDataTokenFactory.createDataToken(initVars);

        DataTypes.Metadata memory metadata = CyberDataToken(dataToken).getMetadata();
        assertEq(metadata.profileId, postParams.profileId);
    }

    function _generateEIP712PostSignature(
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
}
