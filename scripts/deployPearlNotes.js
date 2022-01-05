const { ethers } = require('hardhat')

const PEARL_ADDRESS = '0x52A7F40BB6e9BD9183071cdBdd3A977D713F2e34'
const VAULT_ADDRESS = '0xf4fa0d1c10c47cde9f65d56c3ec977cbeb13449a'

const zeroAddress = '0x0000000000000000000000000000000000000000'
const daoAddr = '0x929a27c46041196e1a49c7b459d63ec9a20cd879'
const reserveAddr = '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270'

async function main() {
  const Staking = await ethers.getContractFactory('OtterStaking')
  const staking = Staking.attach(POLYGON_MAINNET.STAKING_ADDRESS)
  const epoch = await staking.epoch()

  console.log('Current epoch: ' + epoch.number.toString())
  console.log('Epoch length : ' + epoch.length.toString())
  console.log('Epoch end time : ' + epoch.endTime.toString())

  const Vault = await ethers.getContractFactory('OtterLake')
  const vault = await Vault.deploy(
    POLYGON_MAINNET.PEARL_ADDRESS,
    epoch.length,
    epoch.number,
    epoch.endTime
  )
  await vault.deployTransaction.wait()
  console.log('Pearl Vault deployed at: ' + vault.address)

  const OtterLakeDistributor = await ethers.getContractFactory(
    'OtterLakeDistributor'
  )
  const otterLakeDistributor = await OtterLakeDistributor.deploy(
    POLYGON_MAINNET.PEARL_ADDRESS,
    POLYGON_MAINNET.CLAM_ADDRESS,
    POLYGON_MAINNET.sCLAM_ADDRESS,
    POLYGON_MAINNET.STAKING_ADDRESS,
    vault.address,
    epoch.length,
    epoch.endTime
  )
  await otterLakeDistributor.deployTransaction.wait()
  console.log(
    'Pearl Vault Distributor deployed at: ' + otterLakeDistributor.address
  )

  await vault.setDistributor(otterLakeDistributor.address)

  // await hre.run('verify:verify', {
  //   address: bond.address,
  //   constructorArguments: [
  //     addresses.CLAM_ADDRESS,
  //     addresses.sCLAM_ADDRESS,
  //     reserveAddr,
  //     addresses.TREASURY_ADDRESS,
  //     daoAddr,
  //     addresses.STAKING_ADDRESS,
  //     oracleAddr,
  //   ],
  // })
}

main()
  .then(() => console.log('done'))
  .catch((err) => console.error(err))
