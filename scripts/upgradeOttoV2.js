const { ethers, upgrades } = require('hardhat')

async function main() {
  let ottoAddr = '0x6e8A9Cb6B1E73e9fCe3FD3c68b5af9728F708eB7'
  let OTTO = await ethers.getContractFactory('Otto')
  let OTTOV2 = await ethers.getContractFactory('OttoV2')
  await upgrades.forceImport(ottoAddr, OTTO)
  let upgraded = await upgrades.upgradeProxy(ottoAddr, OTTOV2, {
    kind: 'uups',
    call: {
      fn: 'setOpenPeriod',
      args: [7 * 24 * 60 * 60],
    },
    unsafeSkipStorageCheck: true,
  })
  console.log(`otto proxy: ${ottoAddr}, impl: ${upgraded.address}`)
}

main()
  .then(() => process.exit())
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
