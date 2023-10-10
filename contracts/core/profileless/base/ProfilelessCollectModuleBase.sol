// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {IDataTokenModule} from "../interface/IDataTokenModule.sol";
import {Errors} from "../../../libraries/Errors.sol";
import {Events} from "../../../libraries/Events.sol";

abstract contract ProfilelessCollectModuleBase is IDataTokenModule {
    address internal immutable DATA_TOKEN_HUB;

    mapping(address => mapping(address => bool)) internal _isRequestByCollectorByDataToken;

    constructor(address dataTokenHub) {
        if (dataTokenHub == address(0)) {
            revert Errors.ZeroAddress();
        }
        DATA_TOKEN_HUB = dataTokenHub;
        emit Events.DataTokenCollectModuleBaseConstructed(dataTokenHub, address(this), block.timestamp);
    }

    modifier onlyDataToken(uint256 id) {
        _isFromDataToken(id);
        _;
    }

    function _isFromDataToken(uint256 id) internal virtual;
}
