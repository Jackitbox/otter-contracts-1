const { task, types } = require('hardhat/config')

const QUICK_ROUTER = '0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff'
const BUY_BACKER = '0x155D21B6D7EB5DD1035A9Ae57201C20ff1ea90D2'
const CLAM = '0xc250e9987a032acac293d838726c511e6e1c029d'
const DAI_PATH = [
  '0x8f3cf7ad23cd3cadbd9735aff958023239c6a063',
  '0xa3fa99a148fa48d14ed51d610c367c61876997f1',
]

task('buyback', 'Buyback CLAM')
  .addPositionalParam('amountIn', '', null, types.string)
  .setAction(async ({ amountIn }, { ethers }) => {
    const parsedAmountIn = ethers.utils.parseEther(amountIn)
    const quickSwapRouter = await ethers.getContractAt(
      'IUniswapV2Router02',
      QUICK_ROUTER
    )
    const amountsOut = await quickSwapRouter.getAmountsOut(parsedAmountIn, [
      ...DAI_PATH,
      CLAM,
    ])
    let amountOutMin = amountsOut[amountsOut.length - 1]
    console.log('amount out: ' + amountOutMin)

    const buybacker = await ethers.getContractAt('OtterBuybacker', BUY_BACKER)
    const tx = await buybacker.buyback(
      DAI_PATH,
      parsedAmountIn,
      amountOutMin.sub(ethers.utils.parseUnits('1', 9))
    )
    console.log(`buyback CLAM using DAI: $${amountIn}` + '\ntx: ' + tx.hash)
    await tx.wait()
    console.log('done')
  })
