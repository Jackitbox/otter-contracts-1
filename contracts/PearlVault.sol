// // SPDX-License-Identifier: AGPL-3.0-or-later
// pragma solidity 0.7.5;

// import './interfaces/IERC20.sol';
// import './interfaces/IPearlNote.sol';

// import './libraries/SafeMath.sol';
// import './libraries/SafeERC20.sol';

// import './types/Pausable.sol';
// import './types/ReentrancyGuard.sol';
// import './RewardsDistributionRecipient.sol';

// // @dev: Modified from: https://docs.synthetix.io/contracts/source/contracts/stakingrewards
// contract PearlVault is ReentrancyGuard, Pausable {
//     using SafeMath for uint256;
//     using SafeERC20 for IERC20;

//     struct Term {
//         IPearlNote note;
//         uint256 minLockAmount;
//         uint256 lockPeriod;
//         uint16 multiplier; // 100 = x1, 120 = x1.2
//         bool enabled;
//     }

//     struct Epoch {
//         uint256 length;
//         uint256 number;
//         uint256 endTime;
//         uint256 totalReward;
//         uint256 totalLocked;
//         uint256 rewardPerBoostPoint;
//     }

//     /* ========== STATE VARIABLES ========== */

//     IERC20 public immutable pearl;

//     uint256 public periodFinish = 0;
//     uint256 public rewardRate = 0;
//     uint256 public rewardsDuration = 8 hours;
//     uint256 public lastUpdateTime;
//     uint256=>uint256) public rewardPerBoostPoint;
//     // mapping(uint256=>uint256) public rewardPerBoostPoint;

//     Term[] public terms;
//     // term -> token id -> reward paid
//     mapping(uint256 => mapping(uint256 => uint256))
//         public noteRewardPerBoostPointPaid;
//     // term -> token id -> reward
//     // mapping(uint256 => mapping(uint256 => uint256)) public rewards;

//     uint256 private _totalLocked;

//     // mapping(address => uint256) private _balances;

//     /* ========== CONSTRUCTOR ========== */

//     constructor(
//         address _rewardsDistribution,
//         address _pearl,
//         address _pool
//     ) {
//         rewardsDistribution = _rewardsDistribution;
//         pearl = IERC20(_pearl);
//         pool = IRewardPool(_pool);
//     }

//     /* ========== VIEWS ========== */

//     function totalLocked() external view returns (uint256) {
//         return _totalLocked;
//     }

//     function balanceOf(uint256 termIndex, uint256 tokenId)
//         public
//         view
//         returns (uint256)
//     {
//         return terms[termIndex].note.lockAmount(tokenId);
//     }

//     function boostPointOf(uint256 termIndex, uint256 tokenId)
//         public
//         view
//         returns (uint256)
//     {
//         Term memory term = terms[termIndex];
//         return term.note.lockAmount(tokenId).mul(term.multiplier).div(100);
//     }

//     function lastTimeRewardApplicable(uint256 termIndex, uint256 tokenId)
//         public
//         view
//         returns (uint256)
//     {
//         uint256 t = block.timestamp < periodFinish
//             ? block.timestamp
//             : periodFinish;
//         if (termIndex != type(uint256).max) {
//             Term memory term = terms[termIndex];
//             uint256 noteDueDate = term.note.dueDate(tokenId);
//             if (noteDueDate < t) {
//                 return noteDueDate;
//             }
//         }
//         return t;
//     }

//     function rewardPerBoostPoint(uint256 termIndex, uint256 tokenId)
//         public
//         view
//         returns (uint256)
//     {
//         if (_totalLocked == 0) {
//             return rewardPerBoostPointStored;
//         }
//         return
//             rewardPerBoostPointStored.add(
//                 lastTimeRewardApplicable(termIndex, tokenId)
//                     .sub(lastUpdateTime)
//                     .mul(rewardRate)
//                     .mul(1e18)
//                     .div(_totalLocked)
//             );
//     }

//     function earned(uint256 termIndex, uint256 tokenId)
//         public
//         view
//         returns (uint256)
//     {
//         return
//             boostPointOf(termIndex, tokenId)
//                 .mul(
//                     rewardPerBoostPoint(termIndex, tokenId).sub(
//                         noterewardPerBoostPointPaid[termIndex][tokenId]
//                     )
//                 )
//                 .div(1e18)
//                 .add(rewards[termIndex][tokenId]);
//     }

//     function getRewardForDuration() external view returns (uint256) {
//         return rewardRate.mul(rewardsDuration);
//     }

//     /* ========== MUTATIVE FUNCTIONS ========== */

//     function lock(uint256 termIndex, uint256 amount)
//         external
//         nonReentrant
//         notPaused
//     {
//         Term memory term = terms[termIndex];
//         require(amount > 0, 'PearlVault: cannot lock 0 amount');
//         require(term.enabled, 'PearVault: term disabled');
//         require(
//             amount >= term.minLockAmount,
//             'PearlVault: amount < min lock amount'
//         );
//         uint256 nextTokenId = term.note.nextTokenId();
//         _updateReward(termIndex, nextTokenId);

//         pearl.safeTransferFrom(msg.sender, address(this), amount);
//         pearl.safeApprove(address(term.note), amount);
//         uint256 tokenId = term.note.mint(
//             msg.sender,
//             amount,
//             block.timestamp + term.lockPeriod
//         );
//         require(tokenId == nextTokenId, 'PearlVault: token id mismatched');

//         _totalLocked = _totalLocked.add(boostPointOf(termIndex, tokenId));
//         // _balances[msg.sender] = _balances[msg.sender].add(amount);
//         // pearl.safeTransferFrom(msg.sender, address(this), amount);
//         emit Locked(msg.sender, termIndex, tokenId, amount);
//     }

