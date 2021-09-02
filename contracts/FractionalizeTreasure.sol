// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

import './ITreasure.sol';

abstract contract FractionalizeTreasure is ERC1155 {
    address public treasureAddress = 0xf3DFbE887D81C442557f7a59e3a0aEcf5e39F6aa;
    ITreasure public treasureContract = ITreasure(treasureAddress);

    struct Item {
    string name;
    uint value;
    }

    mapping (uint256 => string) private itemNames;
    mapping (uint256 => uint256) private itemValues;

    constructor (Item[] memory items) {
    itemNames[uint256(keccak256("Red Feather""Snow White Feather"))] = "Red and White Feather";
    itemValues[uint256(keccak256("Red Feather""Snow White Feather"))] = 100;

    for (uint i; i < items.length; i++) {
        uint tokenId = uint256(keccak256(abi.encodePacked(items[i].name)));
        itemNames[tokenId] = items[i].name;
        itemValues[tokenId] = items[i].value;
        }
    }


    function decompose(uint256 tokenId) public returns (string[] memory) {
        // TODO: ERC721 transfer of tokenId to address(this)
        // safeTransferFrom(msg.sender, this, tokenId);

        uint256[] memory ids = new uint256[](8);
        ids[0] = uint256(keccak256(abi.encodePacked(treasureContract.getAsset1(tokenId))));
        ids[1] = uint256(keccak256(abi.encodePacked(treasureContract.getAsset2(tokenId))));
        ids[2] = uint256(keccak256(abi.encodePacked(treasureContract.getAsset3(tokenId))));
        ids[3] = uint256(keccak256(abi.encodePacked(treasureContract.getAsset4(tokenId))));
        ids[4] = uint256(keccak256(abi.encodePacked(treasureContract.getAsset5(tokenId))));
        ids[5] = uint256(keccak256(abi.encodePacked(treasureContract.getAsset6(tokenId))));
        ids[6] = uint256(keccak256(abi.encodePacked(treasureContract.getAsset7(tokenId))));
        ids[7] = uint256(keccak256(abi.encodePacked(treasureContract.getAsset8(tokenId))));

        uint256[] memory amounts = new uint256[](8);
        ids[0] = 1;
        ids[1] = 1;
        ids[2] = 1;
        ids[3] = 1;
        ids[4] = 1;
        ids[5] = 1;
        ids[6] = 1;
        ids[7] = 1;

        _mintBatch(msg.sender, ids, amounts, '');
    }
}
