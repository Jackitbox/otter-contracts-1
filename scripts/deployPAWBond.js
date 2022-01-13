const hre = require('hardhat')
const { ethers } = hre

let addresses = {
  sCLAM_ADDRESS: '0xAAc144Dc08cE39Ed92182dd85ded60E5000C9e67',
  CLAM_ADDRESS: '0xC250e9987A032ACAC293d838726C511E6E1C029d',
  TREASURY_ADDRESS: '0x8ce47D56EAa1299d3e06FF3E04637449fFb01C9C',
  CLAM_BONDING_CALC_ADDRESS: '0x651125e097D7e691f3Df5F9e5224f0181E3A4a0E',
  STAKING_ADDRESS: '0xC8B0243F350AA5F8B979b228fAe522DAFC61221a',
  RESERVES: {
    MAI: '0xa3Fa99A148fA48D14Ed51d610c367C61876997F1',
    MAI_CLAM: '0x1581802317f32A2665005109444233ca6E3e2D68',
    FRAX: '0x45c32fa6df82ead1e2ef74d17b76547eddfaff89',
    FRAX_CLAM: '0x167F06eb4242fe3e5436dB7Ffa06bdE3c18Fc999',
  },
  BONDS: {
    MAI: '0x603A74Fd527b85E0A1e205517c1f24aC71f5C263',
    MAI_CLAM: '0x706587BD39322A6a78ddD5491cDbb783F8FD983E',
  },
  NFTS: {
    SAFE_HAND_28DAY_NOTE: '0x03883Df947Af7C0BE2aCe9163489fa85A9947008',
    SAFE_HAND_90DAY_NOTE: '0x5a30229BFbe5A22343aE67D4C077c101768Fd757',
    SAFE_HAND_180DAY_NOTE: '0x931f0857130bcd221D30C06d80aD98affe3Aa526',
    FURRY_HAND_28DAY_NOTE: '0x7C1a1C1e540E6c6F59F1748C3C2Edf39f8Cc06ee',
    FURRY_HAND_OTTER: '0x2A6c8531F8a125098b2f2beeaBb2705FE348474A',
    STONE_HAND_90DAY_NOTE: '0xBe982E164402970da7C72083FB8D5FcdeF751DfA',
    STONE_HAND_OTTER: '0xE93740Df02471aD89B4E1DF7C2aC0BC575519BC5',
    DIAMOND_HAND_180DAY_NOTE: '0x831725bD8c8d2B9e75b872649f146F88e8A92b36',
    DIAMOND_HAND_OTTER: '0x812ae364659B3c7C47322e8Acfbde2eca2c4c439',
  },
  DAO_ADDRESS: '0x929a27c46041196e1a49c7b459d63ec9a20cd879',
}

const zeroAddress = '0x0000000000000000000000000000000000000000'

const reserveAddr = addresses.RESERVES.MAI_CLAM
const isLPBond = true

async function main() {
  const Staking = await ethers.getContractFactory('OtterStaking')
  const staking = Staking.attach(addresses.STAKING_ADDRESS)
  const epoch = await staking.epoch()
  const Bond = await ethers.getContractFactory('OtterPAWBondStakeDepository')
  // const bond = OtterBondStakeDepository.attach(
  //   '0xda0d7c3d751d00a1ec1c495eF7Cf3db1a202B0B9'
  // )

  const calcAddr = isLPBond ? addresses.CLAM_BONDING_CALC_ADDRESS : zeroAddress
  const bond = await Bond.deploy(
    addresses.CLAM_ADDRESS,
    addresses.sCLAM_ADDRESS,
    reserveAddr,
    addresses.TREASURY_ADDRESS,
    addresses.DAO_ADDRESS,
    calcAddr,
    epoch._length,
    epoch.number,
    epoch.endTime
  )
  console.log('Deployed bond:', bond.address)
  await bond.deployTransaction.wait()
  await (await bond.setStaking(addresses.STAKING_ADDRESS)).wait()

  const discounts = [
    {
      name: 'SAFE_HAND_28DAY_NOTE',
      address: addresses.NFTS.SAFE_HAND_28DAY_NOTE,
      discount: 50,
    },
    {
      name: 'SAFE_HAND_90DAY_NOTE',
      address: addresses.NFTS.SAFE_HAND_90DAY_NOTE,
      discount: 100,
    },
    {
      name: 'SAFE_HAND_180DAY_NOTE',
      address: addresses.NFTS.SAFE_HAND_180DAY_NOTE,
      discount: 200,
    },
    {
      name: 'FURRY_HAND_OTTER',
      address: addresses.NFTS.FURRY_HAND_OTTER,
      discount: 50,
    },
    {
      name: 'FURRY_HAND_28DAY_NOTE',
      address: addresses.NFTS.FURRY_HAND_28DAY_NOTE,
      discount: 50,
    },
    {
      name: 'STONE_HAND_OTTER',
      address: addresses.NFTS.STONE_HAND_OTTER,
      discount: 100,
    },
    {
      name: 'STONE_HAND_90DAY_NOTE',
      address: addresses.NFTS.STONE_HAND_90DAY_NOTE,
      discount: 100,
    },
    {
      name: 'DIAMOND_HAND_OTTER',
      address: addresses.NFTS.DIAMOND_HAND_OTTER,
      discount: 200,
    },
    {
      name: 'DIAMOND_HAND_180DAY_NOTE',
      address: addresses.NFTS.DIAMOND_HAND_180DAY_NOTE,
      discount: 200,
    },
  ]

  const expiry = Math.floor(Date.now() / 1000) + 86400 * 90 // expires after 90 days
  for (const { name, address, discount } of discounts) {
    await (await bond.addDiscountTerms(address, discount, expiry)).wait()
    console.log(`discount added: ${name} ${address} ${discount} ${expiry}`)
  }

  // await (await treasury.queue('2', reserveAddr)).wait()

  // await treasury.toggle('0', daiBond.address, zeroAddress)
  // await treasury.toggle('2', reserveAddr, zeroAddress)

  // const tokenMinPrice = '5000'
  // await bond.initializeBondTerms(
  //   '100',
  //   '432000',
  //   '0',
  //   '50',
  //   '10000',
  //   '8000000000000000',
  //   '5170963135351'
  // )

  console.log(
    `bond initialized, please verify: yarn hardhat verify ${bond.address} ${addresses.CLAM_ADDRESS} ${addresses.sCLAM_ADDRESS} ${reserveAddr} ${addresses.TREASURY_ADDRESS} ${addresses.DAO_ADDRESS} ${calcAddr}`
  )
}

main()
  .then(() => console.log('done'))
  .catch((err) => console.error(err))
