const { ethers, timeAndMine } = require('hardhat')
const { expect } = require('chai')
const { BigNumber } = require('@ethersproject/bignumber')
const { parseUnits, parseEther } = require('ethers/lib/utils')

describe('Pearl Vault', function () {
  // Large number for approval for DAI
  const largeApproval = '100000000000000000000000000000000'

  // What epoch will be first epoch
  const firstEpochNumber = '1'

  // How many seconds are in each epoch
  const epochLength = 86400 / 3

  // Initial reward rate for epoch
  const initialRewardRate = '3000'

  // Ethereum 0 address, used when toggling changes in treasury
  const zeroAddress = '0x0000000000000000000000000000000000000000'

  // Initial staking index
  const initialIndex = '1000000000'

  let deployer, vault, pearl, user1, user2

  beforeEach(async function () {
    ;[deployer, user1, user2] = await ethers.getSigners()

    const DAI = await ethers.getContractFactory('DAI')
    pearl = await DAI.deploy(0)

    const Vault = await ethers.getContractFactory('PearlVault')
    vault = await Vault.deploy(deployer.address, pearl.address, pool.address)

    await pool.setVault(vault.address)

    // mint 1,000,000 DAI for testing
    await pearl.mint(deployer.address, parseEther(String(100 * 10000)))
    await pearl.transfer(user1.address, parseEther(String(1000)))
    await pearl.transfer(user2.address, parseEther(String(100)))

    // approve
    await pearl.connect(user1).approve(vault.address, largeApproval)
    await pearl.connect(user2).approve(vault.address, largeApproval)
  })

  describe('terms', function () {
    let note

    beforeEach(async function () {
      const Note = await ethers.getContractFactory('PearlNote')
      note = await Note.deploy(
        pearl.address,
        'Note',
        'NOTE',
        'https://example.com/diamond'
      )
    })

    it('failed to add invalid note address', async function () {
      await expect(
        vault.addTerm(deployer.address, 10, 10, 100)
      ).to.be.revertedWith('')
    })

    it('should add/disable term success', async function () {
      await vault.addTerm(note.address, 10, 35, 100)

      let term = await vault.terms(0)
      expect(term.note).to.eq(note.address)
      expect(term.minLockAmount).to.eq(10)
      expect(term.lockPeriod).to.eq(35)
      expect(term.multiplier).to.eq(100)
      expect(term.enabled).to.be.true

      await vault.disableTerm(0)
      term = await vault.terms(0)
      expect(term.enabled).to.be.false
    })
  })

  describe('lock & withdraw one note', function () {
    const minLockAmount = 0
    const lockPeriod = 100
    const multiplier = 100
    let now, note

    beforeEach(async function () {
      const Note = await ethers.getContractFactory('PearlNote')
      note = await Note.deploy(
        pearl.address,
        'Note',
        'NOTE',
        'https://example.com/diamond'
      )
      await note.setVault(vault.address)
      await vault.addTerm(note.address, minLockAmount, lockPeriod, multiplier)

      now = now || Math.floor(Date.now() / 1000)
    })

    it('should get reward for nft owner', async function () {
      const term = 0

      await vault.setRewardsDuration(10)

      await expect(() =>
        vault.connect(user1).lock(term, 100)
      ).to.changeTokenBalance(pearl, user1, -100)

      expect(await note.balanceOf(user1.address)).to.eq(1)

      const noteId = await note.tokenOfOwnerByIndex(user1.address, 0)
      const reward = 20
      await pearl.transfer(pool.address, reward)

      await timeAndMine.setTimeNextBlock(now + 100)
      await vault.notifyRewardAmount(reward)

      expect(await vault.rewardRate()).to.eq(2)

      await timeAndMine.setTimeNextBlock(now + 105)
      await expect(() =>
        vault.connect(user1).claimReward(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 10)

      await timeAndMine.setTimeNextBlock(now + 150)
      await expect(() =>
        vault.connect(user1).exit(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 110)

      now = now + 200
    })

    it('should forbid exit if the nft is not expired', async function () {
      const term = 0

      await vault.setRewardsDuration(10)

      await expect(() =>
        vault.connect(user1).lock(term, 100)
      ).to.changeTokenBalance(pearl, user1, -100)

      expect(await note.balanceOf(user1.address)).to.eq(1)

      const reward = 20
      await pearl.transfer(pool.address, reward)

      await timeAndMine.setTimeNextBlock(now + 10)
      await vault.notifyRewardAmount(reward)

      expect(await vault.rewardRate()).to.eq(2)

      await timeAndMine.setTimeNextBlock(now + 15)

      const noteId = await note.tokenOfOwnerByIndex(user1.address, 0)
      await expect(() =>
        vault.connect(user1).claimReward(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 10)

      await expect(vault.connect(user1).exit(term, noteId)).to.be.revertedWith(
        'PearlNote: the note is not expired'
      )

      now += 20
    })

    it('should split rewards to 2 nfts', async function () {
      const term = 0

      await vault.setRewardsDuration(100)

      // user 1 lock
      await vault.connect(user1).lock(term, 100)

      const reward = 200
      await pearl.transfer(pool.address, reward)
      await timeAndMine.setTimeNextBlock(now + 100)
      await vault.notifyRewardAmount(reward)

      expect(await vault.rewardRate()).to.eq(2)

      const user1Note = await note.tokenOfOwnerByIndex(user1.address, 0)
      await timeAndMine.setTimeNextBlock(now + 105)
      await expect(() =>
        vault.connect(user1).claimReward(term, user1Note)
      ).to.changeTokenBalance(pearl, user1, 10)

      // user 2 lock
      await timeAndMine.setTimeNextBlock(now + 110)
      await vault.connect(user2).lock(term, 300)
      const user2Note = await note.tokenOfOwnerByIndex(user2.address, 0)

      await timeAndMine.setTime(now + 300)

      await expect(() =>
        vault.connect(user1).exit(term, user1Note)
      ).to.changeTokenBalance(pearl, user1, 155)

      await expect(() =>
        vault.connect(user2).exit(term, user2Note)
      ).to.changeTokenBalance(pearl, user2, 435)

      now += 300
    })
  })

  describe('lock & withdraw two note', function () {
    let now,
      note1,
      note2,
      note1MinAmount = 1,
      note1MinLockPeriod = 100,
      note1Multiplier = 100,
      note2MinAmount = 100,
      note2MinLockPeriod = 300,
      note2Multiplier = 200

    beforeEach(async function () {
      const Note = await ethers.getContractFactory('PearlNote')

      note1 = await Note.deploy(
        pearl.address,
        'Note1',
        'NOTE1',
        'https://example.com/safe'
      )
      await note1.setVault(vault.address)
      await vault.addTerm(
        note1.address,
        note1MinAmount,
        note1MinLockPeriod,
        note1Multiplier
      )

      note2 = await Note.deploy(
        pearl.address,
        'Note2',
        'NOTE2',
        'https://example.com/diamond'
      )
      await note2.setVault(vault.address)
      await vault.addTerm(
        note2.address,
        note2MinAmount,
        note2MinLockPeriod,
        note2Multiplier
      )

      now = now || Math.floor(Date.now() / 1000)
    })

    it('should split rewards to 2 notes', async function () {
      await vault.setRewardsDuration(50)

      // user1 lock to note1
      await timeAndMine.setTimeNextBlock(now + 100)
      await vault.connect(user1).lock(0, 100)
      const user1Note = await note1.tokenOfOwnerByIndex(user1.address, 0)
      expect(await vault.boostPointOf(0, user1Note)).to.eq(100)
      // user2 lock to note2
      await timeAndMine.setTimeNextBlock(now + 101)
      await vault.connect(user2).lock(1, 100)
      const user2Note = await note2.tokenOfOwnerByIndex(user2.address, 0)
      expect(await vault.boostPointOf(1, user2Note)).to.eq(200)

      const reward = 300
      await pearl.transfer(pool.address, reward)
      await timeAndMine.setTimeNextBlock(now + 110)
      await vault.notifyRewardAmount(reward)

      await timeAndMine.setTime(now + 160)

      expect(await vault.earned(0, user1Note)).to.eq('100')
      expect(await vault.earned(1, user2Note)).to.eq('200')

      await timeAndMine.setTime(now + 500)

      await expect(() =>
        vault.connect(user1).exit(0, user1Note)
      ).to.changeTokenBalance(pearl, user1, 200)

      await expect(() =>
        vault.connect(user2).exit(1, user2Note)
      ).to.changeTokenBalance(pearl, user2, 300)

      now += 600
    })

    it('should stop reward for note expired', async function () {
      await vault.setRewardsDuration(300)

      // user1 lock to note1
      await timeAndMine.setTimeNextBlock(now + 100)
      await vault.connect(user1).lock(0, 100)
      const user1Note = await note1.tokenOfOwnerByIndex(user1.address, 0)
      expect(await vault.boostPointOf(0, user1Note)).to.eq(100)
      // user2 lock to note2
      await timeAndMine.setTimeNextBlock(now + 101)
      await vault.connect(user2).lock(1, 100)
      const user2Note = await note2.tokenOfOwnerByIndex(user2.address, 0)
      expect(await vault.boostPointOf(1, user2Note)).to.eq(200)

      const reward = 900
      await pearl.transfer(pool.address, reward)
      await timeAndMine.setTimeNextBlock(now + 110)
      await vault.notifyRewardAmount(reward)

      await timeAndMine.setTime(now + 500)

      await expect(() =>
        vault.connect(user1).exit(0, user1Note)
      ).to.changeTokenBalance(pearl, user1, 200)

      await expect(() =>
        vault.connect(user2).exit(1, user2Note)
      ).to.changeTokenBalance(pearl, user2, 300)

      now += 501
    })
  })
})
