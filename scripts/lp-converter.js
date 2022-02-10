const { ethers } = require('hardhat')

let addresses = {
  sCLAM_ADDRESS: '0xAAc144Dc08cE39Ed92182dd85ded60E5000C9e67',
  CLAM_ADDRESS: '0xC250e9987A032ACAC293d838726C511E6E1C029d',
  PEARL_ADDRESS: '0x52A7F40BB6e9BD9183071cdBdd3A977D713F2e34',
  OLD_CLAM_ADDRESS: '0x4d6A30EFBE2e9D7A9C143Fce1C5Bb30d9312A465',
  OLD_SCLAM_ADDRESS: '0x3949F058238563803b5971711Ad19551930C8209',
  MAI_ADDRESS: '0xa3Fa99A148fA48D14Ed51d610c367C61876997F1',
  TREASURY_ADDRESS: '0x8ce47D56EAa1299d3e06FF3E04637449fFb01C9C',
  CLAM_BONDING_CALC_ADDRESS: '0x651125e097D7e691f3Df5F9e5224f0181E3A4a0E',
  STAKING_ADDRESS: '0xC8B0243F350AA5F8B979b228fAe522DAFC61221a',
  OLD_STAKING_ADDRESS: '0xcF2A11937A906e09EbCb8B638309Ae8612850dBf',
  STAKING_HELPER_ADDRESS: '0x76B38319483b570B4BCFeD2D35d191d3c9E01691',
  MIGRATOR: '0xDaa1f5036eC158fca9E5ce791ab3e213cD1c41df',
  RESERVES: {
    MAI: '0xa3Fa99A148fA48D14Ed51d610c367C61876997F1',
    OLD_MAI_CLAM: '0x8094f4C9a4C8AD1FF4c6688d07Bd90f996C7CA21',
    MAI_CLAM: '0x1581802317f32A2665005109444233ca6E3e2D68',
  },
  BONDS: {
    OLD_MAI: '0x28077992bFA9609Ae27458A766470b03D43dEe8A',
    OLD_MAI_CLAM: '0x64c766f9A4936c3a4b51C55Ea5C4854E19766035',
    MAI: '0x603A74Fd527b85E0A1e205517c1f24aC71f5C263',
    MAI_CLAM: '0x706587BD39322A6a78ddD5491cDbb783F8FD983E',
  },
  CLAM_CIRCULATING_SUPPLY: '0x99ee91871cf39A44E3Fc842541274d7eA05AE4b3',
  LAKE: '0xc67aBdA25D0421FE9Dc1afd64183b179A426a256',
  LAKE_DISTRIBUTOR: '0xbB268A4b6be1bD2E676bfd46aaEA03A100324d35',
}

const zeroAddress = '0x0000000000000000000000000000000000000000'

await hre.network.provider.request({
  method: 'hardhat_impersonateAccount',
  params: ['0x929A27c46041196e1a49C7B459d63eC9A20cd879'],
})
let multisig = await ethers.getSigner(
  '0x929A27c46041196e1a49C7B459d63eC9A20cd879'
)

await hre.network.provider.request({
  method: 'hardhat_impersonateAccount',
  params: ['0x63B0fB7FE68342aFad3D63eF743DE4A74CDF462B'],
})
let deployer = await ethers.getSigner(
  '0x63B0fB7FE68342aFad3D63eF743DE4A74CDF462B'
)

const USDCMAI = '0x160532d2536175d65c03b97b0630a9802c274dad'
const USDC = '0x2791bca1f2de4661ed88a30c99a7a9449aa84174'

let LPConverter = await ethers.getContractFactory('OtterLPConverter')
let lpConverter = await LPConverter.deploy(
  '0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff', // quickswap router
  '0x5ab5C56B9db92Ba45a0B46a207286cD83C15C939', // curve zap
  '0x8ce47D56EAa1299d3e06FF3E04637449fFb01C9C', // treasury
  '0x929A27c46041196e1a49C7B459d63eC9A20cd879', // dao
  {
    gasPrice: ethers.utils.parseUnits('100', 'gwei'),
  }
)

await hre.run('verify:verify', {
  address: lpConverter.address,
  constructorArguments: [
    '0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff', // quickswap router
    '0x5ab5C56B9db92Ba45a0B46a207286cD83C15C939', // curve zap
    '0x8ce47D56EAa1299d3e06FF3E04637449fFb01C9C', // treasury
    '0x929A27c46041196e1a49C7B459d63eC9A20cd879', // dao
  ],
})

let treasury = await ethers.getContractAt(
  'OtterTreasury',
  '0x8ce47D56EAa1299d3e06FF3E04637449fFb01C9C'
)

await deployer.sendTransaction({
  value: ethers.utils.parseEther('10'),
  to: multisig.address,
})

await treasury.connect(multisig).queue(3, lpConverter.address)
await treasury.connect(multisig).queue(4, lpConverter.address)
await treasury.connect(multisig).queue(6, lpConverter.address)

for (var i = 0; i < 86401; i++) {
  await hre.network.provider.request({ method: 'evm_mine' })
  console.log(i)
}

await treasury.connect(multisig).toggle(3, lpConverter.address, zeroAddress)
await treasury.connect(multisig).toggle(4, lpConverter.address, zeroAddress)
await treasury.connect(multisig).toggle(6, lpConverter.address, zeroAddress)
// await treasury
//   .connect(multisig)
//   .toggle(5, USDCMAI, addresses.CLAM_BONDING_CALC_ADDRESS)

let qi = await ethers.getContractAt(
  'IERC20',
  '0x580A84C73811E1839F75d86d75d88cCa0c241fF4'
)
let wmatic = await ethers.getContractAt(
  'IERC20',
  '0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270'
)
let lp = await ethers.getContractAt('IERC20', USDCMAI)
let usdc = await ethers.getContractAt('IERC20', USDC)
let mai = await ethers.getContractAt('IERC20', addresses.MAI_ADDRESS)
let clam = await ethers.getContractAt('IERC20', addresses.CLAM_ADDRESS)

// await hre.network.provider.request({
//   method: 'evm_increaseTime',
//   params: [86400],
// })

// for (var i = 0; i < 14 * 3; i++) {
//   await staking.rebase();
//   console.log(i)
// }
