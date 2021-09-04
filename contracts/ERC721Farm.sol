// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/interfaces/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/structs/EnumerableSet.sol';

import './IMagic.sol';

contract ERC721Farm is IERC721Receiver {
    using EnumerableSet for EnumerableSet.UintSet;

    address private immutable MAGIC;
    address private immutable ERC721_CONTRACT;
    uint256 public immutable EXPIRATION;
    uint256 private immutable RATE;

    mapping(address => EnumerableSet.UintSet) private _deposits;
    mapping(address => mapping(uint256 => uint256)) public depositBlocks;

    constructor(
        address magic,
        address erc721,
        uint256 rate,
        uint256 expiration
    ) {
        MAGIC = magic;
        ERC721_CONTRACT = erc721;
        RATE = rate;
        EXPIRATION = expiration + block.number;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function depositsOf(address account)
        external
        view
        returns (uint256[] memory)
    {
        EnumerableSet.UintSet storage depositSet = _deposits[account];
        uint256[] memory tokenIds = new uint256[](depositSet.length());

        for (uint256 i; i < depositSet.length(); i++) {
            tokenIds[i] = depositSet.at(i);
        }

        return tokenIds;
    }

    function calculateReward(address account, uint256 tokenId)
        public
        view
        returns (uint256 reward)
    {
        reward =
            RATE *
            (_deposits[msg.sender].contains(tokenId) ? 1 : 0) *
            (Math.min(block.number, EXPIRATION) -
                depositBlocks[account][tokenId]);
    }

    function claimReward(uint256 tokenId) public {
        uint256 reward = calculateReward(msg.sender, tokenId);

        if (reward > 0) {
            IMagic(MAGIC).mint(msg.sender, reward);
        }

        depositBlocks[msg.sender][tokenId] = Math.min(block.number, EXPIRATION);
    }

    function deposit(uint256 tokenId) public {
        claimReward(tokenId);
        IERC721(ERC721_CONTRACT).safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            ''
        );

        _deposits[msg.sender].add(tokenId);
    }

    function depositBatch(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            deposit(tokenIds[i]);
        }
    }

    function withdraw(uint256 tokenId) public {
        require(
            _deposits[msg.sender].contains(tokenId),
            'ERC721Farm: token not deposited'
        );

        claimReward(tokenId);

        _deposits[msg.sender].remove(tokenId);

        IERC721(ERC721_CONTRACT).safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            ''
        );
    }

    function withdrawBatch(uint256[] calldata tokenIds) external {
        for (uint256 i; i < tokenIds.length; i++) {
            withdraw(tokenIds[i]);
        }
    }
}
