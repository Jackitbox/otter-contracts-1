const { ethers, upgrades } = require('hardhat')
const { expect } = require('chai')

describe('Otto', function () {
  let deployer, badguy, otto

  const zeroAddress = '0x0000000000000000000000000000000000000000'
  const baseURI = 'http://localhost:8080/otto/metadata/'
  const maxOtto = 5000
  const maxBatchSize = 6

  beforeEach(async function () {
    ;[deployer, badguy] = await ethers.getSigners()

    const OTTO = await ethers.getContractFactory('Otto')
    otto = await upgrades.deployProxy(OTTO, [
      'Otto',
      'OTTO',
      maxBatchSize,
      maxOtto,
    ])
    await otto.deployed()

    expect(await otto.name()).to.eq('Otto')
    expect(await otto.symbol()).to.eq('OTTO')
    await otto.setBaseURI(baseURI)
  })

  describe('Otto Contract', function () {
    it('should fail to mint to zero address', async function () {
      await expect(otto.mint(zeroAddress, 1, [123])).to.be.revertedWith(
        'zero address'
      )
    })

    it('should fail to mint when call is not operator', async function () {
      await expect(otto.connect(badguy).mint(deployer.address, 1, [123])).to.be
        .reverted
    })

    it('should able to mint 1 otto', async function () {
      await expect(() =>
        otto.mint(deployer.address, 1, [123])
      ).to.changeTokenBalance(otto, deployer, 1)
      expect(await otto.ownerOf(0)).to.eq(deployer.address)
      expect(await otto.balanceOf(deployer.address)).to.eq(1)
      expect(await otto.tokenURI(0)).to.eq(`${baseURI}0`)

      const [
        name,
        desc,
        birthday,
        traits,
        level,
        experiences,
        hungerValue,
        friendship,
        attrs,
        bonuses,
      ] = await otto.get(0)

      expect(name).to.eq('')
      expect(desc).to.eq('')
      expect(birthday).to.eq(0)
      expect(traits).to.eq(123)
      expect(level).to.eq(1)
      expect(experiences).to.eq(0)
      expect(hungerValue).to.eq(0)
      expect(friendship).to.eq(0)
      expect(attrs).to.deep.eq([0, 0, 0, 0, 0, 0, 0, 0])
      expect(bonuses).to.deep.eq([0, 0, 0, 0, 0, 0, 0, 0])
    })

    it('should fail to set name when caller is not token owner', async function () {
      await expect(() =>
        otto.mint(deployer.address, 1, [123])
      ).to.changeTokenBalance(otto, deployer, 1)
      await otto.setName(0, 'king')
      await expect(otto.connect(badguy).setName(0, 'king')).to.be.revertedWith(
        'caller is not the owner of the token'
      )
    })

    it('should able to set name', async function () {
      await expect(() =>
        otto.mint(deployer.address, 1, [123])
      ).to.changeTokenBalance(otto, deployer, 1)
      await otto.setName(0, 'king')
      const [name] = await otto.get(0)
      expect(name).to.eq('king')
    })

    it('should fail to set description when caller is not token owner', async function () {
      await expect(() =>
        otto.mint(deployer.address, 1, [123])
      ).to.changeTokenBalance(otto, deployer, 1)
      await otto.setDescription(0, 'I am king')
      await expect(
        otto.connect(badguy).setName(0, 'I am king')
      ).to.be.revertedWith('caller is not the owner of the token')
    })

    it('should able to set description', async function () {
      await expect(() =>
        otto.mint(deployer.address, 1, [123])
      ).to.changeTokenBalance(otto, deployer, 1)
      await otto.setDescription(0, 'I am king')
      const [, desc] = await otto.get(0)
      expect(desc).to.eq('I am king')
    })

    it('should fail to mint 6 ottos with 3 traits', async function () {
      await expect(
        otto.mint(deployer.address, 6, [123, 456, 789])
      ).to.be.revertedWith('invalid traits length')
    })

    it('should able to mint 6 ottos', async function () {
      await expect(() =>
        otto.mint(deployer.address, 6, [123, 456, 789, 1011, 1213, 1415])
      ).to.changeTokenBalance(otto, deployer, 6)
      expect(await otto.balanceOf(deployer.address)).to.eq(6)

      const ids = await Promise.all(
        [...Array(6).keys()].map((i) =>
          otto.tokenOfOwnerByIndex(deployer.address, i)
        )
      )
      expect(ids.map((id) => id.toNumber())).to.deep.eq([0, 1, 2, 3, 4, 5])
      const infos = await Promise.all(ids.map((i) => otto.get(i)))
      expect(infos.map((traits) => traits[3].toNumber())).to.deep.eq([
        123, 456, 789, 1011, 1213, 1415,
      ])
    })
  })
})
