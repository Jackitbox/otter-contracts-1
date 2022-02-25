// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import '../interfaces/IDelegation.sol';
import '../interfaces/IOtterClamQi.sol';

import '../types/Ownable.sol';
import '../types/ERC20.sol';

import '../libraries/SafeMath.sol';

abstract contract LockerOwned is Ownable {
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

interface EQi {
    function maxLock() external view returns (uint256);

    function enter(uint256 _amount, uint256 _blockNumber) external;

    function leave() external;

    function endBlock() external view returns (uint256);

    function balanceOf(address user) external view returns (uint256);

    function underlyingBalance(address user) external view returns (uint256);

    function emergencyExit() external;
}

contract OtterClamQi is IOtterClamQi, ERC20, LockerOwned {
    using SafeMath for uint256;

    event Lock(address indexed receipt, uint256 amount, uint256 blockNumber);
    event Leave(address indexed receipt, uint256 amount);
    event CollectReward(address indexed receipt, uint256 amount);

    IERC20 public immutable qi;
    EQi public immutable eQi;
    address public immutable dao;

    uint256 _maxLock = 60108430;
    bool public burnEnabled = false;

    constructor(
        address qi_,
        address eQi_,
        address dao_
    ) ERC20('OtterClam Qi', 'ocQi', 18) {
        qi = IERC20(qi_);
        eQi = EQi(eQi_);
        dao = dao_;
    }

    function maxLock() external view override returns (uint256) {
        return _maxLock;
    }

    function lock(
        address receipt_,
        uint256 amount_,
        uint256 blockNumber_
    ) external override onlyLocker {
        qi.transferFrom(msg.sender, address(this), amount_);
        qi.approve(address(eQi), amount_);
        eQi.enter(amount_, blockNumber_);
        _mint(receipt_, amount_);

        emit Lock(receipt_, amount_, blockNumber_);
    }

    function unlock(address receipt_, uint256 amount_)
        external
        override
        onlyLocker
    {
        eQi.leave();
        _burn(msg.sender, amount_);
        qi.transfer(address(receipt_), amount_);

        // @dev: let other users burn
        burnEnabled = true;

        emit Leave(receipt_, amount_);
    }

    function collectReward(address receipt_)
        external
        override
        onlyLocker
        returns (uint256)
    {
        uint256 qiBalance = qi.balanceOf(address(this));
        qi.transfer(receipt_, qiBalance);

        emit CollectReward(receipt_, qiBalance);

        return qiBalance;
    }

    function setMaxLock(uint256 maxLock_) external onlyOwner {
        _maxLock = maxLock_;
    }

    function setDelegate(address _delegateContract, address _delegate)
        external
        onlyOwner
    {
        IDelegation(_delegateContract).setDelegate('qidao.eth', _delegate);
    }

    function burn(uint256 amount_) external {
        require(burnEnabled, 'OtterClamQi: burn is disabled');
        _burn(msg.sender, amount_);
        qi.transfer(msg.sender, amount_);
    }

    function setBurnEnabled(bool enabled_) external onlyOwner {
        burnEnabled = enabled_;
    }

    /// @dev Emergency usage

    function emergencyExit() external onlyOwner {
        eQi.emergencyExit();
    }

    function emergencyWithdraw(address token_) external onlyOwner {
        require(token_ != address(qi));
        uint256 balance = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(dao, balance);
    }
}
