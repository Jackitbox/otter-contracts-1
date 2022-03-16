const { ethers, upgrades } = require('hardhat')
const { expect } = require('chai')
const { smock } = require('@defi-wonderland/smock')

describe('Otto', function () {
  let deployer, badguy, otto, dao

  const zeroAddress = '0x0000000000000000000000000000000000000000'
  const baseURI = 'http://localhost:8080/otto/metadata/'
  const maxOtto = 5000
  const maxBatchSize = 6

  beforeEach(async function () {
    ;[deployer, dao, badguy] = await ethers.getSigners()

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

  describe('OttoContract', function () {
    it('should fail to mint to zero address', async function () {
      await expect(otto.mint(zeroAddress, 1, [123])).to.be.revertedWith(
        'zero address'
      )
    })

    it('should fail to mint if caller is not operator', async function () {
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

    it('should fail to set name if caller is not token owner', async function () {
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

    it('should fail to set description if caller is not token owner', async function () {
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

    it('should able to mint 6 ottos at a time', async function () {
      await expect(() =>
        otto.mint(deployer.address, 6, [123, 456, 789, 1011, 1213, 1415])
      ).to.changeTokenBalance(otto, deployer, 6)

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

  describe.only('OttoPrimaryMarket', function () {
    let mkt, weth, clam

    beforeEach(async function () {
      const CLAM = await smock.mock('OtterClamERC20V2')
      const MKT = await ethers.getContractFactory('OttoPrimaryMarket')

      clam = await CLAM.deploy()
      await clam.setVault(deployer.address)

      weth = await CLAM.deploy()
      await weth.setVariable('_name', 'wrapped ether')
      await weth.setVariable('_symbol', 'WETH')
      await weth.setVariable('_decimals', 18)
      await weth.setVault(deployer.address)

      mkt = await upgrades.deployProxy(MKT, [
        otto.address,
        weth.address,
        clam.address,
        dao.address,
      ])
      await mkt.deployed()
    })

    describe('NOT_STARTED', function () {
      beforeEach(async function () {
        await otto.grantOperator(mkt.address)
      })

      it('should fail to prepare if caller is not contract owner', async function () {
        await expect(mkt.connect(badguy).prepare([123])).to.be.revertedWith(
          'Ownable: caller is not the owner'
        )
      })

      it('should able to prepare traits pool', async function () {
        const pool = [123, 456, 789, 1011, 1213, 1415]
        await mkt.prepare(pool)
        expect(await mkt.totalSupply()).to.eq(6)
        const prepared = await Promise.all(
          [...Array(6).keys()].map((i) => mkt.traitsPool(i))
        )
        expect(prepared.map((e) => e.toNumber())).to.deep.eq(pool)
      })

      it('should fail to mint when sale not started yet', async function () {
        await mkt.prepare([123])
        await expect(
          mkt.mint(deployer.address, 1, 0, false)
        ).to.be.revertedWith('sale not started yet')
      })
    })

    describe('PRE_SALE', function () {
      beforeEach(async function () {
        await otto.grantOperator(mkt.address)
        await mkt.preSaleStart()
      })

      it('should fail to mint if caller is not whitelisted', async function () {
        const pool = [123]
        await mkt.prepare(pool)
        await expect(
          mkt.mint(deployer.address, 1, 0, false)
        ).to.be.revertedWith('you are not allowed to mint')
      })

      describe('ottolisted', function () {
        beforeEach(async function () {
          await mkt.setOttolisted([deployer.address])
        })

        it('should able to mint 1 otto', async function () {
          const pool = [123]
          await mkt.prepare(pool)
          await expect(() =>
            mkt.mint(deployer.address, 1, 0, false)
          ).to.changeTokenBalance(otto, deployer, 1)
        })

        it('should able to mint 3 ottos at a time', async function () {
          const pool = [123, 456, 789, 1011, 1213, 1415]
          await mkt.prepare(pool)
          await expect(() =>
            mkt.mint(deployer.address, 3, 0, false)
          ).to.changeTokenBalance(otto, deployer, 3)
        })

        it('should fail to mint 4 ottos at a time', async function () {
          const pool = [123, 456, 789, 1011, 1213, 1415]
          await mkt.prepare(pool)
          await expect(
            mkt.mint(deployer.address, 4, 0, false)
          ).to.be.revertedWith('you can not mint over 3 tokens')
        })

        it('should fail to mint 4 ottos at twice', async function () {
          const pool = [123, 456, 789, 1011, 1213, 1415]
          await mkt.prepare(pool)
          await expect(() =>
            mkt.mint(deployer.address, 3, 0, false)
          ).to.changeTokenBalance(otto, deployer, 3)
          await expect(
            mkt.mint(deployer.address, 1, 0, false)
          ).to.be.revertedWith('you can not mint over 3 tokens')
        })
      })

      describe('diamondhands', function () {
        beforeEach(async function () {
          await mkt.setDiamondhands([deployer.address])
        })

        it('should able to mint 1 otto', async function () {
          const pool = [123]
          await mkt.prepare(pool)
          await expect(() =>
            mkt.mint(deployer.address, 1, 0, false)
          ).to.changeTokenBalance(otto, deployer, 1)
        })

        it('should able to mint 3 ottos at a time', async function () {
          const pool = [123, 456, 789, 1011, 1213, 1415]
          await mkt.prepare(pool)
          await expect(() =>
            mkt.mint(deployer.address, 3, 0, false)
          ).to.changeTokenBalance(otto, deployer, 3)
        })

        it('should fail to mint 4 ottos at a time', async function () {
          const pool = [123, 456, 789, 1011, 1213, 1415]
          await mkt.prepare(pool)
          await expect(
            mkt.mint(deployer.address, 4, 0, false)
          ).to.be.revertedWith('you can not mint over 3 tokens')
        })

        it('should fail to mint 4 ottos at twice', async function () {
          const pool = [123, 456, 789, 1011, 1213, 1415]
          await mkt.prepare(pool)
          await expect(() =>
            mkt.mint(deployer.address, 3, 0, false)
          ).to.changeTokenBalance(otto, deployer, 3)
          await expect(
            mkt.mint(deployer.address, 1, 0, false)
          ).to.be.revertedWith('you can not mint over 3 tokens')
        })
      })

      describe('ottolisted + diamondhands', function () {
        beforeEach(async function () {
          await mkt.setOttolisted([deployer.address])
          await mkt.setDiamondhands([deployer.address])
        })

        it('should able to mint 1 otto', async function () {
          const pool = [123]
          await mkt.prepare(pool)
          await expect(() =>
            mkt.mint(deployer.address, 1, 0, false)
          ).to.changeTokenBalance(otto, deployer, 1)
        })

        it('should able to mint 6 ottos at a time', async function () {
          const pool = [123, 456, 789, 1011, 1213, 1415]
          await mkt.prepare(pool)
          await expect(() =>
            mkt.mint(deployer.address, 6, 0, false)
          ).to.changeTokenBalance(otto, deployer, 6)
        })

        it('should fail to mint 7 ottos at a time', async function () {
          const pool = [123, 456, 789, 1011, 1213, 1415, 1516]
          await mkt.prepare(pool)
          await expect(
            mkt.mint(deployer.address, 7, 0, false)
          ).to.be.revertedWith('you can not mint over 6 tokens')
        })

        it('should fail to mint 7 ottos at twice', async function () {
          const pool = [123, 456, 789, 1011, 1213, 1415, 1516]
          await mkt.prepare(pool)
          await expect(() =>
            mkt.mint(deployer.address, 6, 0, false)
          ).to.changeTokenBalance(otto, deployer, 6)
          await expect(
            mkt.mint(deployer.address, 1, 0, false)
          ).to.be.revertedWith('you can not mint over 6 tokens')
        })
      })
    })

    describe('PUBLIC_SALE', function () {
      beforeEach(async function () {
        await otto.grantOperator(mkt.address)
        await mkt.publicSaleStart()
      })

      it('should fail to mint otto after sold out', async function () {
        await expect(
          mkt.mint(deployer.address, 1, 0, false)
        ).to.be.revertedWith('out of stock')
      })

      it('should fail to mint otto if out of stock', async function () {
        await mkt.prepare([123])
        await expect(
          mkt.mint(deployer.address, 2, 0, false)
        ).to.be.revertedWith('out of stock')
      })

      it('should able to mint 1 otto', async function () {
        const pool = [123, 456, 789, 1011, 1213, 1415]
        await mkt.prepare(pool)
        await expect(() =>
          mkt.mint(deployer.address, 1, 0, false)
        ).to.changeTokenBalance(otto, deployer, 1)
        expect(await otto.ownerOf(0)).to.eq(deployer.address)
        expect(await otto.tokenURI(0)).to.eq(`${baseURI}0`)

        expect(await mkt.totalSupply()).to.eq(5)
        const remain = await Promise.all(
          [...Array(5).keys()].map((i) => mkt.traitsPool(i))
        )
        const [, , , bought] = await otto.get(0)
        expect(
          remain.map((e) => e.toNumber()).sort((a, b) => a - b)
        ).to.deep.eq(pool.filter((e) => e !== bought.toNumber()))
      })

      it('should fail to mint 7 ottos at a time', async function () {
        const pool = [123, 456, 789, 1011, 1213, 1415, 1516]
        await mkt.prepare(pool)
        await expect(
          mkt.mint(deployer.address, 7, 0, false)
        ).to.be.revertedWith('ERC721AUpgradeable: quantity to mint too high')
      })

      it('should able to mint 6 ottos at a time', async function () {
        const pool = [123, 456, 789, 1011, 1213, 1415]
        await mkt.prepare(pool)
        await expect(() =>
          mkt.mint(deployer.address, 6, 0, false)
        ).to.changeTokenBalance(otto, deployer, 6)
        const ids = await Promise.all(
          [...Array(6).keys()].map((i) =>
            otto.tokenOfOwnerByIndex(deployer.address, i)
          )
        )
        expect(ids.map((id) => id.toNumber())).to.deep.eq([...Array(6).keys()])

        const infos = await Promise.all(ids.map((i) => otto.get(i)))
        expect(
          infos.map((info) => info[3].toNumber()).sort((a, b) => a - b)
        ).to.deep.eq(pool)
      })

      it('should able to mint 12 ottos at twice', async function () {
        const pool = [
          123, 456, 789, 1011, 1213, 1415, 1516, 1718, 1920, 2122, 2324, 2526,
        ]
        await mkt.prepare(pool)
        await expect(() =>
          mkt.mint(deployer.address, 6, 0, false)
        ).to.changeTokenBalance(otto, deployer, 6)
        await expect(() =>
          mkt.mint(deployer.address, 6, 0, false)
        ).to.changeTokenBalance(otto, deployer, 6)
        const ids = await Promise.all(
          [...Array(12).keys()].map((i) =>
            otto.tokenOfOwnerByIndex(deployer.address, i)
          )
        )
        expect(ids.map((id) => id.toNumber())).to.deep.eq([...Array(12).keys()])

        const infos = await Promise.all(ids.map((i) => otto.get(i)))
        expect(
          infos.map((info) => info[3].toNumber()).sort((a, b) => a - b)
        ).to.deep.eq(pool)
      })
    })
  })
})
