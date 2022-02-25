// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import '../interfaces/IOtterTreasury.sol';
import '../interfaces/IProxyUniswapV2Pair.sol';

import '../types/Ownable.sol';
import '../types/ERC20Permit.sol';

import '../libraries/SafeMath.sol';

interface IStakingRewards {
    // Views
    function lastTimeRewardApplicable() external view returns (uint256);

    function rewardPerToken() external view returns (uint256);

    function earned(address account) external view returns (uint256);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    // Mutative
    function stake(uint256 amount) external;

    function withdraw(uint256 amount) external;

    function getReward() external;

    function exit() external;
}

contract OtterQuickSwapInvestment is ERC20Permit, Ownable, IProxyUniswapV2Pair {
    using SafeMath for uint256;

    IUniswapV2Pair public immutable lp;
    IERC20 public immutable dQuick;
    IStakingRewards public immutable quickStaking;
    IOtterTreasury public immutable treasury;
    address public immutable dao;

    constructor(
        address lp_,
        address dQuick_,
        address quickStaking_,
        address treasury_,
        address dao_
    ) ERC20('QuickSwap Staking', 'QUICKSWAP', 18) {
        lp = IUniswapV2Pair(lp_);
        dQuick = IERC20(dQuick_);
        quickStaking = IStakingRewards(quickStaking_);
        treasury = IOtterTreasury(treasury_);
        dao = dao_;
    }

    function token0() external view override returns (address) {
        return lp.token0();
    }

    function token1() external view override returns (address) {
        return lp.token1();
    }

    function getReserves()
        external
        view
        override
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        )
    {
        return lp.getReserves();
    }

    function totalSupply() public view override returns (uint256) {
        return lp.totalSupply();
    }

    /// @notice Stake LP to QuickSwap farm
    /// @param amount_ the amount of lp
    function stake(uint256 amount_) external onlyOwner {
        treasury.manage(address(lp), amount_);
        lp.approve(address(quickStaking), amount_);
        quickStaking.stake(amount_);

        uint256 deposited = quickStaking.balanceOf(address(this));
        uint256 newMint = deposited.sub(_totalSupply);
        uint256 profit = treasury.valueOfToken(address(lp), newMint);
        _mint(address(this), newMint);
        _approve(address(this), address(treasury), newMint);
        treasury.deposit(newMint, address(this), profit);
    }

    function withdraw(uint256 amount_) external onlyOwner {
        quickStaking.withdraw(amount_);

        uint256 lpBalance = lp.balanceOf(address(this));
        lp.approve(address(treasury), lpBalance);
        uint256 profit = treasury.valueOfToken(address(lp), lpBalance);
        treasury.deposit(lpBalance, address(lp), profit);

        uint256 deposited = quickStaking.balanceOf(address(this));
        uint256 burned = _totalSupply.sub(deposited);
        treasury.manage(address(this), burned);
        _burn(address(this), burned);
    }

    function harvest() external {
        quickStaking.getReward();
        uint256 balance = dQuick.balanceOf(address(this));
        dQuick.transfer(address(treasury), balance);
    }

    function emergencyWithdraw(address token_) external onlyOwner {
        uint256 balance = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(dao, balance);
    }
}
