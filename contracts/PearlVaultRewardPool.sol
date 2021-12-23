// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './interfaces/IERC20.sol';
import './interfaces/IRewardPool.sol';

import './libraries/SafeMath.sol';
import './libraries/SafeERC20.sol';

import './types/Pausable.sol';
import './types/ReentrancyGuard.sol';
import './types/VaultOwned.sol';

contract PearlVaultRewardPool is
    IRewardPool,
    ReentrancyGuard,
    Pausable,
    VaultOwned
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ========== EVENTS ========== */
    event Recovered(address token, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    /* ========== STATE VARIABLES ========== */
    IERC20 public immutable pearl;

    /* ========== CONSTRUCTOR ========== */
    constructor(address _pearl) {
        pearl = IERC20(_pearl);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function claimReward(address user, uint256 reward)
        external
        override
        nonReentrant
        onlyVault
    {
        require(reward > 0, 'reward must > 0');
        require(user != address(0), 'claim reward with address 0');
        pearl.safeTransfer(user, reward);
        emit RewardPaid(user, reward);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(tokenAddress != address(pearl), 'Cannot withdraw pearl');
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }
}
