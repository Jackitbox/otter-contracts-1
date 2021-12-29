const { ethers, timeAndMine } = require('hardhat')
const { expect } = require('chai')
const {
  formatUnits,
  formatEther,
  parseEther,
  parseUnits,
} = require('@ethersproject/units')

describe('OtterPAWBondStakeDepository', function () {
  // Large number for approval for DAI
  const largeApproval = '100000000000000000000000000000000'

  // What epoch will be first epoch
  const firstEpochNumber = '0'

  // How many seconds are in each epoch
  const epochLength = 86400 / 3

  // Ethereum 0 address, used when toggling changes in treasury
  const zeroAddress = '0x0000000000000000000000000000000000000000'

  // Initial staking index
  const initialIndex = '1737186817'

  const initialRewardRate = '5000'

  let // Used as default deployer for contracts, asks as owner of contracts.
    deployer,
    // Used as the default user for deposits and trade. Intended to be the default regular user.
    depositor,
    dao,
    clam,
    sClam,
    dai,
    treasury,
    staking,
    daiBond,
    firstEpochTime

  beforeEach(async function () {
    ;[deployer, depositor, dao] = await ethers.getSigners()

    firstEpochTime = (await deployer.provider.getBlock()).timestamp - 100

    const CLAM = await ethers.getContractFactory('OtterClamERC20V2')
    clam = await CLAM.deploy()
    await clam.setVault(deployer.address)

    const DAI = await ethers.getContractFactory('DAI')
    dai = await DAI.deploy(0)

    const StakedCLAM = await ethers.getContractFactory('StakedOtterClamERC20V2')
    sClam = await StakedCLAM.deploy()

    const Treasury = await ethers.getContractFactory('OtterTreasury')
    treasury = await Treasury.deploy(
      clam.address,
      dai.address,
      zeroAddress,
      zeroAddress,
      0
    )

    const DAIBond = await ethers.getContractFactory(
      'OtterPAWBondStakeDepository'
    )
    daiBond = await DAIBond.deploy(
      clam.address,
      sClam.address,
      dai.address,
      treasury.address,
      dao.address,
      zeroAddress
    )

    const Staking = await ethers.getContractFactory('OtterStaking')
    staking = await Staking.deploy(
      clam.address,
      sClam.address,
      epochLength,
      firstEpochNumber,
      firstEpochTime
    )
    const StakingWarmup = await ethers.getContractFactory('OtterStakingWarmup')
    const stakingWarmup = await StakingWarmup.deploy(
      staking.address,
      sClam.address
    )

    const StakingDistributor = await ethers.getContractFactory(
      'OtterStakingDistributor'
    )
    const stakingDistributor = await StakingDistributor.deploy(
      treasury.address,
      clam.address,
      epochLength,
      firstEpochTime
    )
    await stakingDistributor.addRecipient(staking.address, initialRewardRate)

    await sClam.initialize(staking.address)
    await sClam.setIndex(initialIndex)

    await staking.setContract('0', stakingDistributor.address)
    await staking.setContract('1', stakingWarmup.address)

    await clam.setVault(treasury.address)

    // queue and toggle deployer reserve depositor
    await treasury.queue('0', deployer.address)
    await treasury.toggle('0', deployer.address, zeroAddress)

    await treasury.queue('0', daiBond.address)
    await treasury.toggle('0', daiBond.address, zeroAddress)

    await treasury.queue('8', stakingDistributor.address)
    await treasury.toggle('8', stakingDistributor.address, zeroAddress)

    await daiBond.setStaking(staking.address)

    // await clam.approve(stakingHelper.address, largeApproval)
    await dai.approve(treasury.address, largeApproval)
    await dai.approve(daiBond.address, largeApproval)
    await dai.connect(depositor).approve(daiBond.address, largeApproval)

    // mint 1,000,000 DAI for testing
    await dai.mint(deployer.address, parseEther(String(100 * 10000)))
    await dai.transfer(depositor.address, parseEther('10000'))
  })

  describe('adjust', function () {
    it('should able to adjust with bcv <= 40', async function () {
      const bcv = 38
      const bondVestingLength = 10
      const minBondPrice = 400 // bond price = $4
      const maxBondPayout = 1000 // 1000 = 1% of CLAM total supply
      const daoFee = 10000 // DAO fee for bond
      const maxBondDebt = '8000000000000000'
      const initialBondDebt = 0
      await daiBond.initializeBondTerms(
        bcv,
        bondVestingLength,
        minBondPrice,
        maxBondPayout, // Max bond payout,
        daoFee,
        maxBondDebt,
        initialBondDebt
      )

      await daiBond.setAdjustment(true, 1, 50, 0)
      const adjustment = await daiBond.adjustment()
      expect(adjustment[0]).to.be.true
      expect(adjustment[1]).to.eq(1)
      expect(adjustment[2]).to.eq(50)
      expect(adjustment[3]).to.eq(0)
    })

    it('should failed to adjust with too large increment', async function () {
      const bcv = 100
      const bondVestingLength = 10
      const minBondPrice = 400 // bond price = $4
      const maxBondPayout = 1000 // 1000 = 1% of CLAM total supply
      const daoFee = 10000 // DAO fee for bond
      const maxBondDebt = '8000000000000000'
      const initialBondDebt = 0
      await daiBond.initializeBondTerms(
        bcv,
        bondVestingLength,
        minBondPrice,
        maxBondPayout, // Max bond payout,
        daoFee,
        maxBondDebt,
        initialBondDebt
      )

      await expect(daiBond.setAdjustment(true, 3, 50, 0)).to.be.revertedWith(
        'Increment too large'
      )
    })

    it('should be able to adjust with normal increment', async function () {
      const bcv = 100
      const bondVestingLength = 10
      const minBondPrice = 400 // bond price = $4
      const maxBondPayout = 1000 // 1000 = 1% of CLAM total supply
      const daoFee = 10000 // DAO fee for bond
      const maxBondDebt = '8000000000000000'
      const initialBondDebt = 0
      await daiBond.initializeBondTerms(
        bcv,
        bondVestingLength,
        minBondPrice,
        maxBondPayout, // Max bond payout,
        daoFee,
        maxBondDebt,
        initialBondDebt
      )

      await daiBond.setAdjustment(false, 2, 80, 3)
      const adjustment = await daiBond.adjustment()
      expect(adjustment[0]).to.be.false
      expect(adjustment[1]).to.eq(2)
      expect(adjustment[2]).to.eq(80)
      expect(adjustment[3]).to.eq(3)
    })
  })

  describe('deposit', function () {
    it('failed to redeem not fully vested bond', async function () {
      await treasury.deposit(
        parseEther('10000'),
        dai.address,
        parseUnits('7500', 9)
      )

      const bcv = 300
      const bondVestingLength = 10
      const minBondPrice = 400 // bond price = $4
      const maxBondPayout = 1000 // 1000 = 1% of CLAM total supply
      const daoFee = 10000 // DAO fee for bond
      const maxBondDebt = '8000000000000000'
      const initialBondDebt = 0
      await daiBond.initializeBondTerms(
        bcv,
        bondVestingLength,
        minBondPrice,
        maxBondPayout, // Max bond payout,
        daoFee,
        maxBondDebt,
        initialBondDebt
      )

      let bondPrice = await daiBond.bondPriceInUSD(zeroAddress)
      console.log('bond price: ' + formatEther(bondPrice))

      await daiBond.deposit(
        parseEther('100'),
        largeApproval,
        deployer.address,
        zeroAddress,
        0
      )

      const prevDAOReserve = await clam.balanceOf(dao.address)
      expect(prevDAOReserve).to.eq(parseUnits('25', 9))
      console.log('dao balance: ' + formatUnits(prevDAOReserve, 9))

      await timeAndMine.setTimeIncrease(2)

      await expect(daiBond.redeem(deployer.address)).to.be.revertedWith(
        'not fully vested'
      )
    })

    it('should redeem sCLAM when vested fully', async function () {
      await treasury.deposit(
        parseEther('10000'),
        dai.address,
        parseUnits('7500', 9)
      )

      const bcv = 300
      const bondVestingLength = 15
      const minBondPrice = 400 // bond price = $4
      const maxBondPayout = 10000 // 1000 = 1% of CLAM total supply
      const daoFee = 10000 // DAO fee for bond
      const maxBondDebt = '8000000000000000'
      const initialBondDebt = 0
      await daiBond.initializeBondTerms(
        bcv,
        bondVestingLength,
        minBondPrice,
        maxBondPayout, // Max bond payout,
        daoFee,
        maxBondDebt,
        initialBondDebt
      )

      expect(await daiBond.bondPriceInUSD(zeroAddress)).to.eq(parseEther('4'))

      await expect(() =>
        daiBond.deposit(
          parseEther('1000'),
          largeApproval,
          deployer.address,
          zeroAddress,
          0
        )
      ).to.changeTokenBalance(clam, dao, parseUnits('250', 9))

      await timeAndMine.setTimeIncrease(432001)
      await staking.rebase()

      await expect(() =>
        daiBond.redeem(deployer.address)
      ).to.changeTokenBalance(sClam, deployer, parseUnits('265', 9))
    })

    it('should deposit twice and redeem sCLAM when vested fully', async function () {
      await treasury.deposit(
        parseEther('100000'),
        dai.address,
        parseUnits('75000', 9)
      )

      const bcv = 300
      const bondVestingLength = 15
      const minBondPrice = 5000 // bond price = $50
      const maxBondPayout = 10000 // 1000 = 1% of CLAM total supply
      const daoFee = 10000 // DAO fee for bond
      const maxBondDebt = '8000000000000000'
      const initialBondDebt = 0
      await daiBond.initializeBondTerms(
        bcv,
        bondVestingLength,
        minBondPrice,
        maxBondPayout, // Max bond payout,
        daoFee,
        maxBondDebt,
        initialBondDebt
      )

      expect(await daiBond.bondPriceInUSD(zeroAddress)).to.eq(parseEther('50'))

      await expect(() =>
        daiBond.deposit(
          parseEther('50'),
          largeApproval,
          deployer.address,
          zeroAddress,
          0
        )
      ).to.changeTokenBalance(clam, dao, parseUnits('1', 9))
      await expect(() =>
        daiBond
          .connect(depositor)
          .deposit(
            parseEther('500'),
            largeApproval,
            depositor.address,
            zeroAddress,
            0
          )
      ).to.changeTokenBalance(clam, dao, parseUnits('10', 9))

      await timeAndMine.setTimeIncrease(86400)
      await staking.rebase()

      await expect(() =>
        daiBond.deposit(
          parseEther('3000'),
          largeApproval,
          deployer.address,
          zeroAddress,
          0
        )
      ).to.changeTokenBalance(clam, dao, parseUnits('60', 9))

      await timeAndMine.setTimeIncrease(432001)
      await staking.rebase()

      await expect(() =>
        daiBond.redeem(deployer.address)
      ).to.changeTokenBalance(sClam, deployer, '116861328128')

      await expect(() =>
        daiBond.redeem(depositor.address)
      ).to.changeTokenBalance(sClam, depositor, '331847447121')
    })

    it('should able to buy with paw discount', async function () {
      const PAW = await ethers.getContractFactory('OtterPAW')
      const diamondHand = await PAW.deploy(
        'diamond hand otter',
        'DHO',
        'ipfs://metadata'
      )

      await treasury.deposit(
        parseEther('10000'),
        dai.address,
        parseUnits('7500', 9)
      )

      const bcv = 300
      const bondVestingLength = 10
      const minBondPrice = 400 // bond price = $4
      const maxBondPayout = 1000 // 1000 = 1% of CLAM total supply
      const daoFee = 10000 // DAO fee for bond
      const maxBondDebt = '8000000000000000'
      const initialBondDebt = 0
      await daiBond.initializeBondTerms(
        bcv,
        bondVestingLength,
        minBondPrice,
        maxBondPayout, // Max bond payout,
        daoFee,
        maxBondDebt,
        initialBondDebt
      )
      await daiBond.setPAWDiscount(diamondHand.address, 1000) // 10% discount

      await diamondHand.setWhitelist([deployer.address])
      await diamondHand.claim()
      const tokenID = diamondHand.claimed(deployer.address)

      expect(await daiBond.bondPriceInUSD(zeroAddress)).to.eq(parseEther('4.0'))
      expect(await daiBond.bondPriceInUSD(diamondHand.address)).to.eq(
        parseEther('3.6')
      )

      await diamondHand.approve(daiBond.address, tokenID)
      await daiBond.deposit(
        parseEther('90'),
        largeApproval,
        deployer.address,
        diamondHand.address,
        tokenID
      )
      expect(await diamondHand.ownerOf(tokenID)).to.eq(daiBond.address)

      const di0 = await daiBond.discountInfo(deployer.address, 0)
      expect(di0.paw).to.eq(diamondHand.address)
      expect(di0.tokenID).to.eq(1)
      expect(di0.discount).to.eq(1000)

      await timeAndMine.increaseTime(5)
      await expect(daiBond.redeem(deployer.address)).to.be.revertedWith(
        'not fully vested'
      )

      await timeAndMine.increaseTime(5)
      await expect(() =>
        daiBond.redeem(deployer.address)
      ).to.be.changeTokenBalance(sClam, deployer, parseUnits('25', 9))
      expect(await diamondHand.ownerOf(tokenID)).to.eq(deployer.address)
    })

    it('should able to buy twice with paw discount', async function () {
      const PAW = await ethers.getContractFactory('OtterPAW')
      const diamondHand = await PAW.deploy(
        'diamond hand otter',
        'DIAMOND',
        'ipfs://metadata'
      )
      const stoneHand = await PAW.deploy(
        'stone hand otter',
        'STONE',
        'ipfs://metadata'
      )

      await treasury.deposit(
        parseEther('10000'),
        dai.address,
        parseUnits('7500', 9)
      )

      const bcv = 300
      const bondVestingLength = 10
      const minBondPrice = 400 // bond price = $4
      const maxBondPayout = 1000 // 1000 = 1% of CLAM total supply
      const daoFee = 10000 // DAO fee for bond
      const maxBondDebt = '8000000000000000'
      const initialBondDebt = 0
      await daiBond.initializeBondTerms(
        bcv,
        bondVestingLength,
        minBondPrice,
        maxBondPayout, // Max bond payout,
        daoFee,
        maxBondDebt,
        initialBondDebt
      )
      await daiBond.setPAWDiscount(diamondHand.address, 1000) // 10% discount
      await daiBond.setPAWDiscount(stoneHand.address, 500) // 5% discount

      await diamondHand.setWhitelist([deployer.address])
      await diamondHand.claim()
      await stoneHand.setWhitelist([deployer.address])
      await stoneHand.claim()
      const tokenIDofDiamondHand = await diamondHand.claimed(deployer.address)
      const tokenIDofStoneHand = await stoneHand.claimed(deployer.address)

      expect(await daiBond.bondPriceInUSD(zeroAddress)).to.eq(parseEther('4.0'))
      expect(await daiBond.bondPriceInUSD(diamondHand.address)).to.eq(
        parseEther('3.6')
      )
      expect(await daiBond.bondPriceInUSD(stoneHand.address)).to.eq(
        parseEther('3.8')
      )

      await diamondHand.approve(daiBond.address, tokenIDofDiamondHand)
      await daiBond.deposit(
        parseEther('90'),
        largeApproval,
        deployer.address,
        diamondHand.address,
        tokenIDofDiamondHand
      )
      expect(await diamondHand.ownerOf(tokenIDofDiamondHand)).to.eq(
        daiBond.address
      )

      await stoneHand.approve(daiBond.address, tokenIDofStoneHand)
      await daiBond.deposit(
        parseEther('90'),
        largeApproval,
        deployer.address,
        stoneHand.address,
        tokenIDofStoneHand
      )
      expect(await stoneHand.ownerOf(tokenIDofStoneHand)).to.eq(daiBond.address)

      const di0 = await daiBond.discountInfo(deployer.address, 0)
      expect(di0.paw).to.eq(diamondHand.address)
      expect(di0.tokenID).to.eq(tokenIDofDiamondHand)
      expect(di0.discount).to.eq(1000)

      const di1 = await daiBond.discountInfo(deployer.address, 1)
      expect(di1.paw).to.eq(stoneHand.address)
      expect(di1.tokenID).to.eq(tokenIDofStoneHand)
      expect(di1.discount).to.eq(500)

      await timeAndMine.increaseTime(5)
      await expect(daiBond.redeem(deployer.address)).to.be.revertedWith(
        'not fully vested'
      )

      await timeAndMine.increaseTime(5)
      await expect(() =>
        daiBond.redeem(deployer.address)
      ).to.be.changeTokenBalance(sClam, deployer, '35055865921')
      expect(await diamondHand.ownerOf(tokenIDofDiamondHand)).to.eq(
        deployer.address
      )
      expect(await stoneHand.ownerOf(tokenIDofStoneHand)).to.eq(
        deployer.address
      )
    })
  })
})
