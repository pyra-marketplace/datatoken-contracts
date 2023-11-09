// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ICollectModule} from "./interfaces/ICollectModule.sol";

contract PublicateNFT is ERC721Enumerable {
    uint256 internal _tokenIdCount = 0;

    constructor() ERC721("Profileless Publicate NFT", "PPN") {}

    function _mintPublicateNFT(address to) internal returns (uint256 tokenId) {
        tokenId = _tokenIdCount;
        _safeMint(to, _tokenIdCount++);
    }
}
