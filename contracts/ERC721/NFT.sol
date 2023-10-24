// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

abstract contract NFT is ERC721, Ownable {
    uint256 counter;
    uint256 price = 2 ether;
    uint priceLevelUp = 1 ether;

    struct Nft {
        string name;
        uint256 id;
        uint8 level;
        uint8 rarity;
    }

    Nft[] nfts;
}