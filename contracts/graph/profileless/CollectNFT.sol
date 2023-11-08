// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Errors} from "./libraries/Errors.sol";
import {ProfilelessHub} from "./ProfilelessHub.sol";

contract CollectNFT is ERC721Enumerable {
    uint256 private _tokenIdCount = 0;
    address internal immutable PROFILELESS_HUB;

    constructor(address profilelessHub) ERC721("Profileless Collect NFT", "PCN") {
        PROFILELESS_HUB = profilelessHub;
    }

    modifier onlyHub() {
        if (msg.sender != PROFILELESS_HUB) {
            revert Errors.NotProfilelessHub();
        }
        _;
    }

    function mintCollectNFT(address to) external onlyHub returns (uint256) {
        _safeMint(to, _tokenIdCount);
        return _tokenIdCount++;
    }
}
