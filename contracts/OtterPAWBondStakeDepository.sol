// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.7.5;

import './interfaces/IOtterTreasury.sol';
import './interfaces/IOtterStaking.sol';
import './interfaces/IOtterBondingCalculator.sol';
import './interfaces/IsCLAM.sol';

import './types/Ownable.sol';

import './libraries/SafeMath.sol';
import './libraries/Math.sol';
import './libraries/FixedPoint.sol';
import './libraries/SafeERC20.sol';

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721Holder.sol';

contract OtterPAWBondStakeDepository is Ownable, ERC721Holder {
    using FixedPoint for *;
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /* ======== EVENTS ======== */

    event BondCreated(
        uint256 deposit,
        uint256 indexed payout,
        uint256 indexed expires,
        uint256 indexed priceInUSD
    );
    event BondRedeemed(
        address indexed recipient,
        uint256 payout,
        uint256 remaining
    );
    event BondPriceChanged(
        uint256 indexed priceInUSD,
        uint256 indexed internalPrice,
        uint256 indexed debtRatio
    );
    event ControlVariableAdjustment(
        uint256 initialBCV,
        uint256 newBCV,
        uint256 adjustment,
        bool addition
    );

    /* ======== STATE VARIABLES ======== */

    address public immutable CLAM; // intermediate reward token from treasury
    address public immutable sCLAM; // token given as payment for bond
    address public immutable principle; // token used to create bond
    address public immutable treasury; // mints CLAM when receives principle
    address public immutable DAO; // receives profit share from bond

    bool public immutable isLiquidityBond; // LP and Reserve bonds are treated slightly different
    address public immutable bondCalculator; // calculates value of LP tokens

    address public staking; // to stake and claim if no staking warmup

    Terms public terms; // stores terms for new bonds
    Adjust public adjustment; // stores adjustment to BCV data

    mapping(address => Bond) public bondInfo; // stores bond information for depositors
    mapping(address => Discount[]) public discountInfo; // stores discount information for depositor
    mapping(address => DiscountTerms) public discountTerms; // stores discount terms for paw.
    address[] public pawAddresses; // all paws that have discount
    uint256 public pawCount; // number of paws that have discount

    mapping(address => mapping(uint256 => address)) public pawOwners;

    uint256 public totalDebt; // total value of outstanding bonds; used for pricing
    uint256 public lastDecay; // reference timestamp for debt decay

    /* ======== STRUCTS ======== */

    // Info for creating new bonds
    struct Terms {
        uint256 controlVariable; // scaling variable for price
        uint256 vestingTerm; // in timestamp
        uint256 minimumPrice; // vs principle value
        uint256 maxPayout; // in thousandths of a %. i.e. 500 = 0.5%
        uint256 fee; // as % of bond payout, in hundreths. ( 500 = 5% = 0.05 for every 1 paid)
        uint256 maxDebt; // 9 decimal debt ratio, max % total supply created as debt
    }

    // Info for bond holder
    struct Bond {
        uint256 payout; //clam at the moment of bond
        uint256 vesting; // Blocks left to vest
        uint256 lastTimestamp; // Last interaction
        uint256 pricePaid; // In DAI, for front end viewing
        uint256 gonsPayout; // sCLAM gons remaining to be paid
    }

    // Info for incremental adjustments to control variable
    struct Adjust {
        bool add; // addition or subtraction
        uint256 rate; // increment
        uint256 target; // BCV when adjustment finished
        uint256 buffer; // minimum length (in blocks) between adjustments
        uint256 lastBlock; // block when last adjustment made
    }

    struct Discount {
        IERC721 paw;
        uint256 tokenID; // paw nft tokenID
        uint256 discount; // discount when buying
    }

    struct DiscountTerms {
        uint256 discount; // 500 = 5%
        uint256 expiry; // timestamp
    }

    /* ======== INITIALIZATION ======== */

    constructor(
        address _CLAM,
        address _sCLAM,
        address _principle,
        address _treasury,
        address _DAO,
        address _bondCalculator
    ) {
        require(_CLAM != address(0));
        CLAM = _CLAM;
        require(_sCLAM != address(0));
        sCLAM = _sCLAM;
        require(_principle != address(0));
        principle = _principle;
        require(_treasury != address(0));
        treasury = _treasury;
        require(_DAO != address(0));
        DAO = _DAO;
        // bondCalculator should be address(0) if not LP bond
        bondCalculator = _bondCalculator;
        isLiquidityBond = (_bondCalculator != address(0));
    }

    /**
     *  @notice initializes bond parameters
     *  @param _controlVariable uint
     *  @param _vestingTerm uint
     *  @param _minimumPrice uint
     *  @param _maxPayout uint
     *  @param _fee uint
     *  @param _maxDebt uint
     *  @param _initialDebt uint
     */
    function initializeBondTerms(
        uint256 _controlVariable,
        uint256 _vestingTerm,
        uint256 _minimumPrice,
        uint256 _maxPayout,
        uint256 _fee,
        uint256 _maxDebt,
        uint256 _initialDebt
    ) external onlyOwner {
        terms = Terms({
            controlVariable: _controlVariable,
            vestingTerm: _vestingTerm,
            minimumPrice: _minimumPrice,
            maxPayout: _maxPayout,
            fee: _fee,
            maxDebt: _maxDebt
        });
        totalDebt = _initialDebt;
        lastDecay = block.timestamp;
    }

    /* ======== POLICY FUNCTIONS ======== */

    enum PARAMETER {
        VESTING,
        PAYOUT,
        FEE,
        DEBT,
        MINPRICE
    }

    enum DISCOUNT_PARAMETER {
        DISCOUNT,
        EXPIRY
    }

    /**
     *  @notice set parameters for new bonds
     *  @param _parameter PARAMETER
     *  @param _input uint
     */
    function setBondTerms(PARAMETER _parameter, uint256 _input)
        external
        onlyOwner
    {
        if (_parameter == PARAMETER.VESTING) {
            // 0
            require(_input >= 10000, 'Vesting must be longer than 3 hours');
            terms.vestingTerm = _input;
        } else if (_parameter == PARAMETER.PAYOUT) {
            // 1
            require(_input <= 1000, 'Payout cannot be above 1 percent');
            terms.maxPayout = _input;
        } else if (_parameter == PARAMETER.FEE) {
            // 2
            require(_input <= 10000, 'DAO fee cannot exceed payout');
            terms.fee = _input;
        } else if (_parameter == PARAMETER.DEBT) {
            // 3
            terms.maxDebt = _input;
        } else if (_parameter == PARAMETER.MINPRICE) {
            // 4
            terms.minimumPrice = _input;
        }
    }

    /**
     *  @notice set control variable adjustment
     *  @param _addition bool
     *  @param _increment uint
     *  @param _target uint
     *  @param _buffer uint
     */
    function setAdjustment(
        bool _addition,
        uint256 _increment,
        uint256 _target,
        uint256 _buffer
    ) external onlyOwner {
        require(
            _increment <= Math.max(terms.controlVariable.mul(25).div(1000), 1),
            'Increment too large'
        );
        adjustment = Adjust({
            add: _addition,
            rate: _increment,
            target: _target,
            buffer: _buffer,
            lastBlock: block.number
        });
    }

    /**
     *  @notice set contract for auto stake
     *  @param _staking address
     */
    function setStaking(address _staking) external onlyOwner {
        require(_staking != address(0));
        staking = _staking;
    }

    /**
     *  @notice add discount for a paw
     *  @param _paw address
     *  @param _discount uint
     *  @param _expiry uint
     */
    function addDiscountTerms(
        address _paw,
        uint256 _discount,
        uint256 _expiry
    ) external onlyOwner {
        require(_paw != address(0), 'zero address');
        require(discountTerms[_paw].discount == 0, 'discount already added');
        discountTerms[_paw] = DiscountTerms({
            discount: _discount,
            expiry: _expiry
        });
        pawAddresses.push(_paw);
        pawCount++;
    }

    /**
     *  @notice set discount for a paw
     *  @param _paw address
     *  @param _value uint
     */
    function setDiscountTerms(
        address _paw,
        DISCOUNT_PARAMETER _parameter,
        uint256 _value
    ) external onlyOwner {
        require(_paw != address(0), 'zero address');
        require(discountTerms[_paw].discount != 0, 'discount not added');
        if (_parameter == DISCOUNT_PARAMETER.DISCOUNT) {
            discountTerms[_paw].discount = _value;
        } else if (_parameter == DISCOUNT_PARAMETER.EXPIRY) {
            discountTerms[_paw].expiry = _value;
        }
    }

    function removeDiscountTermsAt(uint256 _index) external onlyOwner {
        require(_index < pawAddresses.length);
        address pawAddress = pawAddresses[_index];
        delete discountTerms[pawAddress];
        pawAddresses[_index] = pawAddresses[pawAddresses.length - 1];
        delete pawAddresses[pawAddresses.length - 1];
        pawCount--;
    }

    /**
     *  @notice get discount for a paw
     *  @param _paw address
     */
    function discountOf(address _paw) public view returns (uint256) {
        return
            block.timestamp > expiryOf(_paw) ? 0 : discountTerms[_paw].discount;
    }

    /**
     *  @notice expiry of paw
     *  @param _paw address
     */
    function expiryOf(address _paw) public view returns (uint256) {
        return discountTerms[_paw].expiry;
    }

    /**
     *  @notice get original owner of paw
     *  @param _paw address
     *  @param _tokenID uint256
     */
    function ownerOf(address _paw, uint256 _tokenID)
        public
        view
        returns (address)
    {
        return pawOwners[_paw][_tokenID];
    }

    /* ======== USER FUNCTIONS ======== */

    /**
     *  @notice deposit bond
     *  @param _amount uint
     *  @param _maxPrice uint
     *  @param _depositor address
     *  @return uint
     */
    function deposit(
        uint256 _amount,
        uint256 _maxPrice,
        address _depositor,
        address _paw,
        uint256 _tokenID
    ) external returns (uint256) {
        require(_depositor != address(0), 'Invalid address');

        decayDebt();
        require(totalDebt <= terms.maxDebt, 'Max capacity reached');

        uint256 priceInUSD = bondPriceInUSD(_paw); // Stored in bond info
        //uint nativePrice = _bondPrice();

        require(
            _maxPrice >= _bondPrice(_paw),
            'Slippage limit: more than max price'
        ); // slippage protection

        uint256 value = IOtterTreasury(treasury).valueOfToken(
            principle,
            _amount
        );
        uint256 payout = payoutFor(value, _paw); // payout to bonder is computed

        require(payout >= 10000000, 'Bond too small'); // must be > 0.01 CLAM ( underflow protection )
        require(payout <= maxPayout(), 'Bond too large'); // size protection because there is no slippage

        // profits are calculated
        uint256 fee = payout.mul(terms.fee).div(10000);
        uint256 profit = value.sub(payout).sub(fee);

        if (
            discountOf(_paw) > 0 &&
            IERC721(_paw).ownerOf(_tokenID) == msg.sender
        ) {
            pawOwners[_paw][_tokenID] = IERC721(_paw).ownerOf(_tokenID);
            IERC721(_paw).safeTransferFrom(msg.sender, address(this), _tokenID);
            discountInfo[_depositor].push(
                Discount({
                    discount: discountOf(_paw),
                    paw: IERC721(_paw),
                    tokenID: _tokenID
                })
            );
        }
        IERC20(principle).safeTransferFrom(msg.sender, address(this), _amount);
        IERC20(principle).approve(address(treasury), _amount);
        IOtterTreasury(treasury).deposit(_amount, principle, profit);

        if (fee != 0) {
            // fee is transferred to dao
            IERC20(CLAM).safeTransfer(DAO, fee);
        }

        // total debt is increased
        totalDebt = totalDebt.add(value);

        IERC20(CLAM).approve(staking, payout);
        IOtterStaking(staking).stake(payout, address(this));
        IOtterStaking(staking).claim(address(this));

        uint256 stakeGons = IsCLAM(sCLAM).gonsForBalance(payout);
        // depositor info is stored
        bondInfo[_depositor] = Bond({
            gonsPayout: bondInfo[_depositor].gonsPayout.add(stakeGons),
            payout: bondInfo[_depositor].payout.add(payout),
            vesting: terms.vestingTerm,
            lastTimestamp: block.timestamp,
            pricePaid: priceInUSD
        });

        // indexed events are emitted
        emit BondCreated(
            _amount,
            payout,
            block.timestamp.add(terms.vestingTerm),
            priceInUSD
        );
        emit BondPriceChanged(
            bondPriceInUSD(address(0)),
            _bondPrice(address(0)),
            debtRatio()
        );

        adjust(); // control variable is adjusted
        return payout;
    }

    /**
     *  @notice redeem bond for user
     *  @param _recipient address
     *  @return uint
     */
    function redeem(address _recipient) external returns (uint256) {
        Bond memory info = bondInfo[_recipient];
        // (timestamp since last interaction / vesting term remaining)
        uint256 percentVested = percentVestedFor(_recipient);

        require(percentVested >= 10000, 'not fully vested'); // if fully vested
        delete bondInfo[_recipient]; // delete user info
        uint256 _amount = IsCLAM(sCLAM).balanceForGons(info.gonsPayout);
        IERC20(sCLAM).transfer(_recipient, _amount); // pay user everything due
        for (uint256 i = 0; i < discountInfo[_recipient].length; i++) {
            discountInfo[_recipient][i].paw.safeTransferFrom(
                address(this),
                _recipient,
                discountInfo[_recipient][i].tokenID
            );
            delete pawOwners[_recipient][i];
        }
        delete discountInfo[_recipient]; // delete user info
        emit BondRedeemed(_recipient, _amount, 0); // emit bond data
        return _amount;
    }

    /* ======== INTERNAL HELPER FUNCTIONS ======== */

    /**
     *  @notice makes incremental adjustment to control variable
     */
    function adjust() internal {
        uint256 blockCanAdjust = adjustment.lastBlock.add(adjustment.buffer);
        if (adjustment.rate != 0 && block.number >= blockCanAdjust) {
            uint256 initial = terms.controlVariable;
            if (adjustment.add) {
                terms.controlVariable = terms.controlVariable.add(
                    adjustment.rate
                );
                if (terms.controlVariable >= adjustment.target) {
                    adjustment.rate = 0;
                }
            } else {
                terms.controlVariable = terms.controlVariable.sub(
                    adjustment.rate
                );
                if (terms.controlVariable <= adjustment.target) {
                    adjustment.rate = 0;
                }
            }
            adjustment.lastBlock = block.number;
            emit ControlVariableAdjustment(
                initial,
                terms.controlVariable,
                adjustment.rate,
                adjustment.add
            );
        }
    }

    /**
     *  @notice reduce total debt
     */
    function decayDebt() internal {
        totalDebt = totalDebt.sub(debtDecay());
        lastDecay = block.timestamp;
    }

    /* ======== VIEW FUNCTIONS ======== */

    /**
     *  @notice determine maximum bond size
     *  @return uint
     */
    function maxPayout() public view returns (uint256) {
        return IERC20(CLAM).totalSupply().mul(terms.maxPayout).div(100000);
    }

    /**
     *  @notice calculate interest due for new bond
     *  @param _value uint
     *  @return uint
     */
    function payoutFor(uint256 _value, address _paw)
        public
        view
        returns (uint256)
    {
        return
            FixedPoint.fraction(_value, bondPrice(_paw)).decode112with18().div(
                1e16
            );
    }

    /**
     *  @notice calculate current bond premium
     *  @return price_ uint
     */
    function bondPrice(address _paw) public view returns (uint256 price_) {
        price_ = terms.controlVariable.mul(debtRatio()).add(1000000000).div(
            1e7
        );
        if (price_ < terms.minimumPrice) {
            price_ = terms.minimumPrice;
        }

        if (discountOf(_paw) > 0) {
            price_ = price_.sub(price_.mul(discountOf(_paw)).div(10000));
        }
    }

    /**
     *  @notice calculate current bond price and remove floor if above
     *  @return price_ uint
     */
    function _bondPrice(address _paw) internal returns (uint256 price_) {
        price_ = terms.controlVariable.mul(debtRatio()).add(1000000000).div(
            1e7
        );
        if (price_ < terms.minimumPrice) {
            price_ = terms.minimumPrice;
        } else if (terms.minimumPrice != 0) {
            terms.minimumPrice = 0;
        }
        if (discountOf(_paw) > 0) {
            price_ = price_.sub(price_.mul(discountOf(_paw)).div(10000));
        }
    }

    /**
     *  @notice converts bond price to DAI value
     *  @return price_ uint
     */
    function bondPriceInUSD(address _paw) public view returns (uint256 price_) {
        if (isLiquidityBond) {
            price_ = bondPrice(_paw)
                .mul(
                    IOtterBondingCalculator(bondCalculator).markdown(principle)
                )
                .div(100);
        } else {
            price_ = bondPrice(_paw).mul(10**IERC20(principle).decimals()).div(
                100
            );
        }
    }

    /**
     *  @notice calculate current ratio of debt to CLAM supply
     *  @return debtRatio_ uint
     */
    function debtRatio() public view returns (uint256 debtRatio_) {
        uint256 supply = IERC20(CLAM).totalSupply();
        debtRatio_ = FixedPoint
            .fraction(currentDebt().mul(1e9), supply)
            .decode112with18()
            .div(1e18);
    }

    /**
     *  @notice debt ratio in same terms for reserve or liquidity bonds
     *  @return uint
     */
    function standardizedDebtRatio() external view returns (uint256) {
        if (isLiquidityBond) {
            return
                debtRatio()
                    .mul(
                        IOtterBondingCalculator(bondCalculator).markdown(
                            principle
                        )
                    )
                    .div(1e9);
        } else {
            return debtRatio();
        }
    }

    /**
     *  @notice calculate debt factoring in decay
     *  @return uint
     */
    function currentDebt() public view returns (uint256) {
        return totalDebt.sub(debtDecay());
    }

    /**
     *  @notice amount to decay total debt by
     *  @return decay_ uint
     */
    function debtDecay() public view returns (uint256 decay_) {
        uint256 sinceLast = block.timestamp.sub(lastDecay);
        decay_ = totalDebt.mul(sinceLast).div(terms.vestingTerm);
        if (decay_ > totalDebt) {
            decay_ = totalDebt;
        }
    }

    /**
     *  @notice calculate how far into vesting a depositor is
     *  @param _depositor address
     *  @return percentVested_ uint
     */
    function percentVestedFor(address _depositor)
        public
        view
        returns (uint256 percentVested_)
    {
        Bond memory bond = bondInfo[_depositor];
        uint256 timeSinceLast = block.timestamp.sub(bond.lastTimestamp);
        uint256 vesting = bond.vesting;

        if (vesting > 0) {
            percentVested_ = timeSinceLast.mul(10000).div(vesting);
        } else {
            percentVested_ = 0;
        }
    }

    /**
     *  @notice calculate amount of CLAM available for claim by depositor
     *  @param _depositor address
     *  @return pendingPayout_ uint
     */
    function pendingPayoutFor(address _depositor)
        external
        view
        returns (uint256 pendingPayout_)
    {
        uint256 percentVested = percentVestedFor(_depositor);
        uint256 payout = IsCLAM(sCLAM).balanceForGons(
            bondInfo[_depositor].gonsPayout
        );

        if (percentVested >= 10000) {
            pendingPayout_ = payout;
        } else {
            pendingPayout_ = payout.mul(percentVested).div(10000);
        }
    }

    /* ======= AUXILLIARY ======= */

    /**
     *  @notice allow anyone to send lost tokens (excluding principle or CLAM) to the DAO
     *  @return bool
     */
    function recoverLostToken(address _token) external returns (bool) {
        require(_token != CLAM);
        require(_token != sCLAM);
        require(_token != principle);
        IERC20(_token).safeTransfer(
            DAO,
            IERC20(_token).balanceOf(address(this))
        );
        return true;
    }
}
