const { ethers } = require('hardhat')
const { expect } = require('chai')
const { parseEther } = require('ethers/lib/utils')

describe('PearlNote', function () {
  // Large number for approval for DAI
  const largeApproval = '100000000000000000000000000000000'

  let deployer, note, dai, user

  beforeEach(async function () {
    ;[deployer, user] = await ethers.getSigners()

    const DAI = await ethers.getContractFactory('DAI')
    dai = await DAI.deploy(0)

    const Note = await ethers.getContractFactory('PearlNote')
    note = await Note.deploy(
      dai.address,
      'Otter Note',
      'NOTE',
      'https://otter.note/'
    )
    await note.setVault(user.address)
    note = note.connect(user)

    // mint 1,000,000 DAI for testing
    await dai.mint(deployer.address, parseEther(String(100 * 10000)))
    await dai.transfer(user.address, 10000)

    // approve
    await dai.connect(deployer).approve(note.address, largeApproval)
    await dai.connect(user).approve(note.address, largeApproval)
  })

  describe('mint & burn', function () {
    it('should failed mint for non-vault address', async function () {
      const now = Math.round(Date.now() / 1000)
      await expect(
        note.connect(deployer.address).mint(user.address, 100, now)
      ).to.be.revertedWith('VaultOwned: caller is not the Vault')
    })

    it('only vault can burn', async function () {
      const now = Math.round(Date.now() / 1000)
      await expect(() =>
        note.mint(user.address, 100, now)
      ).to.changeTokenBalance(dai, user, -100)

      expect(await note.balanceOf(user.address)).to.eq(1)

      const noteId = await note.tokenOfOwnerByIndex(user.address, 0)
      await expect(note.connect(deployer).burn(noteId)).to.be.revertedWith(
        'VaultOwned: caller is not the Vault'
      )
    })

    it('should success mint & burn', async function () {
      const now = Math.round(Date.now() / 1000)
      await expect(() =>
        note.mint(user.address, 100, now)
      ).to.changeTokenBalance(dai, user, -100)

      expect(await note.balanceOf(user.address)).to.eq(1)

      const noteId = await note.tokenOfOwnerByIndex(user.address, 0)
      expect(await note.lockAmount(noteId)).to.eq(100)
      expect(await note.dueDate(noteId)).to.eq(now)
      expect(await note.tokenURI(noteId)).to.eq('https://otter.note/0')

      await expect(() => note.burn(noteId)).to.changeTokenBalance(
        dai,
        user,
        100
      )
      expect(await note.balanceOf(user.address)).to.eq(0)
    })

    it('should failed to burn if not expired', async function () {
      const now = Math.round(Date.now() / 1000)
      await expect(() =>
        note.mint(user.address, 100, now + 100)
      ).to.changeTokenBalance(dai, user, -100)

      expect(await note.balanceOf(user.address)).to.eq(1)

      const noteId = await note.tokenOfOwnerByIndex(user.address, 0)
      await expect(note.burn(noteId)).to.be.revertedWith(
        'PearlNote: the note is not expired'
      )
    })

    it('should success mint two notes & burn', async function () {
      const now = Math.round(Date.now() / 1000)
      await expect(() =>
        note.mint(user.address, 100, now)
      ).to.changeTokenBalance(dai, user, -100)

      await expect(() =>
        note.mint(user.address, 200, now + 100)
      ).to.changeTokenBalance(dai, user, -200)

      expect(await note.balanceOf(user.address)).to.eq(2)

      const noteId = await note.tokenOfOwnerByIndex(user.address, 0)
      expect(await note.ownerOf(noteId)).to.eq(user.address)
      expect(await note.lockAmount(noteId)).to.eq(100)
      expect(await note.dueDate(noteId)).to.eq(now)
      expect(await note.tokenURI(noteId)).to.eq('https://otter.note/0')

      const noteId2 = await note.tokenOfOwnerByIndex(user.address, 1)
      expect(await note.ownerOf(noteId2)).to.eq(user.address)
      expect(await note.lockAmount(noteId2)).to.eq(200)
      expect(await note.dueDate(noteId2)).to.eq(now + 100)
      expect(await note.tokenURI(noteId2)).to.eq('https://otter.note/1')

      await expect(() => note.burn(noteId)).to.changeTokenBalance(
        dai,
        user,
        100
      )
      await expect(note.burn(noteId2)).to.be.revertedWith(
        'PearlNote: the note is not expired'
      )
      expect(await note.balanceOf(user.address)).to.eq(1)
    })
  })

  describe('extend lock', function () {
    it('should success mint & burn', async function () {
      const now = Math.round(Date.now() / 1000)
      await expect(() =>
        note.mint(user.address, 100, now - 10)
      ).to.changeTokenBalance(dai, user, -100)

      expect(await note.balanceOf(user.address)).to.eq(1)

      const noteId = await note.tokenOfOwnerByIndex(user.address, 0)

      await expect(() =>
        note.extendLock(noteId, 50, now)
      ).to.changeTokenBalance(dai, user, -50)

      expect(await note.lockAmount(noteId)).to.eq(150)
      expect(await note.dueDate(noteId)).to.eq(now)
      expect(await note.tokenURI(noteId)).to.eq('https://otter.note/0')

      await expect(() => note.burn(noteId)).to.changeTokenBalance(
        dai,
        user,
        150
      )
      expect(await note.balanceOf(user.address)).to.eq(0)
    })
  })
})
