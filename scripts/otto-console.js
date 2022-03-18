const { ethers } = require('hardhat')

let deployer = await ethers.getSigner()
let devAddr = 'CHANGE_ME'
let daoAddress = '0x929a27c46041196e1a49c7b459d63ec9a20cd879'
await (
  await deployer.sendTransaction({
    to: daoAddress,
    value: ethers.utils.parseEther('0.5'),
  })
).wait()
let daoAddress = '0x929a27c46041196e1a49c7b459d63ec9a20cd879'
await hre.network.provider.request({
  method: 'hardhat_impersonateAccount',
  params: [daoAddress],
})
let dao = await ethers.getSigner(daoAddress)
let clam = await ethers.getContractAt(
  'ERC20',
  '0xC250e9987A032ACAC293d838726C511E6E1C029d'
)
await (
  await clam.connect(dao).transfer(devAddr, ethers.utils.parseUnits('500', 9))
).wait()

let ottoAddr = '0xd3bC207ffA860B389D2EC35075605147c2A98670'
let portalCreatorAddr = '0xA2B66209A3872257F4FC2532bF35138f466f13ea'

let OTTO = await ethers.getContractFactory('Otto')
let otto = OTTO.attach(ottoAddr)
let PORTALCREATOR = await ethers.getContractFactory('OttopiaPortalCreator')
let portalCreator = PORTALCREATOR.attach(portalCreatorAddr)

await (await otto.grantMinter(portalCreatorAddr)).wait()
await (await portalCreator.setOttolisted(3, [devAddr])).wait()

await network.provider.send('evm_setNextBlockTimestamp', [
  new Date('2022-03-19T13:00:00Z').getTime() / 1000,
])
await network.provider.send('evm_mine')

await (await portalCreator.devMint(deployer.address, 1)).wait()
