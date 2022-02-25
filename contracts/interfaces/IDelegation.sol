// SPDX-License-Identifier: MIT
pragma solidity 0.7.5;

interface IDelegation {
    function clearDelegate(bytes32 _id) external;

    function setDelegate(bytes32 _id, address _delegate) external;

    function delegation(address _address, bytes32 _id)
        external
        view
        returns (address);
}
