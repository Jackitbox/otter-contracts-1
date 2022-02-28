// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

abstract contract LockerOwnedUpgradeable is OwnableUpgradeable {
    event ToggleLocker(address indexed locker, bool toggle);

    mapping(address => bool) public lockers;

    function toggleLocker(address locker_) external onlyOwner {
        lockers[locker_] = !lockers[locker_];

        emit ToggleLocker(locker_, lockers[locker_]);
    }

    modifier onlyLocker() {
        require(lockers[msg.sender], 'LockerOwned: caller is not Locker');
        _;
    }
}
