const { ethers, upgrades } = require('hardhat')

async function main() {
  let OtterClamQi2 = await ethers.getContractFactory('OtterClamQi2')
  let ocQi = await upgrades.upgradeProxy('0xProxy', OtterClamQi2)
  console.log('ocQi2: ', ocQi.address)
}

main()
  .then(() => process.exit())
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
