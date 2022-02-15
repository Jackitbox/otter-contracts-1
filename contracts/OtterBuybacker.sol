// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import './interfaces/IOtterTreasury.sol';

import './types/Ownable.sol';
import './types/ERC20.sol';

import './libraries/SafeMath.sol';

interface ICLAMERC20 {
    function burn(uint256 amount) external;
}

contract OtterBuybacker is Ownable {
    using SafeMath for uint256;

    event Buyback(
        address indexed token,
        uint256 tokenAmount,
        uint256 clamAmount
    );

    event RemoveLiquidity(
        address indexed lp,
        uint256 liquidity,
        uint256 token0Amount,
        uint256 token1Amount
    );

    IUniswapV2Router02 public immutable router;
    IOtterTreasury public immutable treasury;
    address public immutable clam;
    address public immutable dao;

    constructor(
        address swapRouter_,
        address treasury_,
        address clam_,
        address dao_
    ) {
        router = IUniswapV2Router02(swapRouter_);
        treasury = IOtterTreasury(treasury_);
        clam = clam_;
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

    /// @notice Buy back CLAM using treasury
    /// @param path_ the exhcnage path for buyback, first token must in treasury
    /// @param amount_ the amount in path_[0]
    function buyback(
        address[] memory path_,
        uint256 amount_,
        uint256 amountOutMin_
    ) external onlyOwner {
        IERC20 token = IERC20(path_[0]);
        treasury.manage(path_[0], amount_);

        token.approve(address(router), amount_);
        address[] memory path = new address[](path_.length + 1);
        for (uint256 i = 0; i < path_.length; i++) {
            path[i] = path_[i];
        }
        path[path_.length] = clam;
        uint256[] memory amounts = router.swapExactTokensForTokens(
            amount_,
            amountOutMin_,
            path,
            address(this),
            block.timestamp
        );

        uint256 clamBuyback = amounts[amounts.length - 1];
        IERC20(clam).transfer(dao, clamBuyback);

        emit Buyback(path_[0], amount_, clamBuyback);
    }

    /// @notice Remove Liquidity from the pool
    function removeLiquidity(
        address router_,
        address lp_,
        uint256 liquidity_,
        uint256 amountAMin_,
        uint256 amountBMin_
    ) external onlyOwner {
        treasury.manage(lp_, liquidity_);

        IUniswapV2Pair pair = IUniswapV2Pair(lp_);
        IUniswapV2Router02 theRouter = IUniswapV2Router02(router_);
        pair.approve(router_, liquidity_);

        (uint256 amountA, uint256 amountB) = theRouter.removeLiquidity(
            pair.token0(),
            pair.token1(),
            liquidity_,
            amountAMin_,
            amountBMin_,
            address(this),
            block.timestamp
        );

        if (pair.token0() == clam) {
            IERC20(pair.token0()).transfer(dao, amountA);
            IERC20(pair.token1()).transfer(address(treasury), amountB);
        } else {
            IERC20(pair.token0()).transfer(address(treasury), amountA);
            IERC20(pair.token1()).transfer(dao, amountB);
        }

        emit RemoveLiquidity(lp_, liquidity_, amountA, amountB);
    }

    function emergencyWithdraw(address token_) external onlyOwner {
        uint256 balance = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(dao, balance);
    }
}
