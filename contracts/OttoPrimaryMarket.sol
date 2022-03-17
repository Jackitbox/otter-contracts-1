// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

// import 'hardhat/console.sol';
import './interfaces/IOtto.sol';
import './interfaces/IERC20.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';

interface IEACAggregatorProxy {
    function latestAnswer() external view returns (int256);

    function decimals() external view returns (uint8);
}

contract OttoPrimaryMarket is OwnableUpgradeable {
    IOtto public OTTO;
    IERC20 public WETH;
    IERC20 public CLAM;
    IERC20 public MAI;
    IUniswapV2Pair public MAICLAM;
    IEACAggregatorProxy wethPriceFeed;
    address public dao;

    SALE_STAGE public saleStage;

    mapping(address => uint256) public ottolisted;

    enum SALE_STAGE {
        NOT_STARTED,
        PRE_SALE,
        PUBLIC_SALE
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller is another contract');
        _;
    }

    modifier quantityAllowedToMintOnEachStage(uint256 quantity_) {
        require(saleStage != SALE_STAGE.NOT_STARTED, 'sale not started yet');
        if (saleStage == SALE_STAGE.PRE_SALE) {
            require(
                quantity_ <= ottolisted[msg.sender],
                'you are not allowed to mint with this amount'
            );
            ottolisted[msg.sender] -= quantity_;
        }
        _;
    }

    function initialize(
        address otto_,
        address weth_,
        address maiclam_,
        address wethPriceFeed_,
        address dao_
    ) public initializer {
        __Ownable_init();
        OTTO = IOtto(otto_);
        WETH = IERC20(weth_);
        MAICLAM = IUniswapV2Pair(maiclam_);
        MAI = IERC20(MAICLAM.token0());
        CLAM = IERC20(MAICLAM.token1());
        wethPriceFeed = IEACAggregatorProxy(wethPriceFeed_);
        dao = dao_;
    }

    function setOttolisted(uint256 amount_, address[] memory ottolisted_)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < ottolisted_.length; i++) {
            ottolisted[ottolisted_[i]] = amount_;
        }
    }

    function stopSale() external onlyOwner {
        saleStage = SALE_STAGE.NOT_STARTED;
    }

    function startPreSale() external onlyOwner {
        saleStage = SALE_STAGE.PRE_SALE;
    }

    function startPublicSale() external onlyOwner {
        saleStage = SALE_STAGE.PUBLIC_SALE;
    }

    function emergencyWithdraw(address token_) external onlyOwner {
        uint256 balance = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(dao, balance);
    }

    function giveaway(address to_, uint256 quantity_) public onlyOwner {
        OTTO.mint(to_, quantity_);
    }

    function mint(
        address to_,
        uint256 quantity_,
        uint256 maxPrice_,
        bool payInCLAM
    ) external callerIsUser quantityAllowedToMintOnEachStage(quantity_) {
        _payAndDistribute(quantity_, maxPrice_, payInCLAM);
        giveaway(to_, quantity_);
    }

    function _payAndDistribute(
        uint256 quantity_,
        uint256 maxPrice_,
        bool payInCLAM
    ) private {
        if (payInCLAM) {
            uint256 needed_ = priceInCLAM() * quantity_;
            // console.log('needed %s, maxPrice %s', needed_, maxPrice_);
            require(needed_ <= maxPrice_, 'price too low');
            CLAM.transferFrom(msg.sender, address(this), needed_);
            // TODO: distribute
        } else {
            uint256 needed_ = priceInWETH() * quantity_;
            // console.log('needed %s, maxPrice %s', needed_, maxPrice_);
            require(needed_ <= maxPrice_, 'price too low');
            WETH.transferFrom(msg.sender, address(this), needed_);
            // TODO: distribute
        }
    }

    function priceInWETH() public view returns (uint256 price_) {
        if (saleStage == SALE_STAGE.PRE_SALE) {
            price_ = 6 * 10**16; // 0.06 ETH
        } else {
            price_ = 8 * 10**16; // 0.08 ETH
        }
    }

    function priceInCLAM() public view returns (uint256 price_) {
        // mai decimals = 18
        // usd decimals = 8
        // clam decimals = 9
        // assume 1 USD = 1 MAI
        // 1 CLAM = x MAI
        // 1 WETH = y USD = y/x CLAM
        uint256 usdPerWETH = uint256(wethPriceFeed.latestAnswer()); // 10**6
        // console.log('usdPerWETH %s', usdPerWETH);
        uint256 maiPerCLAM = _maiPerCLAM();
        // console.log('maiPerCLAM %s', maiPerCLAM);
        uint256 clamPerWETH = (_toDecimal(
            usdPerWETH,
            wethPriceFeed.decimals()
        ) * 10**CLAM.decimals()) / _toDecimal(maiPerCLAM, MAI.decimals());
        // console.log('clamPerWETH %s', clamPerWETH);

        price_ = (priceInWETH() * clamPerWETH) / 10**WETH.decimals();
        // console.log('price in clam: %s', price_);
        // 30% off
        price_ = _calcDiscount(price_, 3000);
        // console.log('price with discount in clam: %s', price_);
    }

    function _maiPerCLAM() private view returns (uint256 price_) {
        (uint256 reserveMAI, uint256 reserveCLAM, ) = MAICLAM.getReserves();
        // console.log('reserveMAI %s, reserveCLAM %s', reserveMAI, reserveCLAM);
        price_ =
            (_toDecimal(reserveMAI, MAI.decimals()) * 10**MAI.decimals()) /
            _toDecimal(reserveCLAM, CLAM.decimals());
    }

    function _toDecimal(uint256 amount_, uint8 decimals_)
        private
        pure
        returns (uint256)
    {
        return (amount_ * 10**18) / 10**decimals_;
    }

    /**
     * @dev
     * `discount` 3000 means 30 % off
     */
    function _calcDiscount(uint256 price_, uint256 discount_)
        private
        pure
        returns (uint256)
    {
        return (price_ * (10000 - discount_)) / 10000;
    }
}
