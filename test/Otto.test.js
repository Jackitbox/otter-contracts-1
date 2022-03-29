const { ethers, upgrades, network } = require('hardhat')
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

  before(function () {
    upgrades.silenceWarnings()
  })

  beforeEach(async function () {
    ;[deployer, dao, badguy, treasury] = await ethers.getSigners()

    const OTTO = await ethers.getContractFactory('Otto')
    const OTTOV2 = await ethers.getContractFactory('OttoV2')
    const otto1 = await upgrades.deployProxy(
      OTTO,
      [
        'Otto',
        'OTTO',
        6, // maxBatchSize
        5000, // maxOttos
      ],
      { kind: 'uups' }
    )
    await otto1.deployed()
    otto = await upgrades.upgradeProxy(otto1.address, OTTOV2, {
      kind: 'uups',
      call: {
        fn: 'setSummonPeriod',
        args: [7 * 24 * 60 * 60],
      },
      unsafeSkipStorageCheck: true,
    })

    expect(await otto.name()).to.eq('Otto')
    expect(await otto.symbol()).to.eq('OTTO')
    expect(await otto.setBaseURI(baseURI))
      .to.emit(otto, 'BaseURIChanged')
      .withArgs(deployer.address, baseURI)
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
      const otto = await upgrades.deployProxy(
        OTTO,
        [
          'Otto',
          'OTTO',
          6, // maxBatchSize
          8, // maxOttos
        ],
        { kind: 'uups' }
      )
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

    it('should able to mint 1 otto', async function () {
      await expect(() => otto.mint(deployer.address, 1)).to.changeTokenBalance(
        otto,
        deployer,
        1
      )
      expect(await otto.ownerOf(0)).to.eq(deployer.address)
      expect(await otto.balanceOf(deployer.address)).to.eq(1)
      expect(await otto.tokenURI(0)).to.eq(`${baseURI}0`)

      const [name, desc, birthday, traits, values, attrs, bonuses, flags] =
        await otto.infos(0)

      expect(name).to.eq('')
      expect(desc).to.eq('')
      expect(birthday).to.eq(0)
      expect(traits).to.eq(0)
      expect(values).to.eq(0)
      expect(attrs).to.deep.eq(0)
      expect(bonuses).to.deep.eq(0)
      expect(flags).to.eq(0)
    })

    it('should fail to set if caller is not manager', async function () {
      await expect(() => otto.mint(deployer.address, 3)).to.changeTokenBalance(
        otto,
        deployer,
        3
      )
      await expect(
        otto.connect(badguy).set(
          'name',
          'desc',
          1, // tokenId
          12345, // birthday
          1, // traits
          2, // values
          6, // attrs
          7, // bonuses
          8 // flags
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
        'name',
        'desc',
        1, // tokenId
        12345, // birthday
        1, // traits
        2, // values
        6, // attrs
        7, // bonuses
        8 // flags
      )
      const [name, desc, ...got] = await otto.infos(1)
      expect(name).to.eq('name')
      expect(desc).to.eq('desc')
      // ignore mintAt & summonAt
      got.pop()
      got.pop()
      expect(got.map((e) => (e.toNumber ? e.toNumber() : e))).to.deep.eq([
        12345, // birthday
        1, // traits
        2, // values
        6, // attrs
        7, // bonuses
        8, // flags
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

    it('should able to encode and decode u8 u256 correctly', async function () {
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

  describe('OttoV2', function () {
    describe('summon period is not over', function () {
      it('should fail to openPortal if caller is not manager', async function () {
        await expect(otto.connect(badguy).openPortal(0, [1, 2, 3], false)).to.be
          .reverted
      })

      it('should fail to summon if caller is not manager', async function () {
        await expect(otto.connect(badguy).summon(0, 0, 0)).to.be.reverted
      })

      it('should fail to openPortal with invalid tokenId', async function () {
        await expect(otto.openPortal(0, [1, 2, 3], false)).to.be.revertedWith(
          'invalid tokenId'
        )
      })

      it('should fail to openPortal if summonPeriod is not over', async function () {
        await expect(() =>
          otto.mint(deployer.address, 1)
        ).to.changeTokenBalance(otto, deployer, 1)
        await expect(otto.openPortal(0, [1, 2, 3], false)).to.be.revertedWith(
          'summon period is not over'
        )
      })
    })

    describe('summon period is over', function () {
      it('should able to summon', async function () {
        await network.provider.send('evm_setNextBlockTimestamp', [
          new Date('2022-01-01T13:00:00Z').getTime() / 1000,
        ])
        await expect(() =>
          otto.mint(deployer.address, 2)
        ).to.changeTokenBalance(otto, deployer, 2)
        await network.provider.send('evm_mine')
        expect(await otto.exists(0)).to.eq(true)
        const ts = new Date('2022-01-08T13:00:00Z').getTime() / 1000
        expect(await otto.canSummonAt(0)).to.eq(ts)
        await network.provider.send('evm_setNextBlockTimestamp', [ts])
        await network.provider.send('evm_mine')

        await expect(otto.summon(0, 0, 0)).to.be.revertedWith(
          'portal is not open'
        )
        expect(await otto.portalStatus(0)).to.eq(0)
        expect(await otto.openPortal(0, [1, 2, 3], false))
          .to.emit(otto, 'PortalOpened')
          .withArgs(deployer.address, 0, [1, 2, 3], false)
        expect((await otto.candidates(0)).map((e) => e.toNumber())).to.deep.eq([
          1, 2, 3,
        ])
        expect(await otto.legendary(0)).to.eq(false)
        await expect(otto.openPortal(0, [1, 2, 3], false)).to.be.revertedWith(
          'portal is already opened'
        )
        expect(await otto.portalStatus(0)).to.eq(1)
        await expect(otto.summon(0, 3, 0)).to.be.revertedWith(
          'invalid candidate index'
        )
        expect(await otto.summon(0, 2, ts))
          .to.emit(otto, 'OttoSummoned')
          .withArgs(deployer.address, 0, 3, ts)
        expect(await otto.portalStatus(0)).to.eq(2)
        expect(await otto.candidates(0)).to.deep.eq([])
        await expect(otto.summon(0, 2, ts)).to.be.revertedWith(
          'portal is not opened or already summoned'
        )

        await expect(otto.openPortal(1, [1, 3], true)).to.be.revertedWith(
          'legendary otto can only have one candidate'
        )
        expect(await otto.openPortal(1, [3], true))
          .to.emit(otto, 'PortalOpened')
          .withArgs(deployer.address, 1, [3], true)
        expect(await otto.legendary(1)).to.eq(true)
      })
    })

    it('should able to encode and decode u16 u256 correctly', async function () {
      const arr = Array(16).fill(0)
      let n = 0
      expect(await otto.U16toU256(arr)).to.eq(n)
      expect(await otto.U256toU16(n)).to.deep.eq(arr)

      arr[0] = 1
      n = 1
      expect(await otto.U16toU256(arr)).to.eq(n)
      expect(await otto.U256toU16(n)).to.deep.eq(arr)

      arr[1] = 1
      n = 65537
      expect(await otto.U16toU256(arr)).to.eq(n)
      expect(await otto.U256toU16(n)).to.deep.eq(arr)

      arr[2] = 1
      n = 4295032833
      expect(await otto.U16toU256(arr)).to.eq(n)
      expect(await otto.U256toU16(n)).to.deep.eq(arr)

      arr[15] = 1
      n = BigNumber.from(
        '0x0001000000000000000000000000000000000000000000000000000100010001'
      )
      // 0x01000000000000000000000000000000000000000000000000000100010001
      expect(await otto.U16toU256(arr)).to.eq(n)
      expect(await otto.U256toU16(n)).to.deep.eq(arr)
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
      it('should able to get clamPerWETH', async function () {
        expect(await portalCreator.clamPerWETH()).to.eq(parseUnits('50', 9))
      })

      it('should fail to devMint if caller is not owner', async function () {
        await expect(
          portalCreator.connect(badguy).devMint(dao.address, 1)
        ).to.be.revertedWith('Ownable: caller is not the owner')
      })

      it('should fail to devMint 0 otto', async function () {
        await expect(portalCreator.devMint(dao.address, 0)).to.be.revertedWith(
          'devMint quantity must be greater than 0'
        )
      })

      it('should fail to devMint 5001 otto', async function () {
        await expect(
          portalCreator.devMint(dao.address, 5001)
        ).to.be.revertedWith('not enough tokens')
      })

      it('should fail to devMint more than 250 otto', async function () {
        await expect(
          portalCreator.devMint(dao.address, 251)
        ).to.be.revertedWith('not enough tokens for dev')
        await expect(() =>
          portalCreator.devMint(dao.address, 1)
        ).to.changeTokenBalance(otto, dao, 1)
        await expect(
          portalCreator.devMint(dao.address, 250)
        ).to.be.revertedWith('not enough tokens for dev')
      })
      ;[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 250].forEach(function (n) {
        it(`should be able to give ${n} ottos away`, async function () {
          await expect(() =>
            portalCreator.devMint(dao.address, n)
          ).to.changeTokenBalance(otto, dao, n)
          expect(await portalCreator.devCanMint()).to.eq(250 - n)
        })
      })

      it('should fail to addOttolisted if caller is not owner', async function () {
        await expect(
          portalCreator.connect(badguy).addOttolisted(1, [dao.address])
        ).to.be.revertedWith('Ownable: caller is not the owner')
      })

      it('should fail to setOttolisted if caller is not owner', async function () {
        await expect(
          portalCreator.connect(badguy).setOttolisted(1, [dao.address])
        ).to.be.revertedWith('Ownable: caller is not the owner')
      })

      it('should able to set or add ottolisted', async function () {
        await portalCreator.setOttolisted(3, [dao.address, deployer.address])
        expect(await portalCreator.ottolisted(dao.address)).to.eq(3)
        expect(await portalCreator.ottolisted(deployer.address)).to.eq(3)
        await portalCreator.addOttolisted(2, [dao.address, deployer.address])
        expect(await portalCreator.ottolisted(dao.address)).to.eq(5)
        expect(await portalCreator.ottolisted(deployer.address)).to.eq(5)
        await portalCreator.setOttolisted(1, [dao.address, deployer.address])
        expect(await portalCreator.ottolisted(dao.address)).to.eq(1)
        expect(await portalCreator.ottolisted(deployer.address)).to.eq(1)
      })

      it('should able to addOttolisted twice', async function () {
        await portalCreator.addOttolisted(3, [dao.address])
        await portalCreator.addOttolisted(3, [dao.address])
        expect(await portalCreator.ottolisted(dao.address)).to.eq(6)
      })

      it('should fail to adjustSaleConfig if caller is not owner', async function () {
        await expect(
          portalCreator.connect(badguy).adjustSaleConfig(0, 123, 456)
        ).to.be.revertedWith('Ownable: caller is not the owner')
      })

      it('should able to adjustSaleConfig', async function () {
        await portalCreator.adjustSaleConfig(0, 111, 123)
        let cfg = await portalCreator.saleConfig(0)
        expect(cfg.timestamp).to.eq(111)
        expect(cfg.price).to.eq(123)
        await portalCreator.adjustSaleConfig(1, 222, 456)
        cfg = await portalCreator.saleConfig(1)
        expect(cfg.timestamp).to.eq(222)
        expect(cfg.price).to.eq(456)
        await portalCreator.adjustSaleConfig(2, 333, 789)
        cfg = await portalCreator.saleConfig(2)
        expect(cfg.timestamp).to.eq(333)
        expect(cfg.price).to.eq(789)
        await expect(portalCreator.saleConfig(3)).to.be.reverted
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
      before(async function () {
        await network.provider.send('evm_setNextBlockTimestamp', [
          new Date('2022-03-18T13:00:00Z').getTime() / 1000,
        ])
        await network.provider.send('evm_mine')
      })

      it('price in weth', async function () {
        expect(await portalCreator.priceInWETH()).to.eq(parseEther('0.06'))
      })

      it('should fail to mint when sale not started yet', async function () {
        await expect(
          portalCreator.mint(deployer.address, 1, 123, false)
        ).to.be.revertedWith('sale not started yet')
      })
    })

    describe('PRE_SALE', function () {
      before(async function () {
        await network.provider.send('evm_setNextBlockTimestamp', [
          new Date('2022-03-19T13:00:00Z').getTime() / 1000,
        ])
        await network.provider.send('evm_mine')
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
          await portalCreator.addOttolisted(3, [deployer.address])
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
      before(async function () {
        await network.provider.send('evm_setNextBlockTimestamp', [
          new Date('2022-03-20T13:00:00Z').getTime() / 1000,
        ])
        await network.provider.send('evm_mine')
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
