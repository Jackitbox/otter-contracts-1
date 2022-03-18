const { ethers, upgrades } = require('hardhat')
const { parseEther, parseUnits } = require('@ethersproject/units')
const { BigNumber } = require('@ethersproject/bignumber')

const { expect } = require('chai')
const { smock } = require('@defi-wonderland/smock')
const {
  abi: UniswapV2Pair,
} = require('@uniswap/v2-core/build/UniswapV2Pair.json')
const {
  abi: IEACAggregatorProxy,
} = require('../artifacts/contracts/OttopiaPortalCreator.sol/IEACAggregatorProxy.json')

describe('Otto', function () {
  let deployer, badguy, otto, dao, treasury

  const zeroAddress = '0x0000000000000000000000000000000000000000'
  const baseURI = 'http://localhost:8080/otto/metadata/'

  beforeEach(async function () {
    ;[deployer, dao, badguy, treasury] = await ethers.getSigners()

    const OTTO = await ethers.getContractFactory('Otto')
    otto = await upgrades.deployProxy(OTTO, [
      'Otto',
      'OTTO',
      6, // maxBatchSize
      5000, // maxOttos
    ])
    await otto.deployed()

    expect(await otto.name()).to.eq('Otto')
    expect(await otto.symbol()).to.eq('OTTO')
    await otto.setBaseURI(baseURI)
  })

  describe('OttoContract', function () {
    it('should fail to mint to zero address', async function () {
      await expect(otto.mint(zeroAddress, 1)).to.be.revertedWith('zero address')
    })

    it('should fail to mint if caller is not operator', async function () {
      await expect(otto.connect(badguy).mint(deployer.address, 1)).to.be
        .reverted
    })

    it('should fail to mint more than', async function () {
      const OTTO = await ethers.getContractFactory('Otto')
      const otto = await upgrades.deployProxy(OTTO, [
        'Otto',
        'OTTO',
        6, // maxBatchSize
        8, // maxOttos
      ])
      await otto.deployed()
      await expect(() => otto.mint(deployer.address, 6)).to.changeTokenBalance(
        otto,
        deployer,
        6
      )
      await expect(otto.mint(deployer.address, 3)).to.be.revertedWith(
        'ERC721AUpgradeable: out of stock'
      )
      await expect(() => otto.mint(deployer.address, 2)).to.changeTokenBalance(
        otto,
        deployer,
        2
      )
      await expect(otto.mint(deployer.address, 1)).to.be.revertedWith(
        'ERC721AUpgradeable: out of stock'
      )
    })

    it('should able to upgrade collection size', async function () {
      const OTTO = await ethers.getContractFactory('Otto')
      const otto = await upgrades.deployProxy(OTTO, [
        'Otto',
        'OTTO',
        3, // maxBatchSize
        3, // maxOttos
      ])
      await otto.deployed()
      await expect(() => otto.mint(deployer.address, 3)).to.changeTokenBalance(
        otto,
        deployer,
        3
      )
      await expect(otto.mint(deployer.address, 1)).to.be.revertedWith(
        'ERC721AUpgradeable: out of stock'
      )
      const OTTOV2 = await ethers.getContractFactory('OttoV2')
      const ottoV2 = await upgrades.upgradeProxy(otto, OTTOV2)
      await ottoV2.spo(3, 4)
      await expect(() =>
        ottoV2.mint(deployer.address, 1)
      ).to.changeTokenBalance(otto, deployer, 1)
      await expect(ottoV2.mint(deployer.address, 1)).to.be.revertedWith(
        'ERC721AUpgradeable: out of stock'
      )
    })

    it('should able to mint 1 otto', async function () {
      await expect(() => otto.mint(deployer.address, 1)).to.changeTokenBalance(
        otto,
        deployer,
        1
      )
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
      expect(traits).to.eq(0)
      expect(level).to.eq(0)
      expect(experiences).to.eq(0)
      expect(hungerValue).to.eq(0)
      expect(friendship).to.eq(0)
      expect(attrs).to.deep.eq([0, 0, 0, 0, 0, 0, 0, 0])
      expect(bonuses).to.deep.eq([0, 0, 0, 0, 0, 0, 0, 0])
    })

    // it('should fail to set name if caller is not token owner', async function () {
    //   await expect(() => otto.mint(deployer.address, 1)).to.changeTokenBalance(
    //     otto,
    //     deployer,
    //     1
    //   )
    //   await otto.setName(0, 'king')
    //   await expect(otto.connect(badguy).setName(0, 'king')).to.be.revertedWith(
    //     'caller is not the owner of the token'
    //   )
    // })

    // it('should able to set name', async function () {
    //   await expect(() => otto.mint(deployer.address, 1)).to.changeTokenBalance(
    //     otto,
    //     deployer,
    //     1
    //   )
    //   await otto.setName(0, 'king')
    //   const [name] = await otto.get(0)
    //   expect(name).to.eq('king')
    // })

    // it('should fail to set description if caller is not token owner', async function () {
    //   await expect(() => otto.mint(deployer.address, 1)).to.changeTokenBalance(
    //     otto,
    //     deployer,
    //     1
    //   )
    //   await otto.setDescription(0, 'I am king')
    //   await expect(
    //     otto.connect(badguy).setName(0, 'I am king')
    //   ).to.be.revertedWith('caller is not the owner of the token')
    // })

    // it('should able to set description', async function () {
    //   await expect(() => otto.mint(deployer.address, 1)).to.changeTokenBalance(
    //     otto,
    //     deployer,
    //     1
    //   )
    //   await otto.setDescription(0, 'I am king')
    //   const [, desc] = await otto.get(0)
    //   expect(desc).to.eq('I am king')
    // })

    it('should fail to set if caller is not manager', async function () {
      await expect(() => otto.mint(deployer.address, 3)).to.changeTokenBalance(
        otto,
        deployer,
        3
      )
      await expect(
        otto.connect(badguy).set(
          1, // tokenId
          12345, // birthday
          1, // traits
          2, // level
          3, // experiences
          4, // hungerValue
          5, // friendship
          [6, 7, 8, 9, 10, 11, 12, 13], // attrs
          [14, 15, 16, 17, 18, 19, 20, 21] // bonuses
        )
      ).to.be.reverted
    })

    it('should able to set by manager', async function () {
      await expect(() => otto.mint(deployer.address, 3)).to.changeTokenBalance(
        otto,
        deployer,
        3
      )
      await otto.set(
        1, // tokenId
        12345, // birthday
        1, // traits
        2, // level
        3, // experiences
        4, // hungerValue
        5, // friendship
        [6, 7, 8, 9, 10, 11, 12, 13], // attrs
        [14, 15, 16, 17, 18, 19, 20, 21] // bonuses
      )
      const [name, desc, ...got] = await otto.get(1)
      expect(name).to.eq('')
      expect(desc).to.eq('')
      expect(got.map((e) => (e.toNumber ? e.toNumber() : e))).to.deep.eq([
        12345, // birthday
        1, // traits
        2, // level
        3, // experiences
        4, // hungerValue
        5, // friendship
        [6, 7, 8, 9, 10, 11, 12, 13], // attrs
        [14, 15, 16, 17, 18, 19, 20, 21], // bonuses
      ])
    })

    it('should able to mint 6 ottos at a time', async function () {
      await expect(() => otto.mint(deployer.address, 6)).to.changeTokenBalance(
        otto,
        deployer,
        6
      )
      const ids = await Promise.all(
        [...Array(6).keys()].map((i) =>
          otto.tokenOfOwnerByIndex(deployer.address, i)
        )
      )
      expect(ids.map((id) => id.toNumber())).to.deep.eq([0, 1, 2, 3, 4, 5])
    })

    it('should fail to mint 7 ottos at a time', async function () {
      await expect(otto.mint(deployer.address, 7)).to.be.revertedWith(
        'ERC721AUpgradeable: quantity to mint too high'
      )
    })

    it('should able to encode and decode uint256 correctly', async function () {
      const arr = Array(32).fill(0)
      let n = 0
      expect(await otto.U8toU256(arr)).to.eq(n)
      expect(await otto.U256toU8(n)).to.deep.eq(arr)

      arr[0] = 1
      n = 1
      expect(await otto.U8toU256(arr)).to.eq(n)
      expect(await otto.U256toU8(n)).to.deep.eq(arr)

      arr[1] = 1
      n = 257
      expect(await otto.U8toU256(arr)).to.eq(n)
      expect(await otto.U256toU8(n)).to.deep.eq(arr)

      arr[2] = 1
      n = 65793
      expect(await otto.U8toU256(arr)).to.eq(n)
      expect(await otto.U256toU8(n)).to.deep.eq(arr)

      arr[31] = 1
      n = BigNumber.from(
        '0x0100000000000000000000000000000000000000000000000000000000010101'
      )
      expect(await otto.U8toU256(arr)).to.eq(n)
      expect(await otto.U256toU8(n)).to.deep.eq(arr)
    })
  })

  describe('OttopiaPortalCreator', function () {
    let portalCreator, weth, clam, mai, maiclam, wethPriceFeed

    beforeEach(async function () {
      const CLAM = await smock.mock('OtterClamERC20V2')
      const PORTALCREATOR = await ethers.getContractFactory(
        'OttopiaPortalCreator'
      )

      clam = await CLAM.deploy()
      await clam.setVault(deployer.address)

      mai = await CLAM.deploy()
      await mai.setVariable('_name', 'MAI')
      await mai.setVariable('_symbol', 'MAI')
      await mai.setVariable('_decimals', 18)
      await mai.setVault(deployer.address)

      weth = await CLAM.deploy()
      await weth.setVariable('_name', 'wrapped ether')
      await weth.setVariable('_symbol', 'WETH')
      await weth.setVariable('_decimals', 18)
      await weth.setVault(deployer.address)

      maiclam = await smock.fake(UniswapV2Pair)
      maiclam.token0.returns(mai.address)
      maiclam.token1.returns(clam.address)
      maiclam.getReserves.returns([parseEther('2'), parseUnits('1', 9), 0]) // 1 CLAM = 2 MAI

      wethPriceFeed = await smock.fake(IEACAggregatorProxy)
      wethPriceFeed.decimals.returns(8)
      wethPriceFeed.latestAnswer.returns(parseUnits('100', 8)) // 1 ETH = 100 USD = 50 CLAM

      portalCreator = await upgrades.deployProxy(PORTALCREATOR, [
        otto.address,
        weth.address,
        maiclam.address,
        wethPriceFeed.address,
        treasury.address,
        dao.address,
      ])
      await portalCreator.deployed()
      await otto.grantMinter(portalCreator.address)
    })

    describe('ANY_STAGE', function () {
      it('should fail to give otto away if caller is not owner', async function () {
        await expect(
          portalCreator.connect(badguy).giveaway(dao.address, 1)
        ).to.be.revertedWith('Ownable: caller is not the owner')
      })

      it('should fail to give 0 otto away', async function () {
        await expect(portalCreator.giveaway(dao.address, 0)).to.be.revertedWith(
          'giveaway quantity must be greater than 0'
        )
      })
      ;[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13].forEach(function (amount) {
        it(`should be able to give ${amount} ottos away`, async function () {
          await expect(() =>
            portalCreator.giveaway(dao.address, amount)
          ).to.changeTokenBalance(otto, dao, amount)
        })
      })

      it('should fail to setOttolisted if caller is not owner', async function () {
        await expect(
          portalCreator.connect(badguy).setOttolisted(1, [dao.address])
        ).to.be.revertedWith('Ownable: caller is not the owner')
      })

      it('should able to setOttolisted', async function () {
        await portalCreator.setOttolisted(3, [dao.address])
        expect(await portalCreator.ottolisted(dao.address)).to.eq(3)
      })

      it('should fail to adjustPrice if caller is not owner', async function () {
        await expect(
          portalCreator.connect(badguy).adjustPrice(0, 123)
        ).to.be.revertedWith('Ownable: caller is not the owner')
      })

      it('should fail to stopSale if caller is not owner', async function () {
        await expect(
          portalCreator.connect(badguy).stopSale()
        ).to.be.revertedWith('Ownable: caller is not the owner')
      })

      it('should fail to startPreSale if caller is not owner', async function () {
        await expect(
          portalCreator.connect(badguy).startPreSale()
        ).to.be.revertedWith('Ownable: caller is not the owner')
      })

      it('should fail to startPublicSale if caller is not owner', async function () {
        await expect(
          portalCreator.connect(badguy).startPublicSale()
        ).to.be.revertedWith('Ownable: caller is not the owner')
      })

      it('should able to adjust price', async function () {
        await portalCreator.adjustPrice(0, 123)
        expect(await portalCreator.priceInWETH()).to.eq(123)
        await portalCreator.startPreSale()
        await portalCreator.adjustPrice(1, 456)
        expect(await portalCreator.priceInWETH()).to.eq(456)
        await portalCreator.startPublicSale()
        await portalCreator.adjustPrice(2, 789)
        expect(await portalCreator.priceInWETH()).to.eq(789)
        await expect(portalCreator.adjustPrice(3, 123)).to.be.reverted
      })

      it('should fail to emergencyWithdraw if caller is not owner', async function () {
        await expect(
          portalCreator.connect(badguy).emergencyWithdraw(weth.address)
        ).to.be.revertedWith('Ownable: caller is not the owner')
      })

      it('should able to emergencyWithdraw', async function () {
        await expect(() =>
          weth.mint(portalCreator.address, 100)
        ).to.changeTokenBalance(weth, portalCreator, 100)
        await expect(() =>
          portalCreator.emergencyWithdraw(weth.address)
        ).to.changeTokenBalance(weth, dao, 100)
      })

      it('should fail to distribute if caller is not owner', async function () {
        await expect(
          portalCreator.connect(badguy).distribute()
        ).to.be.revertedWith('Ownable: caller is not the owner')
      })

      it('should able to distribute', async function () {
        await expect(() =>
          weth.mint(portalCreator.address, 10000)
        ).to.changeTokenBalance(weth, portalCreator, 10000)
        await expect(() =>
          clam.mint(portalCreator.address, 100)
        ).to.changeTokenBalance(clam, portalCreator, 100)
        await expect(() => portalCreator.distribute()).to.changeTokenBalances(
          weth,
          [dao, treasury],
          [5000, 5000]
        )
        expect(await clam.balanceOf(dao.address)).to.eq(100)
      })
    })

    describe('NOT_STARTED', function () {
      it('price in weth', async function () {
        expect(await portalCreator.priceInWETH()).to.eq(parseEther('0.08'))
      })

      it('should fail to mint when sale not started yet', async function () {
        await expect(
          portalCreator.mint(deployer.address, 1, 123, false)
        ).to.be.revertedWith('sale not started yet')
      })
    })

    describe('PRE_SALE', function () {
      beforeEach(async function () {
        await portalCreator.startPreSale()
      })

      it('price in weth', async function () {
        expect(await portalCreator.priceInWETH()).to.eq(parseEther('0.06'))
      })

      it('price in clam', async function () {
        // 1 ETH = 100 USD = 50 CLAM
        // 0.06 ETH = 3 CLAM
        // 0.042 ETH = 2.1 CLAM
        expect(await portalCreator.priceInCLAM()).to.eq(parseUnits('2.1', 9))
      })

      it('price in clam in real world', async function () {
        wethPriceFeed.decimals.returns(8)
        wethPriceFeed.latestAnswer.returns(BigNumber.from('262733560000'))
        maiclam.getReserves.returns([
          BigNumber.from('342328856291545878163601'),
          BigNumber.from('91637067269631'),
          0,
        ])
        expect(await portalCreator.priceInCLAM()).to.eq(
          BigNumber.from('29538777222')
        )
      })

      it('should fail to mint if caller is not whitelisted', async function () {
        await expect(
          portalCreator.mint(deployer.address, 1, 0, false)
        ).to.be.revertedWith('you are not allowed to mint')
      })

      describe('ottolisted', function () {
        beforeEach(async function () {
          await portalCreator.setOttolisted(3, [deployer.address])
        })
        ;[1, 2, 3].forEach(function (quantity) {
          it(`should able to mint ${quantity} otto in weth`, async function () {
            const price = (await portalCreator.priceInWETH()).mul(quantity)
            await weth.mint(deployer.address, price)
            await weth.approve(portalCreator.address, price)
            await expect(() =>
              portalCreator.mint(deployer.address, quantity, price, false)
            ).to.changeTokenBalance(otto, deployer, quantity)
            expect(await weth.balanceOf(deployer.address)).to.eq(0)
          })
        })
        ;[1, 2, 3].forEach(function (quantity) {
          it(`should able to mint ${quantity} otto in clam`, async function () {
            const price = (await portalCreator.priceInCLAM()).mul(quantity)
            await clam.mint(deployer.address, price)
            await clam.approve(portalCreator.address, price)
            await expect(() =>
              portalCreator.mint(deployer.address, quantity, price, true)
            ).to.changeTokenBalance(otto, deployer, quantity)
            expect(await clam.balanceOf(deployer.address)).to.eq(0)
          })
        })

        it('should fail to mint 4 ottos', async function () {
          const price = (await portalCreator.priceInWETH()).mul(4)
          await weth.mint(deployer.address, price)
          await weth.approve(portalCreator.address, price)
          await expect(
            portalCreator.mint(deployer.address, 4, price, false)
          ).to.be.revertedWith('you are not allowed to mint with this amount')
        })

        it('should fail to mint 4 ottos at twice', async function () {
          const price = await portalCreator.priceInWETH()
          await weth.mint(deployer.address, price.mul(4))
          await weth.approve(portalCreator.address, price.mul(4))
          await expect(() =>
            portalCreator.mint(deployer.address, 3, price.mul(3), false)
          ).to.changeTokenBalance(otto, deployer, 3)
          await expect(
            portalCreator.mint(deployer.address, 1, price, false)
          ).to.be.revertedWith('you are not allowed to mint with this amount')
        })
      })
    })

    describe('PUBLIC_SALE', function () {
      beforeEach(async function () {
        await portalCreator.startPublicSale()
      })

      it('price in weth', async function () {
        expect(await portalCreator.priceInWETH()).to.eq(parseEther('0.08'))
      })

      it('price in clam', async function () {
        // 1 ETH = 100 USD = 50 CLAM
        // 0.08 ETH = 4 CLAM
        // 0.056 ETH = 2.1 CLAM
        expect(await portalCreator.priceInCLAM()).to.eq(parseUnits('2.8', 9))
      })

      it('price in clam in real world', async function () {
        wethPriceFeed.decimals.returns(8)
        wethPriceFeed.latestAnswer.returns(BigNumber.from('262733560000'))
        maiclam.getReserves.returns([
          BigNumber.from('342328856291545878163601'),
          BigNumber.from('91637067269631'),
          0,
        ])
        expect(await portalCreator.priceInCLAM()).to.eq(
          BigNumber.from('39385036296')
        )
      })
      ;[1, 2, 3, 4, 5, 6].forEach(function (quantity) {
        it(`should able to mint ${quantity} ottos in weth`, async function () {
          const price = (await portalCreator.priceInWETH()).mul(quantity)
          await weth.mint(deployer.address, price)
          await weth.approve(portalCreator.address, price)
          await expect(() =>
            portalCreator.mint(deployer.address, quantity, price, false)
          ).to.changeTokenBalance(otto, deployer, quantity)
          const ids = await Promise.all(
            [...Array(quantity).keys()].map((i) =>
              otto.tokenOfOwnerByIndex(deployer.address, i)
            )
          )
          expect(ids.map((id) => id.toNumber())).to.deep.eq([
            ...Array(quantity).keys(),
          ])
        })
      })
      ;[1, 2, 3, 4, 5, 6].forEach(function (quantity) {
        it(`should able to mint ${quantity} ottos in clam`, async function () {
          const price = (await portalCreator.priceInWETH()).mul(quantity)
          await clam.mint(deployer.address, price)
          await clam.approve(portalCreator.address, price)
          await expect(() =>
            portalCreator.mint(deployer.address, quantity, price, true)
          ).to.changeTokenBalance(otto, deployer, quantity)
          const ids = await Promise.all(
            [...Array(quantity).keys()].map((i) =>
              otto.tokenOfOwnerByIndex(deployer.address, i)
            )
          )
          expect(ids.map((id) => id.toNumber())).to.deep.eq([
            ...Array(quantity).keys(),
          ])
        })
      })

      it('should fail to mint 7 ottos', async function () {
        const price = (await portalCreator.priceInWETH()).mul(7)
        await weth.mint(deployer.address, price)
        await weth.approve(portalCreator.address, price)
        await expect(
          portalCreator.mint(deployer.address, 7, price, false)
        ).to.be.revertedWith('ERC721AUpgradeable: quantity to mint too high')
      })

      it('should able to mint 12 ottos at twice', async function () {
        const price = (await portalCreator.priceInWETH()).mul(12)
        await weth.mint(deployer.address, price)
        await weth.approve(portalCreator.address, price)
        await expect(() =>
          portalCreator.mint(deployer.address, 6, price.div(2), false)
        ).to.changeTokenBalance(otto, deployer, 6)
        await expect(() =>
          portalCreator.mint(deployer.address, 6, price.div(2), false)
        ).to.changeTokenBalance(otto, deployer, 6)
        const ids = await Promise.all(
          [...Array(12).keys()].map((i) =>
            otto.tokenOfOwnerByIndex(deployer.address, i)
          )
        )
        expect(ids.map((id) => id.toNumber())).to.deep.eq([...Array(12).keys()])
      })
    })
  })
})
