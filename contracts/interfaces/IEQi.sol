// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IEQi {

    struct UserInfo {
        uint256 amount;
        uint256 endBlock;
    }

    // function maxLock() external view returns (uint256);
    
    function userInfo(address user) external view returns(UserInfo memory);

    function enter(uint256 _amount, uint256 _blockNumber) external;

    function leave() external;

    function endBlock() external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function underlyingBalance(address user) external view returns (uint256);

    function emergencyExit() external;
}