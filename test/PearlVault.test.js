const { ethers, timeAndMine } = require('hardhat')
const { expect } = require('chai')
const { BigNumber } = require('@ethersproject/bignumber')
const { parseUnits, parseEther } = require('ethers/lib/utils')

describe.only('Pearl Vault', function () {
  // Large number for approval for DAI
  const largeApproval = '100000000000000000000000000000000'

  // What epoch will be first epoch
  const firstEpochNumber = '1'

  // How many seconds are in each epoch
  const epochLength = 100

  // Ethereum 0 address, used when toggling changes in treasury
  const zeroAddress = '0x0000000000000000000000000000000000000000'

  let deployer, vault, mockDistributor, pearl, user1, user2, now

  beforeEach(async function () {
    ;[deployer, user1, user2] = await ethers.getSigners()

    now = now || Math.floor(Date.now() / 1000)
    const firstEpochEndTime = now - 10

    const DAI = await ethers.getContractFactory('DAI')
    pearl = await DAI.deploy(0)

    const Vault = await ethers.getContractFactory('PearlVault')
    vault = await Vault.deploy(
      pearl.address,
      epochLength,
      firstEpochNumber,
      firstEpochEndTime
    )

    const MockDistributor = await ethers.getContractFactory('MockDistributor')
    mockDistributor = await MockDistributor.deploy(pearl.address, vault.address)

    await vault.setDistributor(mockDistributor.address)

    // mint 1,000,000 DAI for testing
    await pearl.mint(deployer.address, parseEther(String(100 * 10000)))
    await pearl.transfer(user1.address, parseEther(String(1000)))
    await pearl.transfer(user2.address, parseEther(String(100)))

    // approve
    await pearl.connect(user1).approve(vault.address, largeApproval)
    await pearl.connect(user2).approve(vault.address, largeApproval)
  })

  async function nextEpoch(epoch = 1, harvest = true) {
    for (let i = 0; i < epoch; i++) {
      await timeAndMine.setTimeNextBlock((now += 100))
      if (harvest) {
        await vault.harvest()
      }
    }
  }

  describe('terms', function () {
    let note

    beforeEach(async function () {
      const Note = await ethers.getContractFactory('PearlNote')
      note = await Note.deploy(
        'Note',
        'NOTE',
        'https://example.com/diamond',
        pearl.address,
        vault.address
      )
    })

    it('failed to add invalid note address', async function () {
      await expect(
        vault.addTerm(deployer.address, 10, 10, 100)
      ).to.be.revertedWith('')
    })

    it('failed to add duplicate note address', async function () {
      await vault.addTerm(note.address, 10, 35, 100)
      await expect(vault.addTerm(note.address, 10, 35, 100)).to.be.revertedWith(
        'dupl'
      )
    })

    it('should add/disable term success', async function () {
      await vault.addTerm(note.address, 10, 35, 100)

      let term = await vault.terms(note.address)
      expect(term.note).to.eq(note.address)
      expect(term.minLockAmount).to.eq(10)
      expect(term.lockPeriod).to.eq(35)
      expect(term.multiplier).to.eq(100)
      expect(term.enabled).to.be.true

      await vault.disableTerm(note.address)
      term = await vault.terms(note.address)
      expect(term.enabled).to.be.false
    })
  })

  describe('lock & withdraw one note', function () {
    const minLockAmount = 0
    const lockPeriod = 2
    const multiplier = 100
    let note

    beforeEach(async function () {
      const Note = await ethers.getContractFactory('PearlNote')
      note = await Note.deploy(
        'Note',
        'NOTE',
        'https://example.com/diamond',
        pearl.address,
        vault.address
      )
      await vault.addTerm(note.address, minLockAmount, lockPeriod, multiplier)
    })

    it('should get reward', async function () {
      const term = note.address
      const reward = 10
      await pearl.transfer(mockDistributor.address, reward)

      await expect(() =>
        vault.connect(user1).lock(term, 100)
      ).to.changeTokenBalance(pearl, user1, -100)

      expect(await note.balanceOf(user1.address)).to.eq(1)

      const noteId = await note.tokenOfOwnerByIndex(user1.address, 0)

      await nextEpoch(2, false)

      await expect(() =>
        vault.connect(user1).claimReward(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 10)

      await expect(() =>
        vault.connect(user1).exit(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 100)

      expect(await pearl.balanceOf(vault.address)).to.eq(0)
    })

    it('should failed to reward if not note owner', async function () {
      const term = note.address
      const reward = 10
      await pearl.transfer(mockDistributor.address, reward)

      await expect(() =>
        vault.connect(user1).lock(term, 100)
      ).to.changeTokenBalance(pearl, user1, -100)

      expect(await note.balanceOf(user1.address)).to.eq(1)

      const noteId = await note.tokenOfOwnerByIndex(user1.address, 0)

      await nextEpoch(2)

      await expect(
        vault.connect(user2).claimReward(term, noteId)
      ).to.be.revertedWith('PearlVault: msg.sender is not the note owner')
    })

    it('should exit with second reward', async function () {
      const term = note.address
      const reward = 10
      await pearl.transfer(mockDistributor.address, reward)
      await vault.harvest()

      await expect(() =>
        vault.connect(user1).lock(term, 100)
      ).to.changeTokenBalance(pearl, user1, -100)

      expect(await note.balanceOf(user1.address)).to.eq(1)
      const noteId = await note.tokenOfOwnerByIndex(user1.address, 0)

      await nextEpoch(2, false)

      await pearl.transfer(mockDistributor.address, 20)

      await expect(() =>
        vault.connect(user1).claimReward(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 10)

      await expect(() =>
        vault.connect(user1).exit(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 120)

      expect(await pearl.balanceOf(vault.address)).to.eq(0)
    })

    it('should get all reward', async function () {
      const term = note.address
      const reward = 10
      await pearl.transfer(mockDistributor.address, reward)
      await vault.harvest()

      await expect(() =>
        vault.connect(user1).lock(term, 100)
      ).to.changeTokenBalance(pearl, user1, -100)

      expect(await note.balanceOf(user1.address)).to.eq(1)
      const noteId = await note.tokenOfOwnerByIndex(user1.address, 0)

      await pearl.transfer(mockDistributor.address, 20)
      await nextEpoch(2)

      await expect(() =>
        vault.connect(user1).claimReward(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 30)

      await expect(() =>
        vault.connect(user1).exit(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 100)

      expect(await pearl.balanceOf(vault.address)).to.eq(0)
    })

    it('should get reward after claim', async function () {
      const Note = await ethers.getContractFactory('PearlNote')
      const note2 = await Note.deploy(
        'Note',
        'NOTE',
        'https://example.com/diamond',
        pearl.address,
        vault.address
      )
      await vault.addTerm(note2.address, minLockAmount, 3, multiplier)

      const term = note2.address
      const reward = 10
      await pearl.transfer(mockDistributor.address, reward)
      await vault.harvest()

      await expect(() =>
        vault.connect(user1).lock(term, 100)
      ).to.changeTokenBalance(pearl, user1, -100)

      expect(await note2.balanceOf(user1.address)).to.eq(1)
      const noteId = await note2.tokenOfOwnerByIndex(user1.address, 0)

      await nextEpoch(3, false)

      await pearl.transfer(mockDistributor.address, 20)
      await expect(() =>
        vault.connect(user1).claimReward(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 10)
      await expect(() =>
        vault.connect(user1).claimReward(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 20)

      await expect(() =>
        vault.connect(user1).exit(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 100)

      expect(await pearl.balanceOf(vault.address)).to.eq(0)
    })

    it('should forbid exit if the nft is not expired', async function () {
      const term = note.address
      const reward = 20
      await pearl.transfer(mockDistributor.address, reward)

      await expect(() =>
        vault.connect(user1).lock(term, 100)
      ).to.changeTokenBalance(pearl, user1, -100)

      await nextEpoch(1, false)

      expect(await note.balanceOf(user1.address)).to.eq(1)
      const noteId = await note.tokenOfOwnerByIndex(user1.address, 0)
      await expect(() =>
        vault.connect(user1).claimReward(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 20)

      await expect(vault.connect(user1).exit(term, noteId)).to.be.revertedWith(
        'PearlNote: the note is not expired'
      )
    })

    it('should split rewards to 2 nfts', async function () {
      const term = note.address

      const reward = 20
      await pearl.transfer(mockDistributor.address, reward)
      await vault.harvest()

      // user 1 lock
      await vault.connect(user1).lock(term, 100)
      await vault.connect(user2).lock(term, 300)

      await nextEpoch(2)

      const user1Note = await note.tokenOfOwnerByIndex(user1.address, 0)
      await expect(() =>
        vault.connect(user1).claimReward(term, user1Note)
      ).to.changeTokenBalance(pearl, user1, 5)
      await expect(() =>
        vault.connect(user1).exit(term, user1Note)
      ).to.changeTokenBalance(pearl, user1, 100)

      const user2Note = await note.tokenOfOwnerByIndex(user2.address, 0)
      await expect(() =>
        vault.connect(user2).exit(term, user2Note)
      ).to.changeTokenBalance(pearl, user2, 315)
      expect(await vault.totalLocked()).to.eq(0)
    })
  })

  describe('lock & withdraw two note', function () {
    let note1,
      note2,
      note1MinAmount = 1,
      note1MinLockPeriod = 2,
      note1Multiplier = 100,
      note2MinAmount = 100,
      note2MinLockPeriod = 3,
      note2Multiplier = 200

    beforeEach(async function () {
      const Note = await ethers.getContractFactory('PearlNote')

      note1 = await Note.deploy(
        'Note1',
        'NOTE1',
        'https://example.com/safe',
        pearl.address,
        vault.address
      )
      await vault.addTerm(
        note1.address,
        note1MinAmount,
        note1MinLockPeriod,
        note1Multiplier
      )

      note2 = await Note.deploy(
        'Note2',
        'NOTE2',
        'https://example.com/diamond',
        pearl.address,
        vault.address
      )
      await vault.addTerm(
        note2.address,
        note2MinAmount,
        note2MinLockPeriod,
        note2Multiplier
      )
    })

    it('should failed to lock less than min requirement', async function () {
      await expect(
        vault.connect(user1).lock(note2.address, 50)
      ).to.be.revertedWith('PearlVault: amount < min lock amount')
    })

    it('should split rewards to 2 notes', async function () {
      const reward = 30
      await pearl.transfer(mockDistributor.address, reward)

      // user1 lock to note1
      await vault.connect(user1).lock(note1.address, 100) // epoch 1 -> 2
      const user1Note = await note1.tokenOfOwnerByIndex(user1.address, 0)
      expect(await note1.endEpoch(user1Note)).to.eq(4)

      // user2 lock to note2
      await vault.connect(user2).lock(note2.address, 100)
      const user2Note = await note2.tokenOfOwnerByIndex(user2.address, 0)
      expect(await note2.endEpoch(user2Note)).to.eq(5)

      await nextEpoch(3)

      await expect(() =>
        vault.connect(user1).exit(note1.address, user1Note)
      ).to.changeTokenBalance(pearl, user1, 110)

      await expect(() =>
        vault.connect(user2).exit(note2.address, user2Note)
      ).to.changeTokenBalance(pearl, user2, 120)
    })

    it('should stop reward for note expired', async function () {
      let reward = 30
      await pearl.transfer(mockDistributor.address, reward)
      await vault.harvest() // epoch 1 -> 2

      // user1 lock to note1
      await vault.connect(user1).lock(note1.address, 100)
      const user1Note = await note1.tokenOfOwnerByIndex(user1.address, 0)
      // user2 lock to note2
      await vault.connect(user2).lock(note2.address, 100)
      const user2Note = await note2.tokenOfOwnerByIndex(user2.address, 0)

      await nextEpoch()

      reward = 200
      await pearl.transfer(mockDistributor.address, reward)
      await nextEpoch(3)

      await expect(() =>
        vault.connect(user1).exit(note1.address, user1Note)
      ).to.changeTokenBalance(pearl, user1, 110)

      await expect(() =>
        vault.connect(user2).exit(note2.address, user2Note)
      ).to.changeTokenBalance(pearl, user2, 320)
    })
  })

  describe('extend note', function () {
    const minLockAmount = 0
    const lockPeriod = 2
    const multiplier = 100
    let note

    beforeEach(async function () {
      const Note = await ethers.getContractFactory('PearlNote')
      note = await Note.deploy(
        'Note',
        'NOTE',
        'https://example.com/diamond',
        pearl.address,
        vault.address
      )
      await vault.addTerm(note.address, minLockAmount, lockPeriod, multiplier)
    })

    it('extend non-expired note', async function () {
      const term = note.address
      const reward = 10
      await pearl.transfer(mockDistributor.address, reward)

      await expect(() =>
        vault.connect(user1).lock(term, 100)
      ).to.changeTokenBalance(pearl, user1, -100)

      expect(await note.balanceOf(user1.address)).to.eq(1)

      now += 100
      await timeAndMine.setTimeNextBlock(now)

      await pearl.transfer(mockDistributor.address, 30)

      const noteId = await note.tokenOfOwnerByIndex(user1.address, 0)
      await expect(() =>
        vault.connect(user1).extendLock(term, noteId, 50)
      ).to.changeTokenBalance(pearl, user1, -50)

      await nextEpoch(2)

      await expect(() =>
        vault.connect(user1).claimReward(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 40)

      await expect(() =>
        vault.connect(user1).exit(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 150)

      expect(await pearl.balanceOf(vault.address)).to.eq(0)
    })

    it('failed to extend an expired note ', async function () {
      const term = note.address
      const reward = 10
      await pearl.transfer(mockDistributor.address, reward)

      await expect(() =>
        vault.connect(user1).lock(term, 100)
      ).to.changeTokenBalance(pearl, user1, -100) // 1 -> 2

      expect(await note.balanceOf(user1.address)).to.eq(1)

      await nextEpoch(5)

      const noteId = await note.tokenOfOwnerByIndex(user1.address, 0)
      await expect(
        vault.connect(user1).extendLock(term, noteId, 50)
      ).to.be.revertedWith('PearlVault: the note is expired') // 3 -> 4, expired

      await expect(() =>
        vault.connect(user1).claimReward(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 10)

      await expect(() =>
        vault.connect(user1).exit(term, noteId)
      ).to.changeTokenBalance(pearl, user1, 100)

      expect(await pearl.balanceOf(vault.address)).to.eq(0)
    })

    it('should split rewards to 2 notes', async function () {
      const term = note.address

      const reward = 20
      await pearl.transfer(mockDistributor.address, reward)
      await vault.harvest() // 1 -> 2

      await vault.connect(user1).lock(term, 100)
      const user1Note = await note.tokenOfOwnerByIndex(user1.address, 0)

      await pearl.transfer(mockDistributor.address, 100)
      await nextEpoch(1, false)
      await vault.connect(user2).lock(term, 300) // 2 -> 3, lock at 3

      await expect(() =>
        vault.connect(user1).extendLock(term, user1Note, 100)
      ).to.changeTokenBalance(pearl, user1, -100)

      await pearl.transfer(mockDistributor.address, 20)
      await nextEpoch() // 3 -> 4
      expect(await vault.reward(term, user1Note)).to.eq(60)

      await expect(() =>
        vault.connect(user1).claimReward(term, user1Note)
      ).to.changeTokenBalance(pearl, user1, 60)

      await expect(
        vault.connect(user1).exit(term, user1Note)
      ).to.be.revertedWith('PearlNote: the note is not expired')

      await pearl.transfer(mockDistributor.address, 20)
      await nextEpoch()
      await pearl.transfer(mockDistributor.address, 20)
      await nextEpoch()

      expect(await vault.reward(term, user1Note)).to.eq(8)

      await expect(() =>
        vault.connect(user1).exit(term, user1Note)
      ).to.changeTokenBalance(pearl, user1, 208)

      expect(await pearl.balanceOf(vault.address)).to.eq(112)

      const user2Note = await note.tokenOfOwnerByIndex(user2.address, 0)
      await expect(() =>
        vault.connect(user2).exit(term, user2Note)
      ).to.changeTokenBalance(pearl, user2, 372)

      expect(await vault.totalLocked()).to.eq(0)
      expect(await pearl.balanceOf(vault.address)).to.eq(40)
    })
  })
})
