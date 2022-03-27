const { ethers, upgrades } = require('hardhat')

async function main() {
  let Buybacker = await ethers.getContractFactory('OtterBuybacker')
  let buybacker = await upgrades.deployProxy(
    Buybacker,
    [
      '0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff', // quickswap router
      '0x8ce47D56EAa1299d3e06FF3E04637449fFb01C9C', // treasury
      '0xC250e9987A032ACAC293d838726C511E6E1C029d', // clam
      '0x929A27c46041196e1a49C7B459d63eC9A20cd879', // dao
    ],
    { kind: 'uups' }
  )
  await buybacker.deployed()
  console.log('buybacker: ', buybacker.address)

  // await hre.run('verify:verify', {
  //   address: ocQi.address,
  //   constructorArguments: [
  //     '0x580A84C73811E1839F75d86d75d88cCa0c241fF4', // qi
  //     '0x880decade22ad9c58a8a4202ef143c4f305100b3', // eQi
  //     '0x929A27c46041196e1a49C7B459d63eC9A20cd879', // dao
  //   ],
  // })
}

main()
  .then(() => process.exit())
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
