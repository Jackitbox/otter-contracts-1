const { ethers, upgrades } = require('hardhat')

async function main() {
  let ottoAddr = '0x6e8A9Cb6B1E73e9fCe3FD3c68b5af9728F708eB7'
  let OTTO = await ethers.getContractFactory('Otto')
  let OTTOV2 = await ethers.getContractFactory('OttoV2')
  await upgrades.forceImport(ottoAddr, OTTO)
  let otto = await upgrades.upgradeProxy(ottoAddr, OTTOV2, {
    kind: 'uups',
    call: {
      fn: 'setOpenPeriod',
      args: [7 * 24 * 60 * 60],
    },
    unsafeSkipStorageCheck: true,
  })
  const total = await otto.totalSupply()
  const chunk = 200
  const times = Math.floor(total / chunk)
  const ts = new Date('2022-04-06T13:00:00Z').getTime() / 1000

  for (let i = 0; i <= times; i++) {
    const n = i == times ? total % chunk : chunk
    if (n > 0) {
      const ids = Array(n)
        .fill(0)
        .map((_, index) => index + i * chunk)
      console.log(`${i}/${times}: setCanOpenAt(${ts}, ${ids})`)
      await otto.setCanOpenAt(ts, ids)
    }
  }
  console.log(`address: ${otto.address}`)
}

main()
  .then(() => process.exit())
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
