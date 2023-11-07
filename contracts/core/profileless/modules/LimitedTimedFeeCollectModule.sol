// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Errors} from "../../../libraries/Errors.sol";
import {ProfilelessCollectModuleBase} from "../base/ProfilelessCollectModuleBase.sol";

struct ProfilePublicationData {
    uint256 collectLimit;
    uint256 currentCollects;
    uint256 amount;
    address currency;
    address recipient;
    uint40 endTimestamp;
    address dataToken;
}

contract LimitedTimedFeeCollectModule is ProfilelessCollectModuleBase {
    using SafeERC20 for IERC20;

    uint16 internal constant BPS_MAX = 10000;

    address public immutable DATA_TOKEN_FACTORY;

    mapping(uint256 => ProfilePublicationData) internal _dataByPublication;
    /// @dev pubId => shared people => bool
    mapping(uint256 => mapping(address => bool)) internal _isFeeFree;

    constructor(address dataTokenHub, address dataTokenFactory) ProfilelessCollectModuleBase(dataTokenHub) {
        DATA_TOKEN_FACTORY = dataTokenFactory;
    }

    modifier onlyDataTokenFactory() {
        if (msg.sender != DATA_TOKEN_FACTORY) {
            revert Errors.NotDataTokenFactory();
        }
        _;
    }

    function initializePublicationCollectModule(uint256 pubId, bytes calldata data, address dataToken)
        external
        onlyDataTokenFactory
        returns (bytes memory)
    {
        (uint256 collectLimit, uint256 amount, address currency, address recipient, uint40 endTimestamp) =
            abi.decode(data, (uint256, uint256, address, address, uint40));
        if (collectLimit == 0 /* !_isCurrencyWhitelistedByHub(currency) ||*/ || amount == 0) {
            revert Errors.InitParamsInvalid();
        }

        ProfilePublicationData memory _profilePublicationData = ProfilePublicationData({
            collectLimit: collectLimit,
            currentCollects: 0,
            amount: amount,
            currency: currency,
            recipient: recipient,
            endTimestamp: endTimestamp,
            dataToken: dataToken
        });

        _dataByPublication[pubId] = _profilePublicationData;

        return data;
    }

    function processCollect(uint256 pubId, address collector, bytes calldata data) external onlyDataToken(pubId) {
        if (block.timestamp > _dataByPublication[pubId].endTimestamp) {
            revert Errors.CollectExpired();
        }
        if (_dataByPublication[pubId].currentCollects >= _dataByPublication[pubId].collectLimit) {
            revert Errors.ExceedCollectLimit();
        }
        ++_dataByPublication[pubId].currentCollects;
        _processCollect(collector, pubId, data);
    }

    function _processCollect(address collector, uint256 pubId, bytes calldata data) internal {
        ProfilePublicationData storage targetProfilePublicationData = _dataByPublication[pubId];
        _validateDataIsExpected(data, targetProfilePublicationData.currency, targetProfilePublicationData.amount);

        if (_isFeeFree[pubId][collector]) {
            _isFeeFree[pubId][collector] = false;
        } else {
            if (targetProfilePublicationData.amount > 0) {
                IERC20(targetProfilePublicationData.currency).safeTransferFrom(
                    collector, targetProfilePublicationData.recipient, targetProfilePublicationData.amount
                );
            }
        }
    }

    function _validateDataIsExpected(bytes calldata data, address currency, uint256 amount) internal pure {
        (address decodedCurrency, uint256 decodedAmount) = abi.decode(data, (address, uint256));
        if (decodedAmount != amount || decodedCurrency != currency) {
            revert Errors.ModuleDataMismatch();
        }
    }

    function getPublicationData(uint256 pubId) external view returns (ProfilePublicationData memory) {
        return _dataByPublication[pubId];
    }

    function _isFromDataToken(uint256 pubId) internal view override {
        if (_dataByPublication[pubId].dataToken != msg.sender) {
            revert Errors.NotDataToken();
        }
    }
}
