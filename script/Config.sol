// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

contract Config {
    uint256 internal constant BSCT = 97;
    uint256 internal constant BSC = 56;
    uint256 internal constant POLYGON = 137;
    uint256 internal constant MUMBAI = 80001;

    uint256 internal _privateKey;

    address internal _lensHubProxy = address(0);
    address internal _cyberProfileProxy = address(0);

    function _baseSetUp() internal {
        if (block.chainid == POLYGON) {
            _lensHubProxy = 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d;
        }
        if (block.chainid == MUMBAI) {
            _lensHubProxy = 0x60Ae865ee4C725cd04353b5AAb364553f56ceF82;
        }
        if (block.chainid == BSC) {
            _cyberProfileProxy = 0x2723522702093601e6360CAe665518C4f63e9dA6;
        }
        if (block.chainid == BSCT) {
            _cyberProfileProxy = 0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271;
        }
    }
}
