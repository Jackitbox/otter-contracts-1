const { ethers, timeAndMine } = require('hardhat')
const { expect } = require('chai')
const { parseEther, parseUnits } = require('ethers/lib/utils')

describe('OtterLakeDistributor', function () {
  // Large number for approval for DAI
  const largeApproval = '100000000000000000000000000000000'

  // What epoch will be first epoch
  const firstEpochNumber = '1'

  // How many seconds are in each epoch
  const epochLength = 200

  // Ethereum 0 address, used when toggling changes in treasury
  const zeroAddress = '0x0000000000000000000000000000000000000000'

  // Initial staking index
  const initialIndex = '1000000000'

  let // Used as default deployer for contracts, asks as owner of contracts.
    deployer,
    // Used as the default user for deposits and trade. Intended to be the default regular user.
    clam,
    sClam,
    pearl,
    dai,
    treasury,
    stakingDistributor,
    staking,
    otterLakeDistributor,
    firstEpochTime

  beforeEach(async function () {
    deployer = await ethers.getSigner()

    firstEpochTime = (await deployer.provider.getBlock()).timestamp - 100

    const DAI = await ethers.getContractFactory('DAI')
    dai = await DAI.deploy(0)

    const CLAM = await ethers.getContractFactory('OtterClamERC20')
    clam = await CLAM.deploy()
    await clam.setVault(deployer.address)

    const StakedCLAM = await ethers.getContractFactory('StakedOtterClamERC20')
    sClam = await StakedCLAM.deploy()

    const PEARL = await ethers.getContractFactory('OtterPearlERC20')
    pearl = await PEARL.deploy(sClam.address)

    const Treasury = await ethers.getContractFactory('OtterTreasury')
    treasury = await Treasury.deploy(
      clam.address,
      dai.address,
      zeroAddress,
      zeroAddress,
      0
    )

    const StakingDistributor = await ethers.getContractFactory(
      'OtterStakingDistributor'
    )
    stakingDistributor = await StakingDistributor.deploy(
      treasury.address,
      clam.address,
      epochLength,
      firstEpochTime
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

    const OtterLakeDistributor = await ethers.getContractFactory(
      'OtterLakeDistributor'
    )
    otterLakeDistributor = await OtterLakeDistributor.deploy(
      pearl.address,
      clam.address,
      sClam.address,
      staking.address,
      deployer.address,
      epochLength,
      firstEpochTime
    )

    await sClam.initialize(staking.address)
    await sClam.setIndex(initialIndex)

    // await staking.setContract('0', stakingDistributor.address)
    await staking.setContract('1', stakingWarmup.address)

    // await stakingDistributor.addRecipient(staking.address, initialRewardRate)

    await clam.setVault(treasury.address)

    // queue and toggle reward manager
    await treasury.queue('8', stakingDistributor.address)
    await treasury.toggle('8', stakingDistributor.address, zeroAddress)

    // queue and toggle deployer reserve depositor
    await treasury.queue('0', deployer.address)
    await treasury.toggle('0', deployer.address, zeroAddress)

    // await clam.approve(stakingHelper.address, largeApproval)
    await dai.approve(treasury.address, largeApproval)

    // mint 1,000,000 DAI for testing
    await dai.mint(deployer.address, parseEther(String(100 * 10000)))
  })

  describe('distribute', function () {
    it('distribute pearl to vault', async function () {
      await expect(() =>
        treasury.deposit(parseEther('1000'), dai.address, parseUnits('750', 9))
      ).to.changeTokenBalance(clam, deployer, parseUnits('250', 9))

      await otterLakeDistributor.setRate(200000)
      await clam.transfer(otterLakeDistributor.address, parseUnits('100', 9))

      await expect(() => otterLakeDistributor.distribute()).changeTokenBalance(
        pearl,
        deployer,
        parseEther('20')
      )

      // distribute again, epoch not end
      await expect(() => otterLakeDistributor.distribute()).changeTokenBalance(
        pearl,
        deployer,
        parseEther('0')
      )

      timeAndMine.setTimeNextBlock(firstEpochTime + 200)
      await expect(() => otterLakeDistributor.distribute()).changeTokenBalance(
        pearl,
        deployer,
        parseEther('16')
      )
    })

    it('should distribute pearl to vault from staking distributor', async function () {
      await expect(() =>
        treasury.deposit(parseEther('1000'), dai.address, parseUnits('750', 9))
      ).to.changeTokenBalance(clam, deployer, parseUnits('250', 9))

      await otterLakeDistributor.setDistributor(stakingDistributor.address)
      await stakingDistributor.addRecipient(otterLakeDistributor.address, 5000)

      expect(
        await stakingDistributor.nextRewardFor(otterLakeDistributor.address)
      ).to.eq(parseUnits('1.25', 9))
      await otterLakeDistributor.setRate(1000000)

      await expect(() => otterLakeDistributor.distribute()).changeTokenBalance(
        pearl,
        deployer,
        parseEther('1.25')
      )
      expect(await clam.balanceOf(otterLakeDistributor.address)).to.eq(0)
    })
  })
})
