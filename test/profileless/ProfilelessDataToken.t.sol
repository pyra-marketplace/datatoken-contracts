// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {DataTokenHub} from "../../contracts/DataTokenHub.sol";
import {IDataToken} from "../../contracts/interfaces/IDataToken.sol";
import {ProfilelessDataTokenFactory} from "../../contracts/core/profileless/ProfilelessDataTokenFactory.sol";
import {ProfilelessDataToken} from "../../contracts/core/profileless/ProfilelessDataToken.sol";
import {LimitedFeeCollectModule} from "../../contracts/graph/profileless/modules/LimitedFeeCollectModule.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {Constants} from "../../contracts/libraries/Constants.sol";
import {Test} from "forge-std/Test.sol";
import "./Base.t.sol";

contract ProfilelessDataTokenFactoryTest is ProfilelessBaseTest {
    address public dataTokenOwner;
    uint256 public dataTokenOwnerPK;
    address public dataTokenCollector;
    uint256 public dataTokenCollectorPK;
    DataTokenHub public dataTokenHub;
    ProfilelessDataTokenFactory public profilelessDataTokenFactory;
    ProfilelessDataToken public profilelessDataToken;

    function setUp() public {
        _setUp();
        (dataTokenOwner, dataTokenOwnerPK) = makeAddrAndKey("dataTokenOwner");
        (dataTokenCollector, dataTokenCollectorPK) = makeAddrAndKey("dataTokenCollector");
        currency.mint(dataTokenCollector, 100 ether);

        vm.startPrank(governor);
        dataTokenHub = new DataTokenHub();
        dataTokenHub.initialize();
        profilelessDataTokenFactory = new ProfilelessDataTokenFactory(address(dataTokenHub), address(profilelessHub));
        dataTokenHub.whitelistDataTokenFactory(address(profilelessDataTokenFactory), true);
        vm.stopPrank();

        vm.prank(dataTokenOwner);
        _createDataToken();
    }

    function test_GetDataTokenOwner() public {
        assertEq(profilelessDataToken.getDataTokenOwner(), dataTokenOwner);
    }

    function test_GetContentURI() public {
        assertEq(profilelessDataToken.getContentURI(), contentURI);
    }

    function test_GetMetadata() public {
        DataTypes.Metadata memory metadata = profilelessDataToken.getMetadata();
        assertEq(metadata.originalContract, address(profilelessHub));
        assertEq(metadata.profileId, 0);
        assertEq(profilelessHub.ownerOf(metadata.pubId), dataTokenOwner);
        assertEq(metadata.collectMiddleware, address(collectModule));
    }

    function test_CollectDataToken() public {
        assertFalse(profilelessDataToken.isCollected(dataTokenCollector));

        uint256 pubId = profilelessDataToken.getMetadata().pubId;

        ProfilelessTypes.CollectParams memory collectParams = ProfilelessTypes.CollectParams({
            pubId: profilelessDataToken.getMetadata().pubId,
            collectModuleValidateData: abi.encode(address(currency), amount)
        });
        ProfilelessTypes.EIP712Signature memory signature =
            _getEIP721CollectSignature(collectParams, dataTokenCollector, dataTokenCollectorPK);
        bytes memory data = abi.encode(collectParams, signature);

        vm.startPrank(dataTokenCollector);
        currency.approve(address(collectModule), amount);
        uint256 collectTokenId = profilelessDataToken.collect(data);
        vm.stopPrank();

        assertTrue(profilelessDataToken.isCollected(dataTokenCollector));
    }

    function test_GetCollectNFT() public {
        assertTrue(profilelessDataToken.getCollectNFT() == address(0));

        ProfilelessTypes.CollectParams memory collectParams = ProfilelessTypes.CollectParams({
            pubId: profilelessDataToken.getMetadata().pubId,
            collectModuleValidateData: abi.encode(address(currency), amount)
        });
        ProfilelessTypes.EIP712Signature memory signature =
            _getEIP721CollectSignature(collectParams, dataTokenCollector, dataTokenCollectorPK);
        bytes memory data = abi.encode(collectParams, signature);

        vm.startPrank(dataTokenCollector);
        currency.approve(address(collectModule), amount);
        uint256 collectTokenId = profilelessDataToken.collect(data);
        vm.stopPrank();

        assertFalse(profilelessDataToken.getCollectNFT() == address(0));
        assertEq(IERC721(profilelessDataToken.getCollectNFT()).ownerOf(collectTokenId), dataTokenCollector);
    }

    function _createDataToken() public {
        ProfilelessTypes.PostParams memory postParams = ProfilelessTypes.PostParams({
            contentURI: contentURI,
            collectModule: address(collectModule),
            collectModuleInitData: abi.encode(collectLimit, amount, address(currency), dataTokenOwner)
        });
        ProfilelessTypes.EIP712Signature memory signature = _getEIP721PostSignature(postParams, dataTokenOwner, dataTokenOwnerPK);
        bytes memory initVars = abi.encode(postParams, signature);

        vm.prank(dataTokenOwner);
        address dataToken = profilelessDataTokenFactory.createDataToken(initVars);
        profilelessDataToken = ProfilelessDataToken(dataToken);
    }
}



