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

    uint256[] public traitsPool;

    SALE_STAGE public saleStage;

    mapping(address => bool) public ottolisted;
    mapping(address => bool) public diamondhands;
    mapping(address => uint256) public mintedAmount;

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
        require(totalSupply() >= quantity_, 'out of stock');
        require(saleStage != SALE_STAGE.NOT_STARTED, 'sale not started yet');
        if (saleStage == SALE_STAGE.PRE_SALE) {
            if (ottolisted[msg.sender] && diamondhands[msg.sender]) {
                require(
                    quantity_ + mintedAmount[msg.sender] <= 6,
                    'you can not mint over 6 tokens'
                );
            } else if (ottolisted[msg.sender] && !diamondhands[msg.sender]) {
                require(
                    quantity_ + mintedAmount[msg.sender] <= 3,
                    'you can not mint over 3 tokens'
                );
            } else if (!ottolisted[msg.sender] && diamondhands[msg.sender]) {
                require(
                    quantity_ + mintedAmount[msg.sender] <= 3,
                    'you can not mint over 3 tokens'
                );
            } else {
                revert('you are not allowed to mint');
            }
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

    function setOttolisted(address[] memory ottolisted_) external onlyOwner {
        for (uint256 i = 0; i < ottolisted_.length; i++) {
            ottolisted[ottolisted_[i]] = true;
        }
    }

    function preSaleStart() external onlyOwner {
        saleStage = SALE_STAGE.PRE_SALE;
    }

    function publicSaleStart() external onlyOwner {
        saleStage = SALE_STAGE.PUBLIC_SALE;
    }

    function setDiamondhands(address[] memory diamondhands_)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < diamondhands_.length; i++) {
            diamondhands[diamondhands_[i]] = true;
        }
    }

    function prepare(uint256[] memory pool) external onlyOwner {
        for (uint256 i = 0; i < pool.length; i++) {
            traitsPool.push(pool[i]);
        }
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

    function mint(
        address to_,
        uint256 quantity_,
        uint256 maxPrice_,
        bool payInCLAM
    ) external callerIsUser quantityAllowedToMintOnEachStage(quantity_) {
        _payAndDistribute(quantity_, maxPrice_, payInCLAM);
        uint256[] memory arrTraits = new uint256[](quantity_);
        for (uint256 i = 0; i < quantity_; i++) {
            uint256 size = totalSupply();
            uint256 choosed = _rand(size);
            arrTraits[i] = traitsPool[choosed];
            traitsPool[choosed] = traitsPool[size - 1];
            traitsPool.pop();
        }
        // TODO: tokenomic
        OTTO.mint(to_, quantity_, arrTraits);
        mintedAmount[msg.sender] += quantity_;
    }

    function emergencyWithdraw(address token_) external onlyOwner {
        uint256 balance = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(dao, balance);
    }

    // FIXME: use chainlink vrf
    function _rand(uint256 n) private view returns (uint256) {
        // sha3 and now have been deprecated
        return
            uint256(
                keccak256(abi.encodePacked(block.difficulty, block.timestamp))
            ) % n;
        // convert hash to integer
        // players is an array of entrants
    }

    function totalSupply() public view returns (uint256) {
        return traitsPool.length;
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
        uint256 clamPerWETH = (_valueOf(usdPerWETH, wethPriceFeed.decimals()) *
            10**CLAM.decimals()) / _valueOf(maiPerCLAM, MAI.decimals());
        // console.log('clamPerWETH %s', clamPerWETH);

        price_ = (priceInWETH() * clamPerWETH) / 10**WETH.decimals();
        // console.log('price in clam: %s', price_);
        // 30% off
        price_ = discountPrice(price_, 3000);
        // console.log('price with discount in clam: %s', price_);
    }

    function _maiPerCLAM() private view returns (uint256 price_) {
        (uint256 reserveMAI, uint256 reserveCLAM, ) = MAICLAM.getReserves();
        // console.log('reserveMAI %s, reserveCLAM %s', reserveMAI, reserveCLAM);
        price_ =
            (_valueOf(reserveMAI, MAI.decimals()) * 10**MAI.decimals()) /
            _valueOf(reserveCLAM, CLAM.decimals());
    }

    function _valueOf(uint256 amount_, uint8 decimals_)
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
    function discountPrice(uint256 price_, uint256 discount_)
        public
        pure
        returns (uint256)
    {
        return (price_ * (10000 - discount_)) / 10000;
    }
}
