const { ethers, upgrades } = require('hardhat')

async function main() {
  let OtterQiLocker = await ethers.getContractFactory('OtterQiLocker')
  let upgraded = await upgrades.upgradeProxy(
    '0x69f6c4Fa150F9F0b3037612CF8FadDAeDbd46Bb8',
    OtterQiLocker
  )
  await upgraded.deployed()
  console.log('Upgraded: ', upgraded.address)
}

main()
  .then(() => process.exit())
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
