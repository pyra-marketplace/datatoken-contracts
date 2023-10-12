// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {IDataTokenHub} from "../interfaces/IDataTokenHub.sol";
import {Constants} from "../libraries/Constants.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {Initializable} from "openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";

contract DataTokenHubMock is IDataTokenHub, Initializable {
    string public constant version = "2.0";

    address internal _governor;

    mapping(address => bool) internal _isDataTokenFactoryWhitelisted;

    mapping(address => bool) internal _isDataTokenRegistered;

    constructor() {}

    modifier onlyRegisteredDataToken() {
        if (!_isDataTokenRegistered[msg.sender]) {
            revert Errors.DataTokenNotRegistered(msg.sender);
        }
        _;
    }

    modifier onlyWhitelistedFactory() {
        if (!_isDataTokenFactoryWhitelisted[msg.sender]) {
            revert Errors.DataTokenFactoryNotWhitelisted();
        }
        _;
    }

    modifier onlyGovernor() {
        if (msg.sender != _governor) {
            revert Errors.NotGovernor();
        }
        _;
    }

    /**
     * @inheritdoc IDataTokenHub
     */
    function initialize() external initializer {
        _setGovernor(msg.sender);
    }

    /**
     * @inheritdoc IDataTokenHub
     */
    function whitelistDataTokenFactory(address factory, bool whitelistStatus) external onlyGovernor {
        if (factory == Constants.ZERO_ADDRESS) {
            revert Errors.ZeroAddress();
        }
        _isDataTokenFactoryWhitelisted[factory] = whitelistStatus;
        emit Events.DataTokenFactoryWhitelisted(factory, whitelistStatus);
    }

    /**
     * @inheritdoc IDataTokenHub
     */
    function registerDataToken(address dataTokenOwner, address originalContract, address dataToken)
        external
        onlyWhitelistedFactory
    {
        if (_isDataTokenRegistered[dataToken]) {
            revert Errors.DataTokenAlreadyRegistered(dataToken);
        }
        _isDataTokenRegistered[dataToken] = true;
        emit Events.DataTokenRegistered(dataTokenOwner, originalContract, dataToken);
    }

    /**
     * @inheritdoc IDataTokenHub
     */
    function isDataTokenFactoryWhitelisted(address factory) external view returns (bool) {
        return _isDataTokenFactoryWhitelisted[factory];
    }

    /**
     * @inheritdoc IDataTokenHub
     */
    function isDataTokenRegistered(address datatoken) external view returns (bool) {
        return _isDataTokenRegistered[datatoken];
    }

    /**
     * @inheritdoc IDataTokenHub
     */
    function emitCollected(address collector, address collectNFT, uint256 tokenId) external onlyRegisteredDataToken {
        emit Events.Collected(msg.sender, collector, collectNFT, tokenId);
    }

    /**
     * @inheritdoc IDataTokenHub
     */
    function setGovernor(address newGovernor) external onlyGovernor {
        _setGovernor(newGovernor);
    }

    /**
     * @inheritdoc IDataTokenHub
     */
    function getGovernor() external view override returns (address) {
        return _governor;
    }

    function _setGovernor(address newGovernor) internal virtual {
        if (newGovernor == Constants.ZERO_ADDRESS) {
            revert Errors.ZeroAddress();
        }
        address prevGovernor = _governor;
        _governor = newGovernor;
        emit Events.GovernorSet(prevGovernor, newGovernor, block.timestamp);
    }
}
