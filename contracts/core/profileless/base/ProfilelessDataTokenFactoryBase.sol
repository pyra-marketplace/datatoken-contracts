// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.10;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";

contract ProfilelessDataTokenFactoryBase is ERC721 {
    uint256 internal _tokenIdCount = 0;

    mapping(address => uint256) internal _tokenIdByDataToken;

    constructor() ERC721("ProfilelessTokenFactory", "DataToken") {}

    function _mintPublicationNFT(address to) internal returns (uint256) {
        _safeMint(to, _tokenIdCount);
        return _tokenIdCount++;
    }

    function getOwnerByDataToken(address dataToken) external view returns (address) {
        return ownerOf(_tokenIdByDataToken[dataToken]);
    }

    function getPubIdByDataToken(address dataToken) external view returns (uint256) {
        return _tokenIdByDataToken[dataToken];
    }
}
