const { ethers } = require('hardhat')
const { expect } = require('chai')

describe('OtterClam2021Q4ERC721', function () {
  let nft, deployer, otter

  beforeEach(async function () {
    ;[deployer, otter] = await ethers.getSigners()
    const NFT = await ethers.getContractFactory('OtterCardNFT')
    nft = await NFT.deploy('diamond hand otter', 'DHO', 'ipfs://metadata')
  })

  it('construct', async function () {
    expect(await nft.cardURI()).to.eq('ipfs://metadata')
    expect(await nft.name()).to.eq('diamond hand otter')
    expect(await nft.symbol()).to.eq('DHO')
  })

  describe('claim', function () {
    it('not in whitelist', async function () {
      await expect(nft.connect(otter).claim()).to.be.revertedWith(
        'not in whitelist'
      )
    })

    it('claimed', async function () {
      await nft.setWhitelist([otter.address])

      expect(await nft.tokenIdCount()).to.eq(0)
      await nft.connect(otter).claim()
      expect(await nft.claimed(otter.address)).to.eq(1)
      expect(await nft.tokenIdCount()).to.eq(1)
      expect(await nft.tokenURI(1)).to.eq('ipfs://metadata')
    })

    it('auto increment id', async function () {
      await nft.setWhitelist([deployer.address, otter.address])

      expect(await nft.tokenIdCount()).to.eq(0)
      await nft.claim()
      expect(await nft.tokenIdCount()).to.eq(1)

      await nft.connect(otter).claim()
      expect(await nft.tokenIdCount()).to.eq(2)

      expect(await nft.claimed(deployer.address)).to.eq(1)
      expect(await nft.claimed(otter.address)).to.eq(2)
    })

    it('claim twice', async function () {
      await nft.setWhitelist([otter.address])

      await nft.connect(otter).claim()
      await expect(nft.connect(otter).claim()).to.be.revertedWith(
        'already claimed'
      )
    })
  })

  describe('whitelist', function () {
    it('should return false', async function () {
      await expect(await nft.whitelist(otter.address)).to.be.false
    })

    it('should return false after unset', async function () {
      await nft.setWhitelist([otter.address])
      await nft.unsetWhitelist([otter.address])
      await expect(await nft.whitelist(otter.address)).to.be.false
    })

    it('should return true', async function () {
      await nft.setWhitelist([otter.address])
      await expect(await nft.whitelist(otter.address)).to.be.true
    })

    it('only owner can set whitelist', async function () {
      await expect(
        nft.connect(otter).setWhitelist([otter.address])
      ).to.be.revertedWith('Ownable: caller is not the owner')
    })

    it('only owner can unset whitelist', async function () {
      await expect(
        nft.connect(otter).unsetWhitelist([otter.address])
      ).to.be.revertedWith('Ownable: caller is not the owner')
    })
  })
})
