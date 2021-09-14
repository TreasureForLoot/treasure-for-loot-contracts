// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/Math.sol';
import '@solidstate/contracts/token/ERC20/IERC20.sol';
import '@solidstate/contracts/utils/SafeERC20.sol';

import '../token/IMagic.sol';

contract MagicFarm {
    using SafeERC20 for IERC20;

    address private immutable MAGIC;
    address private immutable MAGIC_ETH_LP;
    uint256 public immutable EXPIRATION;
    uint256 private immutable RATE;

    mapping(address => uint256) public depositBalances;
    mapping(address => uint256) public depositBlocks;

    constructor(
        address magic,
        address magicEthLp,
        uint256 rate,
        uint256 expiration
    ) {
        MAGIC = magic;
        MAGIC_ETH_LP = magicEthLp;
        RATE = rate;
        EXPIRATION = block.number + expiration;
    }

    function calculateRewards(address account)
        public
        view
        returns (uint256 reward)
    {
        reward =
            (RATE *
                depositBalances[account] *
                (Math.min(block.number, EXPIRATION) - depositBlocks[account])) /
            (1 ether);
    }

    function claimRewards() public {
        uint256 reward = calculateRewards(msg.sender);

        if (reward > 0) {
            IMagic(MAGIC).mint(msg.sender, reward);
        }

        depositBlocks[msg.sender] = Math.min(block.number, EXPIRATION);
    }

    function deposit(uint256 amount) external {
        require(
            IERC20(MAGIC_ETH_LP).balanceOf(address(this)) + amount <=
                50e6 ether,
            'MagicFarm: deposit cap reached'
        );
        claimRewards();
        IERC20(MAGIC_ETH_LP).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );
        depositBalances[msg.sender] += amount;
    }

    function withdraw(uint256 amount) external {
        require(
            depositBalances[msg.sender] >= amount,
            'MagicFarm: insufficient balance'
        );

        claimRewards();

        unchecked {
            depositBalances[msg.sender] -= amount;
        }

        IERC20(MAGIC_ETH_LP).safeTransfer(msg.sender, amount);
    }
}
