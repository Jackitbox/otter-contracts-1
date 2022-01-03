const { ethers } = require('hardhat')
const { expect } = require('chai')
const { parseEther } = require('ethers/lib/utils')

describe('PearlNote', function () {
  // Large number for approval for DAI
  const largeApproval = '100000000000000000000000000000000'

  let deployer, note, dai, user, mockVault

  beforeEach(async function () {
    ;[deployer, user] = await ethers.getSigners()

    const DAI = await ethers.getContractFactory('DAI')
    dai = await DAI.deploy(0)

    const MockVault = await ethers.getContractFactory('MockVault')
    mockVault = await MockVault.deploy(dai.address)
    mockVault = mockVault.connect(user)

    const Note = await ethers.getContractFactory('PearlNote')
    note = await Note.deploy(
      'Otter Note',
      'NOTE',
      'https://otter.note/',
      dai.address,
      mockVault.address
    )

    // mint 1,000,000 DAI for testing
    await dai.mint(deployer.address, parseEther(String(100 * 10000)))
    await dai.transfer(user.address, 10000)

    // approve
    await dai.connect(deployer).approve(mockVault.address, largeApproval)
    await dai.connect(user).approve(mockVault.address, largeApproval)
  })

  describe('mint & burn', function () {
    it('should failed mint for non-vault address', async function () {
      await expect(note.mint(user.address, 100, 10)).to.be.revertedWith(
        'VaultOwned: caller is not the Vault'
      )
    })

    it('only vault can burn', async function () {
      await expect(() =>
        mockVault.mint(note.address, user.address, 100, 0)
      ).to.changeTokenBalance(dai, user, -100)

      expect(await note.balanceOf(user.address)).to.eq(1)

      const noteId = await note.tokenOfOwnerByIndex(user.address, 0)
      await expect(note.connect(deployer).burn(noteId)).to.be.revertedWith(
        'VaultOwned: caller is not the Vault'
      )
    })

    it('should success mint & burn', async function () {
      await expect(() =>
        mockVault.mint(note.address, user.address, 100, 3)
      ).to.changeTokenBalance(dai, user, -100)

      expect(await note.balanceOf(user.address)).to.eq(1)

      const noteId = await note.tokenOfOwnerByIndex(user.address, 0)
      expect(await note.lockAmount(noteId)).to.eq(100)
      expect(await note.endEpoch(noteId)).to.eq(3)
      expect(await note.tokenURI(noteId)).to.eq('https://otter.note/0')

      await mockVault.setEpoch(3)

      await expect(() =>
        mockVault.burn(note.address, noteId)
      ).to.changeTokenBalance(dai, user, 100)
      expect(await note.balanceOf(user.address)).to.eq(0)
    })

    it('should failed to burn if not expired', async function () {
      await mockVault.setEpoch(3)
      await expect(() =>
        mockVault.mint(note.address, user.address, 100, 5)
      ).to.changeTokenBalance(dai, user, -100)

      expect(await note.balanceOf(user.address)).to.eq(1)

      const noteId = await note.tokenOfOwnerByIndex(user.address, 0)
      await expect(mockVault.burn(note.address, noteId)).to.be.revertedWith(
        'PearlNote: the note is not expired'
      )
    })

    it('should burn if unlocked all', async function () {
      await mockVault.setEpoch(3)
      await expect(() =>
        mockVault.mint(note.address, user.address, 100, 5)
      ).to.changeTokenBalance(dai, user, -100)

      expect(await note.balanceOf(user.address)).to.eq(1)
      await note.unlockAll()

      const noteId = await note.tokenOfOwnerByIndex(user.address, 0)
      await expect(() =>
        mockVault.burn(note.address, noteId)
      ).to.changeTokenBalance(dai, user, 100)
    })

    it('should success mint two notes & burn', async function () {
      await mockVault.setEpoch(1)
      await expect(() =>
        mockVault.mint(note.address, user.address, 100, 1)
      ).to.changeTokenBalance(dai, user, -100)

      await expect(() =>
        mockVault.mint(note.address, user.address, 200, 2)
      ).to.changeTokenBalance(dai, user, -200)

      expect(await note.balanceOf(user.address)).to.eq(2)

      const noteId = await note.tokenOfOwnerByIndex(user.address, 0)
      expect(await note.ownerOf(noteId)).to.eq(user.address)
      expect(await note.lockAmount(noteId)).to.eq(100)
      expect(await note.endEpoch(noteId)).to.eq(1)
      expect(await note.tokenURI(noteId)).to.eq('https://otter.note/0')

      const noteId2 = await note.tokenOfOwnerByIndex(user.address, 1)
      expect(await note.ownerOf(noteId2)).to.eq(user.address)
      expect(await note.lockAmount(noteId2)).to.eq(200)
      expect(await note.endEpoch(noteId2)).to.eq(2)
      expect(await note.tokenURI(noteId2)).to.eq('https://otter.note/1')

      await expect(() =>
        mockVault.burn(note.address, noteId)
      ).to.changeTokenBalance(dai, user, 100)
      await expect(mockVault.burn(note.address, noteId2)).to.be.revertedWith(
        'PearlNote: the note is not expired'
      )
      expect(await note.balanceOf(user.address)).to.eq(1)
    })
  })

  describe('extend lock', function () {
    it('should success mint & burn', async function () {
      await expect(() =>
        mockVault.mint(note.address, user.address, 100, 0)
      ).to.changeTokenBalance(dai, user, -100)

      expect(await note.balanceOf(user.address)).to.eq(1)

      const noteId = await note.tokenOfOwnerByIndex(user.address, 0)

      await expect(() =>
        mockVault.extendLock(note.address, noteId, 50, 10)
      ).to.changeTokenBalance(dai, user, -50)

      expect(await note.lockAmount(noteId)).to.eq(150)
      expect(await note.endEpoch(noteId)).to.eq(10)
      expect(await note.tokenURI(noteId)).to.eq('https://otter.note/0')

      await expect(mockVault.burn(note.address, noteId)).to.be.revertedWith(
        'PearlNote: the note is not expired'
      )

      await mockVault.setEpoch(10)

      await expect(() =>
        mockVault.burn(note.address, noteId)
      ).to.changeTokenBalance(dai, user, 150)
      expect(await note.balanceOf(user.address)).to.eq(0)
    })
  })
})
