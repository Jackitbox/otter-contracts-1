const { ethers, timeAndMine } = require('hardhat')
const { expect } = require('chai')

describe('OtterClam2021Q4ERC721', function () {
  let nft, deployer, otter

  beforeEach(async function () {
    ;[deployer, otter] = await ethers.getSigners()
    const NFT = await ethers.getContractFactory('OtterPAW')
    nft = await NFT.deploy('diamond hand otter', 'DHO', 'ipfs://metadata')
  })

  it('construct', async function () {
    expect(await nft.name()).to.eq('diamond hand otter')
    expect(await nft.symbol()).to.eq('DHO')
  })

  describe('whitelist', function () {
    it('should return false', async function () {
      expect(await nft.whitelist(otter.address)).to.be.false
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

    it('not in whitelist', async function () {
      await expect(nft.connect(otter).claim()).to.be.revertedWith(
        'not in whitelist'
      )
    })
  })

  describe('claim', function () {
    it('not started', async function () {
      await timeAndMine.setTimeNextBlock(
        Date.UTC(2021, 11, 24, 12, 0, 0) / 1000
      )
      await nft.setWhitelist([otter.address])
      await expect(nft.connect(otter).claim()).to.be.revertedWith(
        'party start at 2021-12-24T013:00:00Z'
      )
    })

    it('claimed', async function () {
      await timeAndMine.setTimeNextBlock(
        Date.UTC(2021, 11, 24, 13, 1, 0) / 1000
      )
      await nft.setWhitelist([otter.address])

      expect(await nft.currentTokenIndex()).to.eq(0)
      await nft.connect(otter).claim()
      expect(await nft.claimed(otter.address)).to.eq(1)
      expect(await nft.currentTokenIndex()).to.eq(1)
      await expect(nft.tokenURI(0)).to.revertedWith('ERC721Metadata: URI query for nonexistent token')
      expect(await nft.tokenURI(1)).to.eq('ipfs://metadata')
      await expect(nft.tokenURI(2)).to.revertedWith('ERC721Metadata: URI query for nonexistent token')
    })

    it('auto increment id', async function () {
      await nft.setWhitelist([deployer.address, otter.address])

      expect(await nft.currentTokenIndex()).to.eq(0)
      await nft.claim()
      expect(await nft.currentTokenIndex()).to.eq(1)

      await nft.connect(otter).claim()
      expect(await nft.currentTokenIndex()).to.eq(2)

      expect(await nft.claimed(deployer.address)).to.eq(1)
      expect(await nft.claimed(otter.address)).to.eq(2)
    })

    it('can not claim twice', async function () {
      await nft.setWhitelist([otter.address])
      await nft.connect(otter).claim()
      await expect(nft.connect(otter).claim()).to.be.revertedWith(
        'already claimed'
      )
    })
  })

  describe('setURI', function () {
    it('set', async function () {
      await nft.setWhitelist([otter.address])
      await nft.connect(otter).claim()
      expect(await nft.tokenURI(1)).to.eq('ipfs://metadata')
      await nft.setURI('ipfs://changed')
      expect(await nft.tokenURI(1)).to.eq('ipfs://changed')
    })

    it('can not set after finalized', async function () {
      await nft.finalize()
      await expect(nft.setURI('ipfs://changed')).to.be.revertedWith('can not set URI after finalized')
    })

    it('can not finalize twice', async function () {
      await nft.finalize()
      await expect(nft.finalize()).to.be.revertedWith('already finalized')
    })
  })
})
