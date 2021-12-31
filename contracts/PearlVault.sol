// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import 'hardhat/console.sol';

import './interfaces/IERC20.sol';
import './interfaces/IPearlNote.sol';
import './interfaces/IStakingDistributor.sol';
import './interfaces/IPearlVault.sol';

import './libraries/SafeMath.sol';
import './libraries/SafeERC20.sol';

import './types/Pausable.sol';
import './types/ReentrancyGuard.sol';

// @dev: Modified from: https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract PearlVault is IPearlVault, ReentrancyGuard, Pausable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct Term {
        IPearlNote note;
        uint256 minLockAmount;
        uint256 lockPeriod;
        uint16 multiplier; // 100 = x1, 120 = x1.2
        bool enabled;
    }

    struct Epoch {
        uint256 length;
        uint256 number;
        uint256 endTime;
        uint256 totalReward; // accumulated rewards
        uint256 reward;
        uint256 totalLocked;
        uint256 rewardPerBoostPoint;
    }

    /* ========== STATE VARIABLES ========== */

    IERC20 public immutable pearl;
    IStakingDistributor public distributor;

    uint256 _epoch;
    mapping(uint256 => Epoch) public epochs;
    // epoch -> unlocked boost points
    mapping(uint256 => uint256) public unlockedBoostPoints;

    Term[] public terms;
    // term -> token id -> reward paid
    mapping(uint256 => mapping(uint256 => uint256))
        public rewardPerBoostPointPaid;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        address pearl_,
        uint256 epochLength_,
        uint256 firstEpochNumber_,
        uint256 firstEpochEndTime_
    ) {
        require(pearl_ != address(0));
        pearl = IERC20(pearl_);

        epochs[firstEpochNumber_] = Epoch({
            length: epochLength_,
            number: firstEpochNumber_,
            endTime: firstEpochEndTime_,
            totalReward: 0,
            reward: 0,
            totalLocked: 0,
            rewardPerBoostPoint: 0
        });
        _epoch = firstEpochNumber_;
    }

    /* ========== VIEWS ========== */

    function epoch() external view override returns (uint256) {
        return _epoch;
    }

    function totalLocked() external view returns (uint256) {
        return epochs[_epoch].totalLocked;
    }

    function balanceOf(uint256 termIndex, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return terms[termIndex].note.lockAmount(tokenId);
    }

    function boostPointOf(uint256 termIndex, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        Term memory term = terms[termIndex];
        return term.note.lockAmount(tokenId).mul(term.multiplier).div(100);
    }

    function rewardPerBoostPoint(uint256 termIndex, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        IPearlNote note = terms[termIndex].note;
        uint256 e = _epoch < note.endEpoch(tokenId)
            ? _epoch
            : note.endEpoch(tokenId).sub(1);
        return
            epochs[e].rewardPerBoostPoint.sub(
                rewardPerBoostPointPaid[termIndex][tokenId]
            );
    }

    function pendingReward(uint256 termIndex, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return
            boostPointOf(termIndex, tokenId)
                .mul(rewardPerBoostPoint(termIndex, tokenId))
                .div(1e18);
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function lock(uint256 termIndex, uint256 amount)
        external
        nonReentrant
        notPaused
    {
        // console.log(
        //     'lock epoch: %s term: %s: amount: %s',
        //     _epoch,
        //     termIndex,
        //     amount
        // );
        harvest();

        Term memory term = terms[termIndex];
        require(amount > 0, 'PearlVault: cannot lock 0 amount');
        require(term.enabled, 'PearVault: term disabled');
        require(
            amount >= term.minLockAmount,
            'PearlVault: amount < min lock amount'
        );
        pearl.safeTransferFrom(msg.sender, address(this), amount);
        pearl.safeApprove(address(term.note), amount);
        uint256 endEpoch = _epoch.add(term.lockPeriod);
        uint256 tokenId = term.note.mint(msg.sender, amount, endEpoch);

        uint256 boostPoint = boostPointOf(termIndex, tokenId);
        epochs[_epoch].totalLocked = epochs[_epoch].totalLocked.add(boostPoint);
        unlockedBoostPoints[endEpoch] = unlockedBoostPoints[endEpoch].add(
            boostPoint
        );

        emit Locked(msg.sender, termIndex, tokenId, amount);
    }

    function redeem(uint256 termIndex, uint256 tokenId) public nonReentrant {
        harvest();

        Term memory term = terms[termIndex];
        require(terms[termIndex].note.ownerOf(tokenId) == msg.sender);
        uint256 amount = term.note.burn(tokenId);

        emit Redeemed(msg.sender, termIndex, tokenId, amount);
    }

    function claimReward(uint256 termIndex, uint256 tokenId)
        public
        nonReentrant
    {
        harvest();

        require(terms[termIndex].note.ownerOf(tokenId) == msg.sender);
        uint256 reward = pendingReward(termIndex, tokenId);
        if (reward > 0) {
            pearl.transfer(msg.sender, reward);
            rewardPerBoostPointPaid[termIndex][tokenId] = epochs[_epoch]
                .rewardPerBoostPoint;
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit(uint256 termIndex, uint256 tokenId) external {
        claimReward(termIndex, tokenId);
        redeem(termIndex, tokenId);
    }

    function harvest() public {
        if (epochs[_epoch].endTime <= block.timestamp) {
            Epoch storage e = epochs[_epoch];
            if (e.totalLocked > 0) {
                e.rewardPerBoostPoint = e
                    .totalReward
                    .sub(epochs[_epoch.sub(1)].totalReward)
                    .mul(1e18)
                    .div(e.totalLocked)
                    .add(epochs[_epoch.sub(1)].rewardPerBoostPoint);
            } else {
                e.totalReward = e.totalReward.sub(e.reward);
            }

            uint256 current = pearl.balanceOf(address(this));
            distributor.distribute();
            uint256 epochReward = pearl.balanceOf(address(this)).sub(current);

            // advance to next epoch
            _epoch = _epoch.add(1);
            epochs[_epoch] = Epoch({
                length: e.length,
                number: _epoch,
                endTime: e.endTime.add(e.length),
                totalReward: e.totalReward.add(epochReward),
                reward: epochReward,
                totalLocked: e.totalLocked.sub(unlockedBoostPoints[_epoch]),
                rewardPerBoostPoint: e.rewardPerBoostPoint
            });
            // console.log('epoch: %s reward: %s', _epoch, epochReward);
        }
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setDistributor(address distributor_) external onlyOwner {
        distributor = IStakingDistributor(distributor_);
    }

    // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
    function recoverERC20(address tokenAddress, uint256 tokenAmount)
        external
        onlyOwner
    {
        require(tokenAddress != address(pearl), 'Cannot withdraw the pearl');
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function addTerm(
        address _note,
        uint256 _minLockAmount,
        uint256 _lockPeriod,
        uint16 _multiplier
    ) public onlyOwner {
        require(
            _multiplier < 1000,
            'PearlVault: multiplier cannot larger than x10'
        );
        IPearlNote note = IPearlNote(_note);
        // @dev: check the note address is valid
        note.lockAmount(0);
        terms.push(
            Term({
                note: note,
                minLockAmount: _minLockAmount,
                lockPeriod: _lockPeriod,
                multiplier: _multiplier,
                enabled: true
            })
        );
        emit TermAdded(_note, _minLockAmount, _lockPeriod, _multiplier);
    }

    function disableTerm(uint256 index) external onlyOwner {
        terms[index].enabled = false;
        emit TermDisabled(address(terms[index].note), index);
    }

    /* ========== EVENTS ========== */

    event TermAdded(
        address indexed note,
        uint256 minLockAmount,
        uint256 lockPeriod,
        uint16 multiplier
    );
    event TermDisabled(address indexed note, uint256 index);
    event RewardAdded(uint256 reward);
    event Locked(
        address indexed user,
        uint256 term,
        uint256 tokenId,
        uint256 amount
    );
    event Redeemed(
        address indexed user,
        uint256 indexed term,
        uint256 indexed tokenId,
        uint256 amount
    );
    event RewardPaid(address indexed user, uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}
