// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.7.5;

import '../interfaces/IERC20.sol';
import '../interfaces/IStakingDistributor.sol';

import '../types/ERC20.sol';

import '../libraries/SafeERC20.sol';

contract MockDistributor is IStakingDistributor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ====== VARIABLES ====== */

    IERC20 public pearl;
    address public vault;

    /* ====== CONSTRUCTOR ====== */

    constructor(address pearl_, address vault_) {
        require(pearl_ != address(0));
        pearl = IERC20(pearl_);
        vault = vault_;
    }

    /* ====== PUBLIC FUNCTIONS ====== */

    /**
        @notice send epoch reward to staking contract
     */
    function distribute() external override returns (bool) {
        uint256 amount = pearl.balanceOf(address(this));
        pearl.transfer(vault, amount);
        return true;
    }
}
