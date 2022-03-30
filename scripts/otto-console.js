const { ethers } = require('hardhat')

let deployer = await ethers.getSigner()
let daoAddress = '0x929a27c46041196e1a49c7b459d63ec9a20cd879'
await deployer.sendTransaction({
  to: daoAddress,
  value: ethers.utils.parseEther('0.5'),
})
await hre.network.provider.request({
  method: 'hardhat_impersonateAccount',
  params: [daoAddress],
})

let devAddr = '0x016bc76cd93b6e2e026ba3130b1dc30098ebfe9e'
await hre.network.provider.request({
  method: 'hardhat_impersonateAccount',
  params: [devAddr],
})
let dev = await ethers.getSigner(devAddr)

let dao = await ethers.getSigner(daoAddress)
let clam = await ethers.getContractAt(
  'ERC20',
  '0xC250e9987A032ACAC293d838726C511E6E1C029d'
)
await (
  await clam.connect(dao).transfer(devAddr, ethers.utils.parseUnits('500', 9))
).wait()

let ottoAddr = '0x6e8A9Cb6B1E73e9fCe3FD3c68b5af9728F708eB7'
let portalCreatorAddr = '0xCb8Ba0c08e746CA6fa79fe535580f89A8eC082C2'

let otto = (await ethers.getContractAt('OttoV2', ottoAddr)).connect(dev)
let portalCreator = (
  await ethers.getContractAt('OttopiaPortalCreator', portalCreatorAddr)
).connect(dev)

await (await otto.grantMinter(portalCreatorAddr)).wait()
await (await portalCreator.setOttolisted(3, [devAddr])).wait()

await network.provider.send('evm_setNextBlockTimestamp', [
  new Date('2022-03-20T13:00:00Z').getTime() / 1000,
])
await network.provider.send('evm_mine')

await (
  await otto.setBaseURI('https://api.otterclam.finance/ottos/metadata/')
).wait()
await (await portalCreator.devMint(deployer.address, 1)).wait()
await (
  await portalCreator.mint(
    deployer.address,
    1,
    await portalCreator.priceInCLAM(),
    true
  )
).wait()
