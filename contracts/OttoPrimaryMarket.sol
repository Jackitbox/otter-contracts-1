// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import './interfaces/IOtto.sol';
import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol';

contract OttoPrimaryMarket is OwnableUpgradeable {
    IOtto public OTTO;
    IERC20MetadataUpgradeable public WETH;
    IERC20MetadataUpgradeable public CLAM;
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
        address clam_,
        address dao_
    ) public initializer {
        __Ownable_init();
        OTTO = IOtto(otto_);
        WETH = IERC20MetadataUpgradeable(weth_);
        CLAM = IERC20MetadataUpgradeable(clam_);
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

    function payAndDistribute(uint256 price_, bool payInCLAM) private {}

    function mint(
        address to_,
        uint256 quantity_,
        uint256 price_,
        bool payInCLAM
    ) external callerIsUser quantityAllowedToMintOnEachStage(quantity_) {
        payAndDistribute(price_, payInCLAM);
        uint256[] memory arrTraits = new uint256[](quantity_);
        for (uint256 i = 0; i < quantity_; i++) {
            uint256 size = totalSupply();
            uint256 choosed = rand(size);
            arrTraits[i] = traitsPool[choosed];
            traitsPool[choosed] = traitsPool[size - 1];
            traitsPool.pop();
        }
        // TODO: tokenomic
        OTTO.mint(to_, quantity_, arrTraits);
        mintedAmount[msg.sender] += quantity_;
    }

    function emergencyWithdraw(address token_) external onlyOwner {
        uint256 balance = IERC20MetadataUpgradeable(token_).balanceOf(
            address(this)
        );
        IERC20MetadataUpgradeable(token_).transfer(dao, balance);
    }

    // FIXME: use chainlink vrf
    function rand(uint256 n) private view returns (uint256) {
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

    function priceInWETH() public view returns (uint256) {
        if (saleStage == SALE_STAGE.PRE_SALE) {
            return 6 * 10**17; // 0.6 ETH
        } else {
            return 8 * 10**17; // 0.8 ETH
        }
    }

    // FIXME: calculate price in CLAM using CLAM-MAI uniswap pair
    function priceInCLAM() public view returns (uint256) {
        return (priceInWETH() * CLAM.decimals()) / WETH.decimals();
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
        return (price_ * (100000 - discount_)) / 100000;
    }
}