// import {DataTokenHub} from "../../contracts/DataTokenHub.sol";
// import {ProfilelessDataTokenFactory} from "../../contracts/core/profileless/ProfilelessDataTokenFactory.sol";
// import {ProfilelessDataToken} from "../../contracts/core/profileless/ProfilelessDataToken.sol";
// import {LimitedFeeCollectModule} from "../../contracts/core/profileless/modules/LimitedFeeCollectModule.sol";
// import {CurrencyMock} from "../../contracts/mocks/CurrencyMock.sol";
// import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
// import {Errors} from "../../contracts/libraries/Errors.sol";
// import {Constants} from "../../contracts/libraries/Constants.sol";
// import {Test} from "forge-std/Test.sol";

// contract ProfilelessDataTokenTest is Test {
//     address governor;
//     address dataTokenOwner;
//     address notDataTokenOwner;
//     address collector;

//     CurrencyMock currency;
//     DataTokenHub dataTokenHub;
//     ProfilelessDataTokenFactory dataTokenFactory;
//     LimitedFeeCollectModule collectModule;
//     ProfilelessDataToken profilelessDataToken;

//     string contentURI;
//     string newContentURI;

//     uint256 collectLimit;
//     uint256 amount;
//     uint256 balance; // collector

//     function setUp() public {
//         governor = makeAddr("governor");
//         dataTokenOwner = makeAddr("dataTokenOwner");
//         notDataTokenOwner = makeAddr("notDataTokenOwner");
//         collector = makeAddr("collector");
//         contentURI = "https://dataverse-os.com";
//         newContentURI = "https://github.com/dataverse-os";

//         collectLimit = 10000;
//         amount = 10e8;
//         balance = 10e18;

//         vm.startPrank(governor);
//         currency = _createCurrency();
//         _createDataTokenHub();
//         dataTokenFactory = _createDataTokenFactory();
//         dataTokenHub.whitelistDataTokenFactory(address(dataTokenFactory), true);
//         collectModule = _createCollectModule();
//         currency.mint(collector, balance);
//         vm.stopPrank();

//         vm.prank(dataTokenOwner);
//         profilelessDataToken = _createDataverseDataToken();
//     }

//     function test_GraphType() public {
//         assertTrue(profilelessDataToken.graphType() == DataTypes.GraphType.Profileless);
//     }

//     function test_SetRoyalty() public {
//         uint256 salePrice = 10e18;
//         uint256 royaltyRate = 100; // 100/10000 = 1%
//         vm.prank(dataTokenOwner);
//         profilelessDataToken.setRoyalty(royaltyRate);

//         (address receiver, uint256 royaltyAmount) = profilelessDataToken.getRoyaltyInfo(0, salePrice);
//         assertEq(receiver, dataTokenOwner);
//         assertEq(royaltyAmount, salePrice * royaltyRate / Constants.BASIS_POINTS);
//     }

