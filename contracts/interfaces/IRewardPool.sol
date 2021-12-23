// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface IRewardPool {
    function claimReward(address user, uint256 reward) external;
}
