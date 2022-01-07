// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import 'hardhat/console.sol';

import './interfaces/IERC20.sol';
import './interfaces/IPearlNote.sol';
import './interfaces/IStakingDistributor.sol';
import './interfaces/IOtterLake.sol';

import './libraries/SafeMath.sol';
import './libraries/SafeERC20.sol';

import './types/Pausable.sol';
import './types/ReentrancyGuard.sol';

// @dev: Modified from: https://docs.synthetix.io/contracts/source/contracts/stakingrewards
contract OtterLake is IOtterLake, ReentrancyGuard, Pausable {
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
    bool public finalized;

    uint256 _epoch;
    mapping(uint256 => Epoch) public epochs;
    // epoch -> unlocked boost points
    mapping(uint256 => uint256) public unlockedBoostPoints;

    // note address -> term
    mapping(address => Term) public terms;
    address[] public termAddresses;

    // note address -> token id -> reward paid
    mapping(address => mapping(uint256 => uint256))
        public rewardPerBoostPointPaid;
    // note address  -> token id -> reward
    mapping(address => mapping(uint256 => uint256)) public rewards;

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

    function balanceOf(address noteAddr, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return terms[noteAddr].note.lockAmount(tokenId);
    }

    function termsCount() external view returns (uint256) {
        return termAddresses.length;
    }

    function totalBoostPoint(address owner)
        external
        view
        returns (uint256 sum)
    {
        for (uint256 i = 0; i < termAddresses.length; i++) {
            IPearlNote note = terms[termAddresses[i]].note;
            uint256 balance = note.balanceOf(owner);
            for (uint256 j = 0; j < balance; j++) {
                uint256 tokenId = note.tokenOfOwnerByIndex(owner, j);
                if (note.endEpoch(tokenId) > _epoch) {
                    sum = sum.add(
                        boostPointOf(
                            address(note),
                            note.tokenOfOwnerByIndex(owner, j)
                        )
                    );
                }
            }
        }
    }

    function boostPointOf(address noteAddr, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        Term memory term = terms[noteAddr];
        return term.note.lockAmount(tokenId).mul(term.multiplier).div(100);
    }

    function validEpoch(address noteAddr, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        IPearlNote note = terms[noteAddr].note;
        return
            _epoch < note.endEpoch(tokenId)
                ? _epoch
                : note.endEpoch(tokenId).sub(1);
    }

    function rewardPerBoostPoint(address noteAddr, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        // console.log(
        //     'reward/point: %s, paid: %s',
        //     epochs[e].rewardPerBoostPoint,
        //     rewardPerBoostPointPaid[noteAddr][tokenId]
        // );
        return
            epochs[validEpoch(noteAddr, tokenId)].rewardPerBoostPoint.sub(
                rewardPerBoostPointPaid[noteAddr][tokenId]
            );
    }

    function reward(address noteAddr, uint256 tokenId)
        external
        view
        returns (uint256)
    {
        return
            rewards[noteAddr][tokenId].add(_pendingReward(noteAddr, tokenId));
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function lock(address noteAddr, uint256 amount)
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

        Term memory term = terms[noteAddr];
        require(amount > 0, 'OtterLake: cannot lock 0 amount');
        require(term.enabled, 'PearVault: term disabled');
        require(
            amount >= term.minLockAmount,
            'OtterLake: amount < min lock amount'
        );
        pearl.safeTransferFrom(msg.sender, address(this), amount);
        pearl.safeApprove(address(term.note), amount);
        uint256 endEpoch = _epoch.add(term.lockPeriod);
        uint256 tokenId = term.note.mint(msg.sender, amount, endEpoch);

        rewardPerBoostPointPaid[noteAddr][tokenId] = epochs[_epoch]
            .rewardPerBoostPoint;
        uint256 boostPoint = boostPointOf(noteAddr, tokenId);
        epochs[_epoch].totalLocked = epochs[_epoch].totalLocked.add(boostPoint);
        unlockedBoostPoints[endEpoch] = unlockedBoostPoints[endEpoch].add(
            boostPoint
        );

        emit Locked(msg.sender, noteAddr, tokenId, amount);
    }

    function extendLock(
        address noteAddr,
        uint256 tokenId,
        uint256 amount
    ) public nonReentrant notPaused {
        harvest();

        Term memory term = terms[noteAddr];
        require(amount > 0, 'OtterLake: cannot lock 0 amount');
        require(term.enabled, 'PearVault: term disabled');
        require(
            terms[noteAddr].note.ownerOf(tokenId) == msg.sender,
            'OtterLake: msg.sender is not the note owner'
        );
        uint256 prevEndEpoch = term.note.endEpoch(tokenId);
        require(prevEndEpoch > _epoch, 'OtterLake: the note is expired');
        _updateReward(noteAddr, tokenId);

        pearl.safeTransferFrom(msg.sender, address(this), amount);
        pearl.safeApprove(address(term.note), amount);

        uint256 prevBoostPoint = term
            .note
            .lockAmount(tokenId)
            .mul(term.multiplier)
            .div(100);

        uint256 endEpoch = _epoch.add(term.lockPeriod);
        term.note.extendLock(tokenId, amount, endEpoch);

        uint256 boostPoint = boostPointOf(noteAddr, tokenId);
        epochs[_epoch].totalLocked = epochs[_epoch].totalLocked.add(
            amount.mul(term.multiplier).div(100)
        );
        unlockedBoostPoints[prevEndEpoch] = unlockedBoostPoints[prevEndEpoch]
            .sub(prevBoostPoint);
        unlockedBoostPoints[endEpoch] = unlockedBoostPoints[endEpoch].add(
            boostPoint
        );

        emit Locked(msg.sender, noteAddr, tokenId, amount);
    }

    function claimAndLock(address noteAddr, uint256 tokenId) external {
        uint256 extendingReward = claimReward(noteAddr, tokenId);
        console.log('claim and lock: %s', extendingReward);
        extendLock(noteAddr, tokenId, extendingReward);
    }

    function redeem(address noteAddr, uint256 tokenId) public nonReentrant {
        harvest();

        Term memory term = terms[noteAddr];
        require(
            terms[noteAddr].note.ownerOf(tokenId) == msg.sender,
            'OtterLake: msg.sender is not the note owner'
        );
        uint256 amount = term.note.burn(tokenId);

        emit Redeemed(msg.sender, noteAddr, tokenId, amount);
    }

    function claimReward(address noteAddr, uint256 tokenId)
        public
        nonReentrant
        returns (uint256)
    {
        harvest();

        require(
            terms[noteAddr].note.ownerOf(tokenId) == msg.sender,
            'OtterLake: msg.sender is not the note owner'
        );
        uint256 claimableReward = _updateReward(noteAddr, tokenId);
        // uint256 reward = pendingReward(termIndex, tokenId);
        if (claimableReward > 0) {
            // console.log('reward: %s', claimableReward);
            rewards[noteAddr][tokenId] = 0;
            pearl.transfer(msg.sender, claimableReward);
            // rewardPerBoostPointPaid[termIndex][tokenId] = epochs[_epoch]
            // .rewardPerBoostPoint;
            emit RewardPaid(msg.sender, noteAddr, tokenId, claimableReward);
            return claimableReward;
        }
        return 0;
    }

    function exit(address note, uint256 tokenId) external {
        claimReward(note, tokenId);
        redeem(note, tokenId);
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
            // console.log(
            //     'distributed epoch: %s locked: %s reward/point: %s',
            //     _epoch,
            //     e.totalLocked,
            //     e.rewardPerBoostPoint
            // );

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
            // console.log(
            //     'start epoch: %s locked: %s reward: %s',
            //     _epoch,
            //     epochs[_epoch].totalLocked,
            //     epochReward
            // );
        }
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    function _updateReward(address noteAddr, uint256 tokenId)
        internal
        returns (uint256)
    {
        rewards[noteAddr][tokenId] = rewards[noteAddr][tokenId].add(
            _pendingReward(noteAddr, tokenId)
        );
        rewardPerBoostPointPaid[noteAddr][tokenId] = epochs[
            validEpoch(noteAddr, tokenId)
        ].rewardPerBoostPoint;
        return rewards[noteAddr][tokenId];
    }

    function _pendingReward(address noteAddr, uint256 tokenId)
        internal
        view
        returns (uint256)
    {
        return
            boostPointOf(noteAddr, tokenId)
                .mul(rewardPerBoostPoint(noteAddr, tokenId))
                .div(1e18);
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
        if (finalized) {
            // @dev if something wrong, dev can extract reward to recover the lose
            require(
                tokenAddress != address(pearl),
                'OtterLake: Cannot withdraw the pearl'
            );
        }
        IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
        emit Recovered(tokenAddress, tokenAmount);
    }

    function finalize() external onlyOwner {
        finalized = true;
    }

    function addTerm(
        address note_,
        uint256 minLockAmount_,
        uint256 lockPeriod_,
        uint16 multiplier_
    ) public onlyOwner {
        require(
            multiplier_ < 1000,
            'OtterLake: multiplier cannot larger than x10'
        );
        require(
            terms[note_].multiplier == 0,
            'OtterLake: duplicate note added'
        );
        IPearlNote note = IPearlNote(note_);
        // @dev: check the note address is valid
        note.lockAmount(0);
        terms[note_] = Term({
            note: note,
            minLockAmount: minLockAmount_,
            lockPeriod: lockPeriod_,
            multiplier: multiplier_,
            enabled: true
        });
        termAddresses.push(note_);
        emit TermAdded(note_, minLockAmount_, lockPeriod_, multiplier_);
    }

    function disableTerm(address note_) external onlyOwner {
        terms[note_].enabled = false;
        emit TermDisabled(note_);
    }

    function removeTermAt(uint256 index) external onlyOwner {
        require(index < termAddresses.length);
        address termAddress = termAddresses[index];
        address note = address(terms[termAddress].note);

        // delete from map
        delete terms[termAddress];

        // delete from array
        termAddresses[index] = termAddresses[termAddresses.length - 1];
        delete termAddresses[termAddresses.length - 1];

        emit TermRemoved(note);
    }

    /* ========== EVENTS ========== */

    event TermAdded(
        address indexed note,
        uint256 minLockAmount,
        uint256 lockPeriod,
        uint16 multiplier
    );
    event TermDisabled(address indexed note);
    event TermRemoved(address indexed note);
    event RewardAdded(uint256 epoch, uint256 reward);
    event Locked(
        address indexed user,
        address indexed note,
        uint256 indexed tokenId,
        uint256 amount
    );
    event Redeemed(
        address indexed user,
        address indexed note,
        uint256 indexed tokenId,
        uint256 amount
    );
    event RewardPaid(
        address indexed user,
        address indexed note,
        uint256 indexed tokenId,
        uint256 reward
    );
    event RewardsDurationUpdated(uint256 newDuration);
    event Recovered(address token, uint256 amount);
}
