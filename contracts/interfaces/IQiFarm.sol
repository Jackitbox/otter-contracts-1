// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >0.7.5;

interface IQiFarm {
    // View function to see deposited balance for a user.
    function deposited(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    // View function to see pending ERC20s for a user.
    function pending(uint256 _pid, address _user)
        external
        view
        returns (uint256);

    // Deposit curveLp tokens to Farm for ERC20 allocation.
    function deposit(uint256 _pid, uint256 _amount) external;

    // Withdraw curveLp tokens from Farm.
    function withdraw(uint256 _pid, uint256 _amount) external;
}
