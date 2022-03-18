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

contract OttopiaPortalCreator is OwnableUpgradeable {
    IOtto public OTTO;
    IERC20 public WETH;
    IERC20 public CLAM;
    IERC20 public MAI;
    IUniswapV2Pair public MAICLAM;
    IEACAggregatorProxy wethPriceFeed;
    address treasury;
    address public dao;

    mapping(address => uint256) public ottolisted;
    mapping(SALE_STAGE => SaleConfig) public saleConfig; // in ETH
    uint256 public devCanMint;

    enum SALE_STAGE {
        NOT_STARTED,
        PRE_SALE,
        PUBLIC_SALE
    }

    struct SaleConfig {
        uint256 timestamp;
        uint256 price;
    }

    modifier callerIsUser() {
        require(tx.origin == msg.sender, 'The caller is another contract');
        _;
    }

    modifier quantityAllowedToMintOnEachStage(uint256 quantity_) {
        require(saleStage() != SALE_STAGE.NOT_STARTED, 'sale not started yet');
        if (saleStage() == SALE_STAGE.PRE_SALE) {
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
        address treasury_,
        address dao_
    ) public initializer {
        __Ownable_init();
        OTTO = IOtto(otto_);
        WETH = IERC20(weth_);
        MAICLAM = IUniswapV2Pair(maiclam_);
        MAI = IERC20(MAICLAM.token0());
        CLAM = IERC20(MAICLAM.token1());
        wethPriceFeed = IEACAggregatorProxy(wethPriceFeed_);
        treasury = treasury_;
        dao = dao_;

        saleConfig[SALE_STAGE.NOT_STARTED] = SaleConfig({
            timestamp: 0,
            price: 8 * 10**16 // 0.08 ETH
        });
        saleConfig[SALE_STAGE.PRE_SALE] = SaleConfig({
            timestamp: 1647694800, // 2022-03-19T13:00:00.000Z
            price: 6 * 10**16 // 0.06 ETH
        });
        saleConfig[SALE_STAGE.PUBLIC_SALE] = SaleConfig({
            timestamp: 1647781200, // 2022-03-20T13:00:00.000Z
            price: 8 * 10**16 // 0.08 ETH
        });
        devCanMint = 250;
    }

    function setOttolisted(uint256 amount_, address[] memory ottolisted_)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < ottolisted_.length; i++) {
            ottolisted[ottolisted_[i]] = amount_;
        }
    }

    function adjustSaleConfig(
        SALE_STAGE stage_,
        uint256 timestamp_,
        uint256 price_
    ) external onlyOwner {
        saleConfig[stage_].timestamp = timestamp_;
        saleConfig[stage_].price = price_;
    }

    function emergencyWithdraw(address token_) external onlyOwner {
        uint256 balance = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(dao, balance);
    }

    function distribute() external onlyOwner {
        uint256 clamBalance = CLAM.balanceOf(address(this));
        CLAM.transfer(dao, clamBalance);

        uint256 wethBalance = WETH.balanceOf(address(this));
        uint256 toTreasury = _calcPercentage(wethBalance, 5000);
        WETH.transfer(treasury, toTreasury);
        WETH.transfer(dao, wethBalance - toTreasury);
    }

    function devMint(address to_, uint256 quantity_) external onlyOwner {
        require(quantity_ > 0, 'devMint quantity must be greater than 0');
        require(quantity_ <= OTTO.totalMintable(), 'not enough tokens');
        require(quantity_ <= devCanMint, 'not enough tokens for dev');
        devCanMint -= quantity_;

        uint256 maxBatch = OTTO.maxBatch();
        uint256 round = quantity_ / maxBatch;
        uint256 remainder = quantity_ % maxBatch;
        for (uint256 i = 0; i < round; i++) {
            OTTO.mint(to_, maxBatch);
        }
        if (remainder > 0) {
            OTTO.mint(to_, remainder);
        }
    }

    function mint(
        address to_,
        uint256 quantity_,
        uint256 maxPrice_,
        bool payInCLAM
    ) external callerIsUser quantityAllowedToMintOnEachStage(quantity_) {
        _pay(quantity_, maxPrice_, payInCLAM);
        OTTO.mint(to_, quantity_);
    }

    function _pay(
        uint256 quantity_,
        uint256 maxPrice_,
        bool payInCLAM
    ) private {
        if (payInCLAM) {
            uint256 needed_ = priceInCLAM() * quantity_;
            // console.log('needed %s, maxPrice %s', needed_, maxPrice_);
            require(needed_ <= maxPrice_, 'price too low');
            CLAM.transferFrom(msg.sender, address(this), needed_);
        } else {
            uint256 needed_ = priceInWETH() * quantity_;
            // console.log('needed %s, maxPrice %s', needed_, maxPrice_);
            require(needed_ <= maxPrice_, 'price too low');
            WETH.transferFrom(msg.sender, address(this), needed_);
        }
    }

    function saleStage() public view returns (SALE_STAGE stage_) {
        if (block.timestamp >= saleConfig[SALE_STAGE.PUBLIC_SALE].timestamp) {
            return SALE_STAGE.PUBLIC_SALE;
        } else if (
            block.timestamp >= saleConfig[SALE_STAGE.PRE_SALE].timestamp
        ) {
            return SALE_STAGE.PRE_SALE;
        } else {
            return SALE_STAGE.NOT_STARTED;
        }
    }

    function priceInWETH() public view returns (uint256 price_) {
        return saleConfig[saleStage()].price;
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
        price_ = _calcPercentage(price_, 7000);
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
     * `discount` 7000 means 70% => 30% off
     */
    function _calcPercentage(uint256 price_, uint256 percentage_)
        private
        pure
        returns (uint256)
    {
        return (price_ * percentage_) / 10000;
    }
}
