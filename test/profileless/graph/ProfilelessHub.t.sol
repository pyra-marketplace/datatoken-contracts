// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Errors} from "../../../contracts/graph/profileless/libraries/Errors.sol";
import "../Base.t.sol";

contract ProfilelessHubTest is ProfilelessBaseTest {
    function setUp() public {
        _setUp();
    }

    function test_GetGovernor() public {
        assertEq(profilelessHub.getGovernor(), governor);
    }

    function test_SetGovernor() public {
        address newGovernor = makeAddr("newGovernor");

        vm.prank(governor);
        profilelessHub.setGovernor(newGovernor);
        assertEq(profilelessHub.getGovernor(), newGovernor);
    }

    function test_IsCurrencyWhitelisted() public {
        assertTrue(profilelessHub.isCurrencyWhitelisted(address(currency)));
    }

    function test_WhitelistCurrency() public {
        address newCurrency = makeAddr("newCurrency");

        vm.prank(governor);
        profilelessHub.whitelistCurrency(newCurrency, true);
        assertTrue(profilelessHub.isCurrencyWhitelisted(newCurrency));
    }

    function test_IsCollectModuleWhitelisted() public {
        assertEq(profilelessHub.isCollectModuleWhitelisted(address(collectModule)), true);
    }

    function test_WhitelistCollectModule() public {
        address newCollectModule = makeAddr("newCollectModule");

        vm.prank(governor);
        profilelessHub.whitelistCollectModule(newCollectModule, true);
        assertTrue(profilelessHub.isCollectModuleWhitelisted(newCollectModule));
    }

    function test_IsRestricted() public {
        assertFalse(profilelessHub.isRestricted(collector, pubOwner));

        ProfilelessTypes.RestrictParams memory restrictParams =
            ProfilelessTypes.RestrictParams({account: collector, restricted: true});

        vm.prank(pubOwner);
        profilelessHub.restrict(restrictParams);

        assertTrue(profilelessHub.isRestricted(collector, pubOwner));
    }

    function test_Post() public {
        ProfilelessTypes.PostParams memory postParams = ProfilelessTypes.PostParams({
            contentURI: contentURI,
            collectModule: address(collectModule),
            collectModuleInitData: abi.encode(collectLimit, amount, currency, pubOwner)
        });

        vm.prank(pubOwner);
        uint256 pubId = profilelessHub.post(postParams);
        ProfilelessTypes.Publication memory publication = profilelessHub.getPublication(pubId);
        assertEq(publication.pubId, pubId);
        assertEq(publication.contentURI, contentURI);
        assertEq(publication.collectModule, address(collectModule));
        assertEq(publication.collectNFT, address(0));
        assertEq(profilelessHub.ownerOf(pubId), pubOwner);
    }

    function test_PostWithSig() public {
        ProfilelessTypes.PostParams memory postParams = ProfilelessTypes.PostParams({
            contentURI: contentURI,
            collectModule: address(collectModule),
            collectModuleInitData: abi.encode(collectLimit, amount, address(currency), pubOwner)
        });
        ProfilelessTypes.EIP712Signature memory signature = _getEIP712PostSignature(postParams, pubOwner, pubOwnerPK);

        vm.prank(pubOwner);
        uint256 pubId = profilelessHub.postWithSig(postParams, signature);
        ProfilelessTypes.Publication memory publication = profilelessHub.getPublication(pubId);
        assertEq(publication.pubId, pubId);
        assertEq(publication.contentURI, contentURI);
        assertEq(publication.collectModule, address(collectModule));
        assertEq(publication.collectNFT, address(0));
        assertEq(profilelessHub.ownerOf(pubId), pubOwner);
    }

    function test_Collect() public {
        ProfilelessTypes.PostParams memory postParams = ProfilelessTypes.PostParams({
            contentURI: contentURI,
            collectModule: address(collectModule),
            collectModuleInitData: abi.encode(collectLimit, amount, address(currency), pubOwner)
        });

        vm.prank(pubOwner);
        uint256 pubId = profilelessHub.post(postParams);

        ProfilelessTypes.CollectParams memory collectParams = ProfilelessTypes.CollectParams({
            pubId: pubId,
            collectModuleValidateData: abi.encode(address(currency), amount)
        });
        vm.startPrank(collector);
        currency.approve(address(collectModule), amount);
        uint256 collectTokenId = profilelessHub.collect(collectParams);
        vm.stopPrank();
        assertEq(IERC721(profilelessHub.getPublication(pubId).collectNFT).ownerOf(collectTokenId), collector);
    }

    function test_CollectWithSig() public {
        ProfilelessTypes.PostParams memory postParams = ProfilelessTypes.PostParams({
            contentURI: contentURI,
            collectModule: address(collectModule),
            collectModuleInitData: abi.encode(collectLimit, amount, address(currency), pubOwner)
        });

        vm.prank(pubOwner);
        uint256 pubId = profilelessHub.post(postParams);

        ProfilelessTypes.CollectParams memory collectParams = ProfilelessTypes.CollectParams({
            pubId: pubId,
            collectModuleValidateData: abi.encode(address(currency), amount)
        });
        ProfilelessTypes.EIP712Signature memory signature =
            _getEIP712CollectSignature(collectParams, collector, collectorPK);
        vm.startPrank(collector);
        currency.approve(address(collectModule), amount);
        uint256 collectTokenId = profilelessHub.collectWithSig(collectParams, signature);
        vm.stopPrank();
        assertEq(IERC721(profilelessHub.getPublication(pubId).collectNFT).ownerOf(collectTokenId), collector);
    }

    function testRevert_Collect_WhenRestricted() public {
        ProfilelessTypes.PostParams memory postParams = ProfilelessTypes.PostParams({
            contentURI: contentURI,
            collectModule: address(collectModule),
            collectModuleInitData: abi.encode(collectLimit, amount, address(currency), pubOwner)
        });
        ProfilelessTypes.RestrictParams memory restrictParams =
            ProfilelessTypes.RestrictParams({account: collector, restricted: true});

        vm.startPrank(pubOwner);
        uint256 pubId = profilelessHub.post(postParams);
        profilelessHub.restrict(restrictParams);
        vm.stopPrank();

        ProfilelessTypes.CollectParams memory collectParams = ProfilelessTypes.CollectParams({
            pubId: pubId,
            collectModuleValidateData: abi.encode(address(currency), amount)
        });

        vm.startPrank(collector);
        currency.approve(address(collectModule), amount);
        vm.expectRevert(Errors.AccountRestricted.selector);
        profilelessHub.collect(collectParams);
        vm.stopPrank();
    }

    function test_Restrict() public {
        assertFalse(profilelessHub.isRestricted(collector, pubOwner));

        ProfilelessTypes.RestrictParams memory restrictParams =
            ProfilelessTypes.RestrictParams({account: collector, restricted: true});

        vm.prank(pubOwner);
        profilelessHub.restrict(restrictParams);

        assertTrue(profilelessHub.isRestricted(collector, pubOwner));
    }

    function test_RestrictWithSig() public {
        assertFalse(profilelessHub.isRestricted(collector, pubOwner));

        ProfilelessTypes.RestrictParams memory restrictParams =
            ProfilelessTypes.RestrictParams({account: collector, restricted: true});
        ProfilelessTypes.EIP712Signature memory signature =
            _getEIP712RestrictSignature(restrictParams, pubOwner, pubOwnerPK);

        vm.prank(pubOwner);
        profilelessHub.restrictWithSig(restrictParams, signature);

        assertTrue(profilelessHub.isRestricted(collector, pubOwner));
    }
}
