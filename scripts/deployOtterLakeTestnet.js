const { ethers } = require('hardhat')

async function main() {
  // const Staking = await ethers.getContractFactory('OtterStaking')
  // const staking = Staking.attach(POLYGON_MAINNET.STAKING_ADDRESS)
  // const epoch = await staking.epoch()

  // console.log('Current epoch: ' + epoch.number.toString())
  // console.log('Epoch length : ' + epoch.length.toString())
  // console.log('Epoch end time : ' + epoch.endTime.toString())
  const epochLength = 28800
  const epoch = 194
  const endTime = 1641456000
  const pearlAddress = '0x19907af68A173080c3e05bb53932B0ED541f6d20'

  const Lake = await ethers.getContractFactory('OtterLake')
  const lake = await Lake.deploy(pearlAddress, epochLength, epoch, endTime)
  await lake.deployTransaction.wait()
  console.log('Pearl Lake deployed at: ' + lake.address)

  const OtterLakeDistributor = await ethers.getContractFactory(
    'OtterLakeDistributor'
  )
  const otterLakeDistributor = await OtterLakeDistributor.deploy(
    pearlAddress,
    '0x3059fa18F6b339D630d06963839FAf1513eE2E9E',
    '0x7A663e1BF34cB44D1aa0Ee29CE53D2D0c4Ab97De',
    '0x2A0AFb64c1A5F69D585478700ad6dDA0A5dFB68a',
    lake.address,
    epochLength,
    endTime
  )
  await otterLakeDistributor.deployTransaction.wait()
  console.log(
    'Pearl Lake Distributor deployed at: ' + otterLakeDistributor.address
  )

  await lake.setDistributor(otterLakeDistributor.address)

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
