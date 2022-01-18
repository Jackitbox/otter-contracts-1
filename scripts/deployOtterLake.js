const { ethers } = require('hardhat')

const POLYGON_MAINNET = {
  sCLAM_ADDRESS: '0xAAc144Dc08cE39Ed92182dd85ded60E5000C9e67',
  CLAM_ADDRESS: '0xC250e9987A032ACAC293d838726C511E6E1C029d',
  PEARL_ADDRESS: '0x52A7F40BB6e9BD9183071cdBdd3A977D713F2e34',
  OLD_CLAM_ADDRESS: '0x4d6A30EFBE2e9D7A9C143Fce1C5Bb30d9312A465',
  OLD_SCLAM_ADDRESS: '0x3949F058238563803b5971711Ad19551930C8209',
  MAI_ADDRESS: '0xa3Fa99A148fA48D14Ed51d610c367C61876997F1',
  TREASURY_ADDRESS: '0x8ce47D56EAa1299d3e06FF3E04637449fFb01C9C',
  OLD_TREASURY: '0xab328Ca61599974b0f577d1F8AB0129f2842d765',
  CLAM_BONDING_CALC_ADDRESS: '0x651125e097D7e691f3Df5F9e5224f0181E3A4a0E',
  STAKING_ADDRESS: '0xC8B0243F350AA5F8B979b228fAe522DAFC61221a',
  OLD_STAKING_ADDRESS: '0xcF2A11937A906e09EbCb8B638309Ae8612850dBf',
  STAKING_HELPER_ADDRESS: '0x76B38319483b570B4BCFeD2D35d191d3c9E01691',
  MIGRATOR: '0xDaa1f5036eC158fca9E5ce791ab3e213cD1c41df',
  RESERVES: {
    MAI: '0xa3Fa99A148fA48D14Ed51d610c367C61876997F1',
    OLD_MAI_CLAM: '0x8094f4C9a4C8AD1FF4c6688d07Bd90f996C7CA21',
    MAI_CLAM: '0x1581802317f32A2665005109444233ca6E3e2D68',
  },
  BONDS: {
    MAI: '0x603A74Fd527b85E0A1e205517c1f24aC71f5C263',
    MAI_CLAM: '0x706587BD39322A6a78ddD5491cDbb783F8FD983E',
    OLD_MAI: '0x28077992bFA9609Ae27458A766470b03D43dEe8A',
    OLD_MAI_CLAM: '0x79B47c03B02019Af78Ee0de9B0b3Ac0786338a0d',
    OLD_MAI_CLAM_V2: '0x64c766f9A4936c3a4b51C55Ea5C4854E19766035',
  },
  NFTS: {
    SAFE_HAND: '0xaAd62438fB1Bf9560d93dD7D691c528CB087C2F6',
    FURRY_HAND: '0x2A6c8531F8a125098b2f2beeaBb2705FE348474A',
    STONE_HAND: '0xE93740Df02471aD89B4E1DF7C2aC0BC575519BC5',
    DIAMOND_HAND: '0x812ae364659B3c7C47322e8Acfbde2eca2c4c439',
  },
  CLAM_CIRCULATING_SUPPLY: '0x99ee91871cf39A44E3Fc842541274d7eA05AE4b3',
  IDO: '0x7f637ea843405dff10592f894292a8f1188166f9',
}

async function main() {
  const Staking = await ethers.getContractFactory('OtterStaking')
  const staking = Staking.attach(POLYGON_MAINNET.STAKING_ADDRESS)
  const epoch = await staking.epoch()

  console.log('Current epoch: ' + epoch.number.toString())
  console.log('Epoch length : ' + epoch._length.toString())
  console.log('Epoch end time : ' + epoch.endTime.toString())

  // const Lake = await ethers.getContractFactory('OtterLake')
  // const lake = Lake.attach('0xc67aBdA25D0421FE9Dc1afd64183b179A426a256')
  // const lake = await Lake.deploy(
  //   POLYGON_MAINNET.PEARL_ADDRESS,
  //   epoch._length,
  //   epoch.number,
  //   epoch.endTime
  // )
  // await lake.deployTransaction.wait()
  // console.log('Pearl Lake deployed at: ' + lake.address)

  // const OtterLakeDistributor = await ethers.getContractFactory(
  //   'OtterLakeDistributor'
  // )
  // const otterLakeDistributor = await OtterLakeDistributor.deploy(
  //   POLYGON_MAINNET.PEARL_ADDRESS,
  //   POLYGON_MAINNET.CLAM_ADDRESS,
  //   POLYGON_MAINNET.sCLAM_ADDRESS,
  //   POLYGON_MAINNET.STAKING_ADDRESS,
  //   lake.address,
  //   epoch._length,
  //   epoch.endTime
  // )
  // await otterLakeDistributor.deployTransaction.wait()
  // console.log(
  //   'Pearl Lake Distributor deployed at: ' + otterLakeDistributor.address
  // )

  // await lake.setDistributor(otterLakeDistributor.address)

  await hre.run('verify:verify', {
    address: '0xbB268A4b6be1bD2E676bfd46aaEA03A100324d35',
    constructorArguments: [
      POLYGON_MAINNET.PEARL_ADDRESS,
      POLYGON_MAINNET.CLAM_ADDRESS,
      POLYGON_MAINNET.sCLAM_ADDRESS,
      POLYGON_MAINNET.STAKING_ADDRESS,
      '0xc67aBdA25D0421FE9Dc1afd64183b179A426a256',
      epoch._length,
      epoch.endTime,
    ],
  })
}

main()
  .then(() => console.log('done'))
  .catch((err) => console.error(err))
