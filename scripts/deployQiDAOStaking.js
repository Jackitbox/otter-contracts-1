const { ethers, upgrades } = require('hardhat')

async function main() {
  let Staking = await ethers.getContractFactory('OtterQiDAOCurveStaking')
  let staking = await upgrades.deployProxy(
    Staking,
    [
      '0x447646e84498552e62eCF097Cc305eaBFFF09308', // curve lp
      '0x580A84C73811E1839F75d86d75d88cCa0c241fF4', // qi
      '0x0635af5ab29fc7bba007b8cebad27b7a3d3d1958', // qi farm
      '0x8ce47D56EAa1299d3e06FF3E04637449fFb01C9C', // treasury
      '0x929A27c46041196e1a49C7B459d63eC9A20cd879', // dao
    ],
    { kind: 'uups' }
  )
  await staking.deployed()
  console.log('Staking: ', staking.address)

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
