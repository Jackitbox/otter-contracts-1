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
  console.log('otto: ', otto.address)
  let ottoImplAddr = await upgrades.erc1967.getImplementationAddress(
    otto.address
  )
  console.log('ottoImpl: ', ottoImplAddr)

  let portalCreatorArgs = [
    otto.address, // OTTO
    '0x062f24cb618e6ba873ec1c85fd08b8d2ee9bf23e', // WETH
    '0x578cEa575734D4d3A3Fb68872e41535746E375bE', // MAI-CLAM LP
    '0x0715A7794a1dc8e42615F059dD6e406A6594651A', // WETH ORACLE
    '0x8F2FA71aa0BC9CEde830e0A2410a06cDDaff20D4', // TREASURY
    '0x8F2FA71aa0BC9CEde830e0A2410a06cDDaff20D4', // DAO
  ]
  let PORTALCREATOR = await ethers.getContractFactory('OttopiaPortalCreator')
  let portalCreator = await upgrades.deployProxy(
    PORTALCREATOR,
    portalCreatorArgs,
    { kind: 'uups' }
  )
  await portalCreator.deployed()
  console.log('portal: ', portalCreator.address)
  let portalCreatorImplAddr = await upgrades.erc1967.getImplementationAddress(
    portalCreator.address
  )
  console.log('portalImpl: ', portalCreatorImplAddr)

  console.log(`yarn hardhat verify ${ottoImplAddr}`)
  console.log(`yarn hardhat verify ${portalCreatorImplAddr}"`)
}

main()
  .then(() => process.exit())
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
