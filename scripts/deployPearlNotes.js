const { ethers } = require('hardhat')

// mainnet
const PEARL_ADDRESS = '0x52A7F40BB6e9BD9183071cdBdd3A977D713F2e34'
const LAKE_ADDRESS = '0xc67aBdA25D0421FE9Dc1afd64183b179A426a256'
const BASE_URI = 'https://api.otterclam.finance/pearl_notes/metadata/'
// testnet
// const PEARL_ADDRESS = '0x52A7F40BB6e9BD9183071cdBdd3A977D713F2e34'
// const LAKE_ADDRESS = '0x2fe19128A8257182fdD77f90eA96D27cA342897A'
// const BASE_URI = 'https://otter-api-pr-11.herokuapp.com/pearl_notes/metadata/'

async function main() {
  const notes = [
    {
      name: 'Safe-Hand 14-Day Note',
      symbol: 'SAFE14',
      baseURI: BASE_URI,
      lockPeriod: 14 * 3,
      multiplier: 100,
      minAmount: 0,
    },
    {
      name: 'Safe-Hand 28-Day Note',
      symbol: 'SAFE28',
      baseURI: BASE_URI,
      lockPeriod: 28 * 3,
      multiplier: 110,
      minAmount: 0,
    },
    {
      name: 'Safe-Hand 90-Day Note',
      symbol: 'SAFE90',
      baseURI: BASE_URI,
      lockPeriod: 90 * 3,
      multiplier: 135,
      minAmount: 0,
    },
    {
      name: 'Safe-Hand 180-Day Note',
      symbol: 'SAFE180',
      baseURI: BASE_URI,
      lockPeriod: 180 * 3,
      multiplier: 200,
      minAmount: 0,
    },
    {
      name: 'Furry-Hand 28-Day Note',
      symbol: 'FURRY28',
      baseURI: BASE_URI,
      lockPeriod: 28 * 3,
      multiplier: 110,
      minAmount: 50,
    },
    {
      name: 'Stone-Hand 90-Day Note',
      symbol: 'STONE90',
      baseURI: BASE_URI,
      lockPeriod: 90 * 3,
      multiplier: 135,
      minAmount: 50,
    },
    {
      name: 'Diamond-Hand 180-Day Note',
      symbol: 'DIAMOND180',
      baseURI: BASE_URI,
      lockPeriod: 180 * 3,
      multiplier: 200,
      minAmount: 50,
    },
  ]

  const Note = await ethers.getContractFactory('PearlNote')
  const Lake = await ethers.getContractFactory('OtterLake')
  const lake = Lake.attach(LAKE_ADDRESS)

  // for (let {
  //   name,
  //   symbol,
  //   baseURI,
  //   lockPeriod,
  //   multiplier,
  //   minAmount,
  // } of notes) {
  //   let note = await Note.deploy(
  //     name,
  //     symbol,
  //     baseURI,
  //     PEARL_ADDRESS,
  //     LAKE_ADDRESS
  //   )
  //   await note.deployTransaction.wait()

  //   const tx = await lake.addTerm(
  //     note.address,
  //     ethers.utils.parseEther(String(minAmount)),
  //     lockPeriod,
  //     multiplier
  //   )
  //   await tx.wait()

  //   console.log(`Note ${await note.name()} deployed at: ${note.address}`)
  // }

  await hre.run('verify:verify', {
    address: '0xC713af03353710EA37DF849237E32a936a63cBbd',
    constructorArguments: [
      notes[0].name,
      notes[0].symbol,
      notes[0].baseURI,
      PEARL_ADDRESS,
      LAKE_ADDRESS,
    ],
  })
}

main()
  .then(() => console.log('done'))
  .catch((err) => console.error(err))
