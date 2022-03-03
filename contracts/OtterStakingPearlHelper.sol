// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './interfaces/IERC20.sol';
import './interfaces/IPearlERC20.sol';
import './interfaces/IOtterStaking.sol';

contract OtterStakingPearlHelper {
    IOtterStaking public immutable staking;
    IERC20 public immutable CLAM;
    IERC20 public immutable sCLAM;
    IPearlERC20 public immutable PEARL;

    constructor(
        address _staking,
        address _CLAM,
        address _sCLAM,
        address _PEARL
    ) {
        require(_staking != address(0));
        staking = IOtterStaking(_staking);
        require(_CLAM != address(0));
        CLAM = IERC20(_CLAM);
        require(_sCLAM != address(0));
        sCLAM = IERC20(_sCLAM);
        require(_PEARL != address(0));
        PEARL = IPearlERC20(_PEARL);
    }

    function stake(uint256 _amount) external returns (uint256) {
        CLAM.transferFrom(msg.sender, address(this), _amount);
        CLAM.approve(address(staking), _amount);
        staking.stake(_amount, address(this));
        staking.claim(address(this));
        sCLAM.approve(address(PEARL), _amount);
        uint256 pearlAmount = PEARL.wrap(_amount);
        PEARL.transfer(msg.sender, pearlAmount);
        return pearlAmount;
    }

    function unstake(uint256 _amount) external returns (uint256) {
        PEARL.transferFrom(msg.sender, address(this), _amount);
        uint256 clamAmount = PEARL.unwrap(_amount);
        sCLAM.approve(address(staking), clamAmount);
        staking.unstake(clamAmount, true);
        CLAM.transfer(msg.sender, clamAmount);
        return clamAmount;
    }
}
