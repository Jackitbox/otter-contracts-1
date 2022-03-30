const { BigNumber } = require('ethers')
const { task, types } = require('hardhat/config')

const QUICK_ROUTER = '0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff'
const BUY_BACKER = '0x017aDb26B2Ea4dbd9f1372710748e1388fa3082a'
const CLAM = '0xc250e9987a032acac293d838726c511e6e1c029d'
const DAI_PATH = [
  '0x8f3cf7ad23cd3cadbd9735aff958023239c6a063',
  '0xa3fa99a148fa48d14ed51d610c367c61876997f1',
]
const QI_PATH = [
  '0x580a84c73811e1839f75d86d75d88cca0c241ff4', // qi
  '0x8f3cf7ad23cd3cadbd9735aff958023239c6a063', // dai
  '0xa3fa99a148fa48d14ed51d610c367c61876997f1', // mai
]

task('buyback', 'Buyback CLAM')
  .addPositionalParam('amountIn', '', null, types.string)
  .setAction(async ({ amountIn }, { ethers }) => {
    let parsedAmountIn = BigNumber.from(0)
    if (amountIn === 'max') {
      const qi = await ethers.getContractAt('IERC20', QI_PATH[0])
      parsedAmountIn = await qi.balanceOf(
        '0x8ce47D56EAa1299d3e06FF3E04637449fFb01C9C' // treasury
      )
    } else {
      parsedAmountIn = ethers.utils.parseEther(amountIn)
    }
    const quickSwapRouter = await ethers.getContractAt(
      'IUniswapV2Router02',
      QUICK_ROUTER
    )
    const amountsOut = await quickSwapRouter.getAmountsOut(parsedAmountIn, [
      ...QI_PATH,
      CLAM,
    ])
    let amountOutMin = amountsOut[amountsOut.length - 1]
    console.log('amount out: ' + amountOutMin)

    const buybacker = await ethers.getContractAt('OtterBuybacker', BUY_BACKER)
    const tx = await buybacker.buyback(
      QI_PATH,
      parsedAmountIn,
      amountOutMin.sub(ethers.utils.parseUnits('1', 9))
    )
    console.log(
      `buyback CLAM using QI: ${parsedAmountIn.toString()}` + '\ntx: ' + tx.hash
    )
    await tx.wait()
    console.log('done')
  })
