const { ethers } = require('hardhat')

async function main() {
  const PAW = await ethers.getContractFactory('OtterPAW')

  const pawParams = [
    [
      'Safe-Hand Otter',
      'SAFE',
      'https://gateway.pinata.cloud/ipfs/QmeQ9MCnAqq3HtvKWmSecSTLiUNj7QiT2uNtRm2Ln4BrvH',
    ],
    [
      'Furry-Hand Otter',
      'FURRY',
      'https://gateway.pinata.cloud/ipfs/QmWAzMkpNgJi7k7xkzgjLJneuhtxjziDP86oooA9dJf9Tx',
    ],
    [
      'Stone-Hand Otter',
      'STONE',
      'https://gateway.pinata.cloud/ipfs/QmXS3MVLv7kbtHCr6CiNkakcpJr99odbpEaicfxb74rKSQ',
    ],
    [
      'Diamond-Hand Otter',
      'DIAMOND',
      'https://gateway.pinata.cloud/ipfs/QmNoj7fEjEEh2upJgLcNMRVesAsE84wAREDBVKuPWaGFeT',
    ],
  ]

  for (const params of pawParams) {
    console.log(`deploy ${params[0]}`)
    const paw = await PAW.deploy(...params)
    console.log(`wait for ${params[0]}`)
    await paw.deployTransaction.wait()
    console.log(
      `please verify '${paw.address}' ${params.map((e) => `'${e}'`).join(' ')}`
    )
  }
}

main()
  .then(() => process.exit())
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
