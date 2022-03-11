// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

import '../interfaces/IOtterTreasury.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IQiFarm.sol';

import '../types/OperatorOwnedUpgradeable.sol';

import '../libraries/SafeMath.sol';

contract OtterQiDAOCurveStaking is
    ERC20Upgradeable,
    OperatorOwnedUpgradeable,
    UUPSUpgradeable
{
    using SafeMath for uint256;

    event Stake(uint256 amount, uint256 blockNumber);
    event Unstake(uint256 amount);
    event Harvest(uint256 amount);

    IERC20 public curveLp;
    IERC20 public qi;
    IQiFarm public qiFarm;
    IOtterTreasury public treasury;
    address public dao;

    function initialize(
        address curveLp_,
        address qi_,
        address qiFarm_,
        address treasury_,
        address dao_
    ) public initializer {
        __ERC20_init('Qi Curve Staking', 'QICURVE');
        __Ownable_init();
        curveLp = IERC20(curveLp_);
        qi = IERC20(qi_);
        qiFarm = IQiFarm(qiFarm_);
        treasury = IOtterTreasury(treasury_);
        dao = dao_;
    }

    /// @notice Stake curveLp to Qi farm
    /// @param amount_ the amount of curveLp
    function stake(
        uint256 pid_,
        uint256 amount_,
        bool useManage_,
        bool useDeposit_
    ) external onlyOperator {
        if (useManage_) {
            treasury.manage(address(curveLp), amount_);
        }
        curveLp.approve(address(qiFarm), amount_);
        qiFarm.deposit(pid_, amount_);

        uint256 deposited = qiFarm.deposited(pid_, address(this));
        uint256 newMint = deposited.sub(totalSupply());
        if (useDeposit_) {
            uint256 profit = treasury.valueOfToken(address(curveLp), newMint);
            _mint(address(this), newMint);
            _approve(address(this), address(treasury), newMint);
            treasury.deposit(newMint, address(this), profit);
        } else {
            _mint(address(treasury), newMint);
        }
    }

    function unstake(uint256 pid_, uint256 amount_) external onlyOperator {
        qiFarm.withdraw(pid_, amount_);

        uint256 lpBalance = curveLp.balanceOf(address(this));
        curveLp.approve(address(treasury), lpBalance);
        uint256 profit = treasury.valueOfToken(address(curveLp), lpBalance);
        treasury.deposit(lpBalance, address(curveLp), profit);

        uint256 deposited = qiFarm.deposited(pid_, address(this));
        uint256 burned = totalSupply().sub(deposited);
        treasury.manage(address(this), burned);
        _burn(address(this), burned);
    }

    function harvest(uint256 pid_) external {
        qiFarm.deposit(pid_, 0);
        uint256 qiBalance = qi.balanceOf(address(this));
        qi.transfer(address(treasury), qiBalance);
    }

    function emergencyWithdraw(address token_) external onlyOwner {
        uint256 balance = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(dao, balance);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
