// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.9;

import '@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol';
import '@uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol';

import '../interfaces/IOtterTreasury.sol';
import '../interfaces/IERC20.sol';
import '../interfaces/IOtterClamQi.sol';
import '../interfaces/IEQi.sol';

import '../types/LockerOwnedUpgradeable.sol';

interface ISmartVault is IERC20 {
    function depositAndInvest(uint256 amount) external;
}

contract OtterQiLocker is LockerOwnedUpgradeable, UUPSUpgradeable {
    event Lock(uint256 amount, uint256 blockNumber);
    event Leave(uint256 amount);
    event Harvest(uint256 amount);
    event ConvertToQi(address token, uint256 amountIn, uint256 amountOut);
    event ConvertToTetuQi(address token, uint256 amountIn, uint256 amountOut);

    IERC20 public qi;
    IOtterClamQi public ocQi;
    IOtterTreasury public treasury;
    address public dao;

    function initialize(
        address qi_,
        address ocQi_,
        address treasury_,
        address dao_
    ) public initializer {
        __Ownable_init();
        qi = IERC20(qi_);
        ocQi = IOtterClamQi(ocQi_);
        treasury = IOtterTreasury(treasury_);
        dao = dao_;
    }

    IEQi public constant eQi = IEQi(0x880DeCADe22aD9c58A8A4202EF143c4F305100B3);

    /// @notice Lock Qi to QiDAO and mint ocQi to treasury
    /// @param amount_ the amount of qi
    function lock(uint256 amount_) public onlyLocker {
        treasury.manage(address(qi), amount_);
        qi.approve(address(ocQi), amount_);
        uint256 endBlock = eQi.userInfo(address(ocQi)).endBlock;
        uint256 maxLock = ocQi.maxLock();  // 4 years
        uint256 diffBlock = 0;
        if (endBlock == 0) {
            diffBlock = maxLock;
        } else if (endBlock < (block.number + maxLock)) {
            diffBlock = (block.number + maxLock) - endBlock;
        }
        ocQi.lock(address(treasury), amount_, diffBlock);
        emit Lock(amount_, diffBlock);
    }

    /// @notice Unlock Qi from QiDAO and burn ocQi
    function unlock() external onlyLocker {
        uint256 treasuryAmount = IERC20(address(ocQi)).balanceOf(
            address(treasury)
        );
        treasury.manage(address(ocQi), treasuryAmount);
        ocQi.unlock(address(treasury), treasuryAmount);
        emit Leave(treasuryAmount);
    }

    /// @notice Harvest reward from QiDAO
    /// @param relock_ the boolean showing to lock or not
    function harvest(bool relock_) external onlyLocker {
        uint256 rewards = ocQi.collectReward(address(treasury));
        if (relock_) {
            lock(rewards);
        }
        emit Harvest(rewards);
    }

    address public constant QuickSwapRouter =
        0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff;

    function convertToQI(
        address[] memory path_,
        uint256 amountIn_,
        uint256 amountOutMin_
    ) public onlyLocker returns (uint256) {
        address source = path_[0];
        treasury.manage(source, amountIn_);
        address[] memory path = new address[](path_.length + 1);
        for (uint256 i = 0; i < path_.length; i++) {
            path[i] = path_[i];
        }
        path[path_.length] = address(qi);
        IERC20(source).approve(QuickSwapRouter, amountIn_);
        uint256[] memory amounts = IUniswapV2Router02(QuickSwapRouter)
            .swapExactTokensForTokens(
                amountIn_,
                amountOutMin_,
                path,
                address(treasury),
                block.timestamp
            );
        emit ConvertToQi(source, amountIn_, amounts[amounts.length - 1]);
        return amounts[amounts.length - 1];
    }

    // ===== TetuQi =====

    ISmartVault public constant tetuQi =
        ISmartVault(0x4Cd44ced63d9a6FEF595f6AD3F7CED13fCEAc768);
    ISmartVault public constant xTetuQi =
        ISmartVault(0x8f1505C8F3B45Cb839D09c607939095a4195738e);
    IUniswapV2Router02 public constant tetuRouter =
        IUniswapV2Router02(0x736FD9EabB15776A3adfea1B975c868F72A29d14);

    function convertToTetuQi(
        address[] memory path_,
        uint256 amountIn_,
        uint256 amountOutMin_,
        bool stake
    ) external onlyLocker {
        uint256 qiAmount = amountIn_;
        if (path_.length > 0) {
            qiAmount = convertToQI(path_, amountIn_, amountOutMin_);
        }
        treasury.manage(address(qi), qiAmount);
        address[] memory tetuQiPath = new address[](2);
        tetuQiPath[0] = address(qi);
        tetuQiPath[1] = address(tetuQi);
        uint256[] memory swapTetuQiOutput = tetuRouter.getAmountsOut(
            qiAmount,
            tetuQiPath
        );
        if (swapTetuQiOutput[1] > qiAmount) {
            qi.approve(address(tetuRouter), qiAmount);
            uint256[] memory tetuQiOutput = tetuRouter.swapExactTokensForTokens(
                qiAmount,
                swapTetuQiOutput[1],
                tetuQiPath,
                address(this),
                block.timestamp
            );
            qiAmount = tetuQiOutput[1];
        } else {
            qi.approve(address(tetuQi), qiAmount);
            tetuQi.depositAndInvest(qiAmount);
        }
        if (stake) {
            tetuQi.approve(address(xTetuQi), tetuQi.balanceOf(address(this)));
            xTetuQi.depositAndInvest(tetuQi.balanceOf(address(this)));
            xTetuQi.transfer(
                address(treasury),
                xTetuQi.balanceOf(address(this))
            );
        } else {
            tetuQi.transfer(address(treasury), tetuQi.balanceOf(address(this)));
        }
        emit ConvertToTetuQi(
            path_.length > 0 ? path_[0] : address(qi),
            amountIn_,
            qiAmount
        );
    }

    // ===== Emgerency =====

    function emergencyWithdraw(address token_) external onlyOwner {
        uint256 balance = IERC20(token_).balanceOf(address(this));
        IERC20(token_).transfer(dao, balance);
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
