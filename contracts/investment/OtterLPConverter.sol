// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import '../interfaces/IOtterTreasury.sol';

import '../types/Ownable.sol';
import '../types/ERC20.sol';

import '../libraries/SafeMath.sol';

interface CurveZapDepositor {
    function exchange_underlying(
        address pool,
        int128 i,
        int128 j,
        uint256 dx,
        uint256 min_dy
    ) external returns (uint256);
}

interface CurveMetaPool {
    function get_dy_underlying(
        int128 i,
        int128 j,
        uint256 dx
    ) external returns (uint256);
}

contract OtterLPConverter is Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 public immutable router;
    CurveZapDepositor public immutable curveZap;
    IOtterTreasury public immutable treasury;
    address public immutable dao;

    constructor(
        address swapRouter_,
        address curveZap_,
        address treasury_,
        address dao_
    ) {
        router = IUniswapV2Router02(swapRouter_);
        curveZap = CurveZapDepositor(curveZap_);
        treasury = IOtterTreasury(treasury_);
        dao = dao_;
    }

    function lpAddress(address source_, address target_)
        public
        view
        returns (address)
    {
        return
            IUniswapV2Factory(router.factory()).getPair(
                address(source_),
                address(target_)
            );
    }

    /// @notice Swap certain amount of source to source/target LP
    /// @param amount_ the amount in source
    function addLiquidity(
        address source_,
        address target_,
        uint256 amount_
    ) external onlyOwner {
        IERC20 source = IERC20(source_);
        IERC20 target = IERC20(target_);
        treasury.manage(address(source), amount_);

        uint256 currentBalance = source.balanceOf(address(this));
        uint256 halfAmount = currentBalance.div(2);
        source.approve(address(router), halfAmount);
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

        source.approve(address(router), sourceBalance);
        target.approve(address(router), targetBalance);

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
        IERC20 lp = IERC20(lpAddress(source_, target_));
        uint256 lpBalance = lp.balanceOf(address(this));
        lp.approve(address(treasury), lpBalance);
        uint256 profit = treasury.valueOfToken(address(lp), lpBalance);
        treasury.deposit(lpBalance, address(lp), profit);
    }

    /// @notice Create LP from token1, token2, return left to treasury
    function addLiquidityNoSwap(
        address token1_,
        uint256 amount1_,
        address token2_,
        uint256 amount2_,
        bool useDeposit_
    ) external onlyOwner {
        IERC20 token1 = IERC20(token1_);
        IERC20 token2 = IERC20(token2_);
        treasury.manage(token1_, amount1_);
        treasury.manage(token2_, amount2_);

        token1.approve(address(router), amount1_);
        token2.approve(address(router), amount2_);

        router.addLiquidity(
            token1_,
            token2_,
            amount1_,
            amount2_,
            1,
            1,
            address(this),
            block.timestamp
        );
        IERC20 lp = IERC20(lpAddress(token1_, token2_));
        uint256 lpBalance = lp.balanceOf(address(this));

        if (useDeposit_) {
            lp.approve(address(treasury), lpBalance);
            uint256 profit = treasury.valueOfToken(address(lp), lpBalance);
            treasury.deposit(lpBalance, address(lp), profit);
        } else {
            lp.transfer(address(treasury), lpBalance);
        }

        token1.transfer(address(treasury), token1.balanceOf(address(this)));
        token2.transfer(address(treasury), token2.balanceOf(address(this)));
    }

    /// @notice Swap certain amount of source to source/target LP through curve
    /// @param amount_ the amount in source
    function addLiquidityCurve(
        address source_,
        address target_,
        address pool_,
        int128 i_,
        int128 j_,
        uint256 amount_
    ) external onlyOwner {
        IERC20 source = IERC20(source_);
        IERC20 target = IERC20(target_);
        treasury.manage(address(source), amount_);

        uint256 currentBalance = source.balanceOf(address(this));
        uint256 halfAmount = currentBalance.div(2);
        source.approve(address(curveZap), halfAmount);
        curveZap.exchange_underlying(pool_, i_, j_, halfAmount, 0);

        uint256 sourceBalance = source.balanceOf(address(this));
        uint256 targetBalance = target.balanceOf(address(this));

        source.approve(address(router), sourceBalance);
        target.approve(address(router), targetBalance);

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
        IERC20 lp = IERC20(lpAddress(source_, target_));
        uint256 lpBalance = lp.balanceOf(address(this));
        lp.approve(address(treasury), lpBalance);
        uint256 profit = treasury.valueOfToken(address(lp), lpBalance);
        treasury.deposit(lpBalance, address(lp), profit);
    }

    function emergencyWithdraw(address token_) external onlyOwner {
        uint256 balance = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(dao, balance);
    }
}
