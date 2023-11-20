// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {Proxy} from "@openzeppelin/contracts/proxy/Proxy.sol";
import {ERC1967Upgrade} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Upgrade.sol";

contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _changeAdmin(msg.sender);
        _upgradeToAndCall(_logic, _data, false);
    }

    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }

    function getImplementation() external view returns (address) {
        return _implementation();
    }

    function upgradeTo(address implementation) external ifAdmin {
        _upgradeTo(implementation);
    }
}
