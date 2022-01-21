// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import './interfaces/IOtterTreasury.sol';

import './types/Ownable.sol';
import './types/ERC20.sol';

import './libraries/SafeMath.sol';
import './libraries/SafeERC20.sol';

contract OtterLPConverter is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public immutable source;
    IERC20 public immutable target;
    IUniswapV2Router02 public immutable router;
    IOtterTreasury public immutable treasury;

    constructor(
        address source_,
        address target_,
        address swapRouter_,
        address treasury_
    ) {
        source = IERC20(source_);
        target = IERC20(target_);
        router = IUniswapV2Router02(swapRouter_);
        treasury = IOtterTreasury(treasury_);
    }

    /// @notice Swap certain amount of source to source/target LP
    /// @param amount_ the amount in source
    function addLiquidity(uint256 amount_) external onlyOwner {
        treasury.manage(address(source), amount_);

        uint256 halfAmount = amount_.div(2);
        source.safeApprove(address(router), halfAmount);
        address[] memory path = new address[](2);
        path[0] = address(source);
        path[1] = address(target);
        router.swapExactTokensForTokens(
            halfAmount,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 sourceBalance = source.balanceOf(address(this));
        uint256 targetBalance = target.balanceOf(address(this));

        source.safeApprove(address(router), sourceBalance);
        target.safeApprove(address(router), targetBalance);

        router.addLiquidity(
            address(source),
            address(target),
            sourceBalance,
            targetBalance,
            1,
            1,
            address(this),
            block.timestamp
        );
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());
        IERC20 lp = IERC20(factory.getPair(address(source), address(target)));
        uint256 lpBalance = lp.balanceOf(address(this));
        lp.safeApprove(address(treasury), lpBalance);
        uint256 profit = treasury.valueOfToken(address(lp), lpBalance);
        treasury.deposit(lpBalance, address(lp), profit);
    }
}
