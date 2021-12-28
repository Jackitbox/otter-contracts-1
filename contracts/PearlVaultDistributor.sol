// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.7.5;

import './interfaces/IOtterTreasury.sol';
import './interfaces/IPearlERC20.sol';
import './interfaces/IOtterStaking.sol';
import './interfaces/IStakingDistributor.sol';

import './types/ERC20.sol';
import './types/Ownable.sol';

import './libraries/SafeERC20.sol';

contract PearlVaultDistributor is Ownable, IStakingDistributor {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /* ====== VARIABLES ====== */

    IERC20 public immutable clam;
    IERC20 public immutable sClam;
    IPearlERC20 public pearl;
    IOtterStaking public staking;
    IStakingDistributor public distributor;

    uint256 public immutable epochLength; // seconds
    uint256 public nextEpochTime; // unix epoch time in seconds

    Adjust public adjustment;

    /* ====== STRUCTS ====== */

    address public vault;
    uint256 public rate;

    struct Adjust {
        bool add;
        uint256 rate;
        uint256 target;
    }

    /* ====== CONSTRUCTOR ====== */

    constructor(
        address pearl_,
        address clam_,
        address sClam_,
        address staking_,
        address vault_,
        uint256 epochLength_,
        uint256 nextEpochTime_
    ) {
        require(pearl_ != address(0));
        pearl = IPearlERC20(pearl_);
        require(clam_ != address(0));
        clam = IERC20(clam_);
        require(sClam_ != address(0));
        sClam = IERC20(sClam_);
        require(staking_ != address(0));
        staking = IOtterStaking(staking_);
        require(vault_ != address(0));
        vault = vault_;

        epochLength = epochLength_;
        nextEpochTime = nextEpochTime_;
    }

    /* ====== PUBLIC FUNCTIONS ====== */

    /**
        @notice send epoch reward to staking contract
     */
    function distribute() external override returns (bool) {
        if (nextEpochTime <= block.timestamp) {
            nextEpochTime = nextEpochTime.add(epochLength); // set next epoch time
            if (rate > 0) {
                if (address(distributor) != address(0)) {
                    distributor.distribute();
                }

                uint256 reward = nextRewardAt(rate);
                require(
                    clam.balanceOf(address(this)) >= reward,
                    'PearlVaultDistributor: clam balance lower than reward'
                );

                // stake
                clam.safeApprove(address(staking), reward);
                staking.stake(reward, address(this));
                staking.claim(address(this));

                // convert sCLAM to PEARL
                sClam.safeApprove(address(pearl), reward);
                uint256 pearlAmount = pearl.wrap(reward);
                pearl.transfer(vault, pearlAmount);
            }
            adjust(); // check for adjustment
            return true;
        } else {
            return false;
        }
    }

    /* ====== INTERNAL FUNCTIONS ====== */

    /**
        @notice increment reward rate for collector
     */
    function adjust() internal {
        if (adjustment.rate != 0) {
            if (adjustment.add) {
                // if rate should increase
                rate = rate.add(adjustment.rate); // raise rate
                if (rate >= adjustment.target) {
                    // if target met
                    rate = 0; // turn off adjustment
                }
            } else {
                // if rate should decrease
                rate = rate.sub(adjustment.rate); // lower rate
                if (rate <= adjustment.target) {
                    // if target met
                    rate = 0; // turn off adjustment
                }
            }
        }
    }

    /* ====== VIEW FUNCTIONS ====== */

    /**
        @notice view function for next reward at given rate
        @param _rate uint
        @return uint
     */
    function nextRewardAt(uint256 _rate) public view returns (uint256) {
        return clam.balanceOf(address(this)).mul(_rate).div(1000000);
    }

    /**
        @notice view function for next reward for specified address
        @return uint
     */
    function nextReward() public view returns (uint256) {
        return nextRewardAt(rate);
    }

    /* ====== POLICY FUNCTIONS ====== */

    /**
        @notice set adjustment info for a collector's reward rate
        @param _add bool
        @param _rate uint
        @param _target uint
     */
    function setAdjustment(
        bool _add,
        uint256 _rate,
        uint256 _target
    ) external onlyOwner {
        adjustment = Adjust({add: _add, rate: _rate, target: _target});
    }

    function setRate(uint256 rate_) external onlyOwner {
        rate = rate_;
    }

    function setStaking(address staking_) external onlyOwner {
        staking = IOtterStaking(staking_);
    }

    function setDistributor(address distributor_) external onlyOwner {
        distributor = IStakingDistributor(distributor_);
    }
}
