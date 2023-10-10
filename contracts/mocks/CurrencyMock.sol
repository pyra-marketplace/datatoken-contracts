// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract CurrencyMock is ERC20 {
    constructor(string memory name, string memory symbol) ERC20(name, symbol) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}