const { ethers, upgrades } = require('hardhat')

const dao = '0x929A27c46041196e1a49C7B459d63eC9A20cd879'
await hre.network.provider.request({
  method: 'hardhat_impersonateAccount',
  params: [dao],
})
let multisig = await ethers.getSigner(dao)

await hre.network.provider.request({
  method: 'hardhat_impersonateAccount',
  params: ['0x63B0fB7FE68342aFad3D63eF743DE4A74CDF462B'],
})
let deployer = await ethers.getSigner(
  '0x63B0fB7FE68342aFad3D63eF743DE4A74CDF462B'
)

// const TetuGovernance = '0xcc16d636dd05b52ff1d8b9ce09b09bc62b11412b'
// await hre.network.provider.request({
//   method: 'hardhat_impersonateAccount',
//   params: [TetuGovernance],
// })
// let tetuGovernance = await ethers.getSigner(TetuGovernance)
// let tetuController = new ethers.Contract(
//   '0x6678814c273d5088114b6e40cc49c8db04f9bc29',
//   require('./scripts/abi/TetuController.json'),
//   tetuGovernance
// )
// await tetuController.changeWhiteListStatus([QI_LOCKER], true)

const zeroAddress = '0x0000000000000000000000000000000000000000'
const QI = '0x580A84C73811E1839F75d86d75d88cCa0c241fF4'
const QI_LOCKER = '0x69f6c4Fa150F9F0b3037612CF8FadDAeDbd46Bb8'

let OtterQiLocker = await ethers.getContractFactory('OtterQiLocker', deployer)
let upgraded = await upgrades.upgradeProxy(QI_LOCKER, OtterQiLocker)
await upgraded.deployed()

let qiLocker = (await ethers.getContractAt('OtterQiLocker', QI_LOCKER)).connect(
  deployer
)
let qi = await ethers.getContractAt('IERC20', QI)
let tetuQi = new ethers.Contract(
  '0x4Cd44ced63d9a6FEF595f6AD3F7CED13fCEAc768',
  require('./scripts/abi/TetuSmartVault.json'),
  ethers.provider
)
let xTetuQi = new ethers.Contract(
  '0x8f1505C8F3B45Cb839D09c607939095a4195738e',
  require('./scripts/abi/TetuSmartVault.json'),
  ethers.provider
)

let treasury = await ethers.getContractAt(
  'OtterTreasury',
  '0x8ce47D56EAa1299d3e06FF3E04637449fFb01C9C'
)
// await deployer.sendTransaction({
//   value: ethers.utils.parseEther('10'),
//   to: multisig.address,
// })

// await treasury.connect(multisig).queue(2, ocQi.address) // reserve token
// await treasury.connect(multisig).queue(3, qiLocker.address) // reserve manager

// for (var i = 0; i < 86401; i++) {
//   await hre.network.provider.request({ method: 'evm_mine' })
//   console.log(i)
// }

// await treasury.connect(multisig).toggle(2, ocQi.address, zeroAddress)
// await treasury.connect(multisig).toggle(3, qiLocker.address, zeroAddress)

// await ocQi.toggleLocker(qiLocker.address)
// await qiLocker.lock(ethers.utils.parseEther('100'), '1')
// await qiLocker.lock(ethers.utils.parseEther('100'), '60108430')

// await hre.network.provider.request({
//   method: 'evm_increaseTime',
//   params: [86400],
// })

// for (var i = 0; i < 14 * 3; i++) {
//   await staking.rebase();
//   console.log(i)
// }

await hre.run('verify:verify', {
  address: ocQi.address,
  constructorArguments: [
    '0x580A84C73811E1839F75d86d75d88cCa0c241fF4', // qi
    '0x880decade22ad9c58a8a4202ef143c4f305100b3', // eQi
    '0x929A27c46041196e1a49C7B459d63eC9A20cd879', // dao
  ],
})
