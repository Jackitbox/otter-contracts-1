// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';

abstract contract OperatorOwnedUpgradeable is OwnableUpgradeable {
    event ToggleOperator(address indexed operator, bool toggle);

    mapping(address => bool) public operators;

    function toggleOperator(address operator_) external onlyOwner {
        operators[operator_] = !operators[operator_];

        emit ToggleOperator(operator_, operators[operator_]);
    }

    modifier onlyOperator() {
        require(operators[msg.sender], 'OperatorOwned: caller is not Operator');
        _;
    }
}
