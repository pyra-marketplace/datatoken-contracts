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
    address internal _profilelessHub = address(0);

    address[] internal _currencys;

    function _baseSetUp() internal {
        if (block.chainid == POLYGON) {
            _lensHubProxy = 0xDb46d1Dc155634FbC732f92E853b10B288AD5a1d;
        }
        if (block.chainid == MUMBAI) {
            _lensHubProxy = 0xC1E77eE73403B8a7478884915aA599932A677870;

            address WMATIC = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889;
            address WETH = 0x3C68CE8504087f89c640D02d133646d98e64ddd9;
            address USDC = 0x2058A9D7613eEE744279e3856Ef0eAda5FCbaA7e;
            address DAI = 0x001B3B4d0F3714Ca98ba10F6042DaEbF0B1B7b6F;

            _currencys.push(WMATIC);
            _currencys.push(WETH);
            _currencys.push(USDC);
            _currencys.push(DAI);
        }
        if (block.chainid == BSC) {
            _cyberProfileProxy = 0x2723522702093601e6360CAe665518C4f63e9dA6;
        }
        if (block.chainid == BSCT) {
            _cyberProfileProxy = 0x57e12b7a5F38A7F9c23eBD0400e6E53F2a45F271;
        }
    }
}
