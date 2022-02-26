// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

interface IOtterClamQi {
    function maxLock() external view returns (uint256);

    function lock(
        address receipt_,
        uint256 amount_,
        uint256 blockNumber_
    ) external;

    function unlock(address receipt_, uint256 amount_) external;

    function collectReward(address receipt_) external returns (uint256);
}