//     function testRevert_SetRoyalty_WhenNotDataTokenOwner() public {
//         uint256 royaltyRate = 100; // 100/10000 = 1%

//         vm.expectRevert(Errors.NotDataTokenOwner.selector);
//         vm.prank(notDataTokenOwner);
//         profilelessDataToken.setRoyalty(royaltyRate);
//     }

//     function testRevert_SetRoyalty_WhenInvalidRoyaltyRate() public {
//         uint256 royaltyRate = 11000; // 11000/10000 = 110%

//         vm.expectRevert(abi.encodeWithSelector(Errors.InvalidRoyaltyRate.selector, royaltyRate, Constants.BASIS_POINTS));
//         vm.prank(dataTokenOwner);
//         profilelessDataToken.setRoyalty(royaltyRate);
//     }

//     function test_SupportsInterface() public {
//         bytes4 interfaceId;
//         bool isSupported;

//         interfaceId = 0x2a55205a;
//         isSupported = profilelessDataToken.supportsInterface(interfaceId);
//         assertEq(isSupported, true);

//         interfaceId = 0x11111111;
//         isSupported = profilelessDataToken.supportsInterface(interfaceId);
//         assertEq(isSupported, false);
//     }

//     function test_Collect() public {
//         bytes memory validataData = abi.encode(address(currency), amount);
//         bytes memory data = abi.encode(collector, validataData);

//         vm.startPrank(collector);
//         currency.approve(address(collectModule), balance);
//         profilelessDataToken.collect(data);
//         vm.stopPrank();
//     }

//     function test_IsCollected() public {
//         bytes memory validataData = abi.encode(address(currency), amount);
//         bytes memory data = abi.encode(collector, validataData);

//         vm.startPrank(collector);
//         currency.approve(address(collectModule), balance);
//         profilelessDataToken.collect(data);
//         vm.stopPrank();

//         assertEq(profilelessDataToken.isCollected(collector), true);
//     }

//     function test_GetCollectNFT() public {
//         assertEq(profilelessDataToken.getCollectNFT(), address(profilelessDataToken));
//     }

//     function test_GetDataTokenOwner() public {
//         assertEq(dataTokenOwner, profilelessDataToken.getDataTokenOwner());
//     }

//     function test_GetContentURI() public {
//         assertEq(contentURI, profilelessDataToken.getContentURI());
//     }

//     function test_GetMetadata() public {
//         DataTypes.Metadata memory metadata = profilelessDataToken.getMetadata();
//         assertEq(metadata.profileId, 0);
//         assertEq(metadata.pubId, 0);
//     }

//     function testRevert_Collect_WhenInvalidData() public {
//         bytes memory validataData = abi.encode(address(currency), amount);
//         bytes memory data = abi.encode(validataData);

//         vm.startPrank(collector);
//         currency.approve(address(collectModule), balance);
//         vm.expectRevert();
//         profilelessDataToken.collect(data);
//         vm.stopPrank();
//     }

//     function _createCurrency() internal returns (CurrencyMock) {
//         return new CurrencyMock("Currency-Mock", "CUR");
//     }

//     function _createDataTokenHub() internal {
//         dataTokenHub = new DataTokenHub();
//         dataTokenHub.initialize();
//     }

//     function _createDataTokenFactory() internal returns (ProfilelessDataTokenFactory) {
//         return new ProfilelessDataTokenFactory(address(dataTokenHub));
//     }

//     function _createCollectModule() internal returns (LimitedFeeCollectModule) {
//         return new LimitedFeeCollectModule(address(dataTokenHub), address(dataTokenFactory));
//     }

//     function _createDataverseDataToken() internal returns (ProfilelessDataToken) {
//         DataTypes.PostParams memory postParams;
//         postParams.contentURI = contentURI;
//         postParams.collectModule = address(collectModule);
//         postParams.collectModuleInitData = abi.encode(collectLimit, amount, currency, dataTokenOwner);
//         bytes memory initVars = abi.encode(postParams);
//         return ProfilelessDataToken(dataTokenFactory.createDataToken(initVars));
//     }
// }
