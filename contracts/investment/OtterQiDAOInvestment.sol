// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

import '../interfaces/IOtterTreasury.sol';
import '../interfaces/IProxyUniswapV2Pair.sol';

import '../types/Ownable.sol';
import '../types/ERC20Permit.sol';

import '../libraries/SafeMath.sol';
import '../libraries/SafeERC20.sol';

interface IQiFarm {
    // View function to see deposited LP for a user.
    function deposited(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    // View function to see pending ERC20s for a user.
    function pending(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    // Deposit LP tokens to Farm for ERC20 allocation.
    function deposit(uint256 _pid, uint256 _amount) external;

    // Withdraw LP tokens from Farm.
    function withdraw(uint256 _pid, uint256 _amount) external;
}

contract OtterQiDAOInvestment is ERC20Permit, Ownable, IProxyUniswapV2Pair {
    using SafeMath for uint256;

    IUniswapV2Pair public immutable lp;
    IERC20 public immutable qi;
    IQiFarm public immutable qiFarm;
    IOtterTreasury public immutable treasury;

    constructor(
        address lp_,
        address qi_,
        address qiFarm_,
        address treasury_
    ) ERC20('Qi Staking', 'QISTAKING', 18) {
        lp = IUniswapV2Pair(lp_);
        qi = IERC20(qi_);
        qiFarm = IQiFarm(qiFarm_);
        treasury = IOtterTreasury(treasury_);
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

    /// @notice Stake lp to Qi farm
    /// @param amount_ the amount of lp
    function stake(uint256 pid_, uint256 amount_) external onlyOwner {
        treasury.manage(address(lp), amount_);
        lp.approve(address(qiFarm), amount_);
        qiFarm.deposit(pid_, amount_);

        uint256 deposited = qiFarm.deposited(pid_, address(this));
        uint256 newMint = deposited.sub(_totalSupply);
        uint256 profit = treasury.valueOfToken(address(lp), newMint);
        _mint(address(this), newMint);
        _approve(address(this), address(treasury), newMint);
        treasury.deposit(newMint, address(this), profit);
    }

    function unstake(uint256 pid_, uint256 amount_) external onlyOwner {
        qiFarm.withdraw(pid_, amount_);

        uint256 lpBalance = lp.balanceOf(address(this));
        lp.approve(address(treasury), lpBalance);
        uint256 profit = treasury.valueOfToken(address(lp), lpBalance);
        treasury.deposit(lpBalance, address(lp), profit);

        uint256 deposited = qiFarm.deposited(pid_, address(this));
        uint256 burned = _totalSupply.sub(deposited);
        treasury.manage(address(this), burned);
        _burn(address(this), burned);
    }

    function harvest(uint256 pid_) external {
        qiFarm.deposit(pid_, 0);
        uint256 qiBalance = qi.balanceOf(address(this));
        qi.transfer(address(treasury), qiBalance);
    }
}
