const { ethers, upgrades } = require('hardhat')

async function main() {
  let ottoArgs = [
    'Otto', // name
    'OTTO', // symbol
    '6', // maxBatchSize
    '5000', // collectionSize
  ]
  let OTTO = await ethers.getContractFactory('Otto')
  let otto = await upgrades.deployProxy(OTTO, ottoArgs, { kind: 'uups' })
  await otto.deployed()
  let ottoImplAddr = await upgrades.erc1967.getImplementationAddress(
    otto.address
  )
  console.log('otto: ', otto.address)
  console.log('ottoImpl: ', ottoImplAddr)

  let portalCreatorArgs = [
    otto.address, // OTTO
    '0x7ceb23fd6bc0add59e62ac25578270cff1b9f619', // WETH
    '0x1581802317f32A2665005109444233ca6E3e2D68', // MAI-CLAM LP
    '0xf9680d99d6c9589e2a93a78a04a279e509205945', // WETH ORACLE
    '0x8ce47D56EAa1299d3e06FF3E04637449fFb01C9C', // TREASURY
    '0x929A27c46041196e1a49C7B459d63eC9A20cd879', // DAO
  ]
  let PORTALCREATOR = await ethers.getContractFactory('OttopiaPortalCreator')
  let portalCreator = await upgrades.deployProxy(
    PORTALCREATOR,
    portalCreatorArgs,
    { kind: 'uups' }
  )
  await portalCreator.deployed()
  let portalCreatorImplAddr = await upgrades.erc1967.getImplementationAddress(
    portalCreator.address
  )
  console.log('portal: ', portalCreator.address)
  console.log('portalImpl: ', portalCreatorImplAddr)

  console.log(`yarn hardhat verify ${ottoImplAddr} "${ottoArgs.join(' ')}"`)
  console.log(
    `yarn hardhat verify ${portalCreatorImplAddr} "${portalCreatorArgs.join(
      ' '
    )}"`
  )
}

main()
  .then(() => process.exit())
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
