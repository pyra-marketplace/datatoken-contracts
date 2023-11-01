// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {ProfilelessDataTokenFactoryBase} from "./ProfilelessDataTokenFactoryBase.sol";
import {DataTokenBase} from "../../../base/DataTokenBase.sol";
import {Constants} from "../../../libraries/Constants.sol";
import {DataTypes} from "../../../libraries/DataTypes.sol";
import {Errors} from "../../../libraries/Errors.sol";

abstract contract ProfilelessDataTokenBase is ERC721Enumerable, DataTokenBase {
    uint256 private _tokenIdCount = 0;

    // bytes4(keccak256('royaltyInfo(uint256,uint256)')) == 0x2a55205a
    bytes4 internal constant INTERFACE_ID_ERC2981 = 0x2a55205a;
    uint256 internal _royaltyRate;

    constructor(address dataTokenHub, string memory contentURI, DataTypes.Metadata memory metadata)
        ERC721("Profileless Collection NFT", "PCN")
        DataTokenBase(dataTokenHub, contentURI, metadata)
    {}

    function setRoyalty(uint256 royaltyRate) external onlyDataTokenOwner {
        if (royaltyRate > Constants.BASIS_POINTS) {
            revert Errors.InvalidRoyaltyRate(royaltyRate, Constants.BASIS_POINTS);
        }
        _royaltyRate = royaltyRate;
    }

    function getRoyaltyInfo(uint256, uint256 salePrice) external view returns (address, uint256) {
        return (_getProfilelessTokenOwner(), (salePrice * _royaltyRate) / Constants.BASIS_POINTS);
    }

    function _mintCollectNFT(address to) internal returns (uint256) {
        _safeMint(to, _tokenIdCount);
        return _tokenIdCount++;
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == INTERFACE_ID_ERC2981;
    }

    function _getProfilelessTokenOwner() internal view returns (address) {
        return ProfilelessDataTokenFactoryBase(DATA_TOKEN_FACTORY).getOwnerByDataToken(address(this));
    }

    /**
     * @inheritdoc DataTokenBase
     */
    function _checkDataTokenOwner() internal view override {
        if (msg.sender != _getProfilelessTokenOwner()) {
            revert Errors.NotDataTokenOwner();
        }
    }
}
