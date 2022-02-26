const { ethers, upgrades } = require('hardhat')

async function main() {
  // let OtterClamQi = await ethers.getContractFactory('OtterClamQi')
  // let ocQi = await upgrades.deployProxy(
  //   OtterClamQi,
  //   [
  //     '0x580A84C73811E1839F75d86d75d88cCa0c241fF4', // qi
  //     '0x880decade22ad9c58a8a4202ef143c4f305100b3', // eQi
  //     '0x929A27c46041196e1a49C7B459d63eC9A20cd879', // dao
  //   ],
  //   { kind: 'uups' }
  // )
  // await ocQi.deployed()
  // console.log('ocQi: ', ocQi.address)

  let OtterQiLocker = await ethers.getContractFactory('OtterQiLocker')
  let qiLocker = await upgrades.deployProxy(
    OtterQiLocker,
    [
      '0x580A84C73811E1839F75d86d75d88cCa0c241fF4', // qi
      '0x0906ee253B2cD6737A3CD3838490Cb0b90fD68be', // ocQi
      '0x8ce47D56EAa1299d3e06FF3E04637449fFb01C9C', // treasury
      '0x929A27c46041196e1a49C7B459d63eC9A20cd879', // dao
    ],
    { kind: 'uups' }
  )
  await qiLocker.deployed()
  console.log('qiLocker: ', qiLocker.address)

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
