// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

import '../interfaces/IOtterTreasury.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IOtterClamQi.sol';

import '../types/LockerOwnedUpgradeable.sol';

contract OtterQiLocker is LockerOwnedUpgradeable, UUPSUpgradeable {
    event Lock(uint256 amount, uint256 blockNumber);
    event Leave(uint256 amount);
    event Harvest(uint256 amount);

    IERC20 public qi;
    IOtterClamQi public ocQi;
    IOtterTreasury public treasury;
    address public dao;

    function initialize(
        address qi_,
        address ocQi_,
        address treasury_,
        address dao_
    ) public initializer {
        __Ownable_init();
        qi = IERC20(qi_);
        ocQi = IOtterClamQi(ocQi_);
        treasury = IOtterTreasury(treasury_);
        dao = dao_;
    }

    /// @notice Lock Qi to QiDAO and mint ocQi to treasury
    /// @param amount_ the amount of qi
    /// @param blockNumber_ the block number going to locked
    function lock(uint256 amount_, uint256 blockNumber_) public onlyLocker {
        treasury.manage(address(qi), amount_);
        qi.approve(address(ocQi), amount_);
        ocQi.lock(address(treasury), amount_, blockNumber_);
        emit Lock(amount_, blockNumber_);
    }

    /// @notice Unlock Qi from QiDAO and burn ocQi
    function unlock() external onlyLocker {
        uint256 treasuryAmount = IERC20(address(ocQi)).balanceOf(
            address(treasury)
        );
        treasury.manage(address(ocQi), treasuryAmount);
        ocQi.unlock(address(treasury), treasuryAmount);
        emit Leave(treasuryAmount);
    }

    /// @notice Harvest reward from QiDAO
    /// @param blockNumber_ the block number going to locked, if = 0, no lock
    function harvest(uint256 blockNumber_) external onlyLocker {
        uint256 rewards = ocQi.collectReward(address(treasury));
        if (blockNumber_ > 0) {
            lock(rewards, blockNumber_);
        }
        emit Harvest(rewards);
    }

    function emergencyWithdraw(address token_) external onlyOwner {
        uint256 balance = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(dao, balance);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
