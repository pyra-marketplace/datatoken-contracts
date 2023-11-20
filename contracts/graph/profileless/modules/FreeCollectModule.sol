// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {CollectModuleBase} from "./base/CollectModuleBase.sol";
import {ICollectModule} from "../interfaces/ICollectModule.sol";

struct ProfilePublicationData {
    uint256 collectLimit;
    uint256 currentCollects;
}

contract FreeCollectModule is CollectModuleBase, ICollectModule {
    error InitParamsInvalid();
    error ExceedCollectLimit();

    using SafeERC20 for IERC20;

    mapping(uint256 => ProfilePublicationData) internal _publicationDataById;

    constructor(address profilelessHub) CollectModuleBase(profilelessHub) {}

    /**
     * @inheritdoc ICollectModule
     */
    function initializePublicationCollectModule(uint256 pubId, bytes calldata data)
        external
        onlyHub
        returns (bytes memory)
    {
        uint256 collectLimit = abi.decode(data, (uint256));
        if (collectLimit == 0) {
            revert InitParamsInvalid();
        }

        ProfilePublicationData memory _profilePublicationData =
            ProfilePublicationData({collectLimit: collectLimit, currentCollects: 0});

        _publicationDataById[pubId] = _profilePublicationData;

        return data;
    }

    /**
     * @inheritdoc ICollectModule
     */
    function processCollect(uint256 pubId, address, bytes calldata) external onlyHub {
        if (_publicationDataById[pubId].currentCollects >= _publicationDataById[pubId].collectLimit) {
            revert ExceedCollectLimit();
        }
        ++_publicationDataById[pubId].currentCollects;
    }

    function getPublicationData(uint256 pubId) external view returns (ProfilePublicationData memory) {
        return _publicationDataById[pubId];
    }
}
