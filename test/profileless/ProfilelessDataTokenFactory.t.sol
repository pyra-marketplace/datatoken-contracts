// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {DataTokenHub} from "../../contracts/DataTokenHub.sol";
import {IDataToken} from "../../contracts/interfaces/IDataToken.sol";
import {ProfilelessDataTokenFactory} from "../../contracts/core/profileless/ProfilelessDataTokenFactory.sol";
import {LimitedFeeCollectModule} from "../../contracts/graph/profileless/modules/LimitedFeeCollectModule.sol";
import {DataTypes} from "../../contracts/libraries/DataTypes.sol";
import {Constants} from "../../contracts/libraries/Constants.sol";
import {Test} from "forge-std/Test.sol";
import "./Base.t.sol";

contract ProfilelessDataTokenFactoryTest is ProfilelessBaseTest {
    address public dataTokenOwner;
    uint256 public dataTokenOwnerPK;
    DataTokenHub public dataTokenHub;
    ProfilelessDataTokenFactory public profilelessDataTokenFactory;

    function setUp() public {
        _setUp();
        (dataTokenOwner, dataTokenOwnerPK) = makeAddrAndKey("dataTokenOwner");

        vm.startPrank(governor);
        dataTokenHub = new DataTokenHub();
        dataTokenHub.initialize();
        profilelessDataTokenFactory = new ProfilelessDataTokenFactory(address(dataTokenHub), address(profilelessHub));
        dataTokenHub.whitelistDataTokenFactory(address(profilelessDataTokenFactory), true);
        vm.stopPrank();
    }

    function test_CreateDataToken() public {
        ProfilelessTypes.PostParams memory postParams = ProfilelessTypes.PostParams({
            contentURI: contentURI,
            collectModule: address(collectModule),
            collectModuleInitData: abi.encode(collectLimit, amount, address(currency), dataTokenOwner)
        });
        ProfilelessTypes.EIP712Signature memory signature =
            _getEIP721PostSignature(postParams, dataTokenOwner, dataTokenOwnerPK);
        bytes memory initVars = abi.encode(postParams, signature);

        vm.prank(dataTokenOwner);
        address dataToken = profilelessDataTokenFactory.createDataToken(initVars);
        assertEq(IDataToken(dataToken).getDataTokenOwner(), dataTokenOwner);
        assertEq(IDataToken(dataToken).getContentURI(), contentURI);
    }
}