//     function withdraw(uint256 termIndex, uint256 tokenId)
//         public
//         nonReentrant
//         updateReward(termIndex, tokenId)
//     {
//         Term memory term = terms[termIndex];
//         require(terms[termIndex].note.ownerOf(tokenId) == msg.sender);
//         uint256 boostPoint = boostPointOf(termIndex, tokenId);
//         _totalLocked = _totalLocked.sub(boostPoint);
//         // _balances[msg.sender] = _balances[msg.sender].sub(amount);
//         uint256 amount = term.note.burn(tokenId);
//         // pearl.safeTransfer(msg.sender, amount);
//         emit Withdrawn(msg.sender, amount);
//     }

//     function claimReward(uint256 termIndex, uint256 tokenId)
//         public
//         nonReentrant
//         updateReward(termIndex, tokenId)
//     {
//         require(terms[termIndex].note.ownerOf(tokenId) == msg.sender);
//         uint256 reward = rewards[termIndex][tokenId];
//         if (reward > 0) {
//             rewards[termIndex][tokenId] = 0;
//             pool.claimReward(msg.sender, reward);
//             emit RewardPaid(msg.sender, reward);
//         }
//     }

//     function exit(uint256 termIndex, uint256 tokenId) external {
//         claimReward(termIndex, tokenId);
//         withdraw(termIndex, tokenId);
//     }

//     /* ========== RESTRICTED FUNCTIONS ========== */

//     function notifyRewardAmount(uint256 reward)
//         external
//         override
//         onlyRewardsDistribution
//         updateReward(type(uint256).max, type(uint256).max)
//     {
//         if (block.timestamp >= periodFinish) {
//             rewardRate = reward.div(rewardsDuration);
//         } else {
//             uint256 remaining = periodFinish.sub(block.timestamp);
//             uint256 leftover = remaining.mul(rewardRate);
//             rewardRate = reward.add(leftover).div(rewardsDuration);
//         }

//         // Ensure the provided reward amount is not more than the balance in the contract.
//         // This keeps the reward rate in the right range, preventing overflows due to
//         // very high values of rewardRate in the earned and rewardsPerToken functions;
//         // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
//         uint256 balance = pearl.balanceOf(address(pool));
//         require(
//             rewardRate <= balance.div(rewardsDuration),
//             'PearlVault: provided reward too high'
//         );

//         lastUpdateTime = block.timestamp;
//         periodFinish = block.timestamp.add(rewardsDuration);
//         emit RewardAdded(reward);
//     }

//     // Added to support recovering LP Rewards from other systems such as BAL to be distributed to holders
//     function recoverERC20(address tokenAddress, uint256 tokenAmount)
//         external
//         onlyOwner
//     {
//         require(tokenAddress != address(pearl), 'Cannot withdraw the pearl');
//         IERC20(tokenAddress).safeTransfer(owner(), tokenAmount);
//         emit Recovered(tokenAddress, tokenAmount);
//     }

//     function setRewardsDuration(uint256 _rewardsDuration) external onlyOwner {
//         require(
//             block.timestamp > periodFinish,
//             'Previous rewards period must be complete before changing the duration for the new period'
//         );
//         rewardsDuration = _rewardsDuration;
//         emit RewardsDurationUpdated(rewardsDuration);
//     }

//     function addTerm(
//         address _note,
//         uint256 _minLockAmount,
//         uint256 _lockPeriod,
//         uint16 _multiplier
//     ) public onlyOwner {
//         require(
//             _multiplier < 1000,
//             'PearlVault: multiplier cannot larger than x10'
//         );
//         IPearlNote note = IPearlNote(_note);
//         // @dev: check the note address is valid
//         note.lockAmount(0);
//         terms.push(
//             Term({
//                 note: note,
//                 minLockAmount: _minLockAmount,
//                 lockPeriod: _lockPeriod,
//                 multiplier: _multiplier,
//                 enabled: true
//             })
//         );
//         emit TermAdded(_note, _minLockAmount, _lockPeriod, _multiplier);
//     }

//     function disableTerm(uint256 index) external onlyOwner {
//         terms[index].enabled = false;
//         emit TermDisabled(address(terms[index].note), index);
//     }

//     function _updateReward(uint256 termIndex, uint256 tokenId) private {
//         rewardPerBoostPointStored = rewardPerBoostPoint(
//             type(uint256).max,
//             type(uint256).max
//         );
//         lastUpdateTime = lastTimeRewardApplicable(
//             type(uint256).max,
//             type(uint256).max
//         );
//         if (termIndex != type(uint256).max) {
//             rewards[termIndex][tokenId] = earned(termIndex, tokenId);
//             noterewardPerBoostPointPaid[termIndex][
//                 tokenId
//             ] = rewardPerBoostPointStored;
//         }
//     }

//     /* ========== MODIFIERS ========== */

//     modifier updateReward(uint256 termIndex, uint256 tokenId) {
//         _updateReward(termIndex, tokenId);
//         _;
//     }

//     /* ========== EVENTS ========== */

//     event TermAdded(
//         address indexed note,
//         uint256 minLockAmount,
//         uint256 lockPeriod,
//         uint16 multiplier
//     );
//     event TermDisabled(address indexed note, uint256 index);
//     event RewardAdded(uint256 reward);
//     event Locked(
//         address indexed user,
//         uint256 term,
//         uint256 tokenId,
//         uint256 amount
//     );
//     event Withdrawn(address indexed user, uint256 amount);
//     event RewardPaid(address indexed user, uint256 reward);
//     event RewardsDurationUpdated(uint256 newDuration);
//     event Recovered(address token, uint256 amount);
// }
