// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';

import '../interfaces/IDelegation.sol';
import '../interfaces/IOtterClamQi.sol';
import '../interfaces/IERC20.sol';

abstract contract LockerOwned is OwnableUpgradeable {
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

contract OtterClamQi is
    IOtterClamQi,
    ERC20Upgradeable,
    LockerOwned,
    UUPSUpgradeable
{
    event Lock(address indexed receipt, uint256 amount, uint256 blockNumber);
    event Leave(address indexed receipt, uint256 amount);
    event CollectReward(address indexed receipt, uint256 amount);

    IERC20 public qi;
    EQi public eQi;
    address public dao;
    uint256 _maxLock;
    bool public burnEnabled;

    function initialize(
        address qi_,
        address eQi_,
        address dao_
    ) public initializer {
        __ERC20_init('OtterClam Qi', 'ocQi');
        __Ownable_init();
        qi = IERC20(qi_);
        eQi = EQi(eQi_);
        dao = dao_;
        _maxLock = 60108430;
        burnEnabled = false;
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

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
