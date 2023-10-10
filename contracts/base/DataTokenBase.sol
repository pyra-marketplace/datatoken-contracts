// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {DataTypes} from "../libraries/DataTypes.sol";

abstract contract DataTokenBase {
    address internal immutable DATA_TOKEN_HUB;
    address internal immutable DATA_TOKEN_FACTORY;

    DataTypes.Metadata internal _metadata;
    string internal _contentURI;

    constructor(address dataTokenHub, string memory contentURI, DataTypes.Metadata memory metadata) {
        _metadata = metadata;

        DATA_TOKEN_HUB = dataTokenHub;
        DATA_TOKEN_FACTORY = msg.sender;

        _contentURI = contentURI;
    }

    modifier onlyDataTokenOwner() {
        _checkDataTokenOwner();
        _;
    }

    function _checkDataTokenOwner() internal virtual;
}
