const { ethers } = require('hardhat')

const PEARL_ADDRESS = '0x52A7F40BB6e9BD9183071cdBdd3A977D713F2e34'
const LAKE_ADDRESS = '0xAaC7D4A36DAb95955ef3c641c23F1fA46416CF71'
// testnet
//const PEARL_ADDRESS = '0x19907af68A173080c3e05bb53932B0ED541f6d20'
//const LAKE_ADDRESS = '0x252f672EbeCBF8c3952eD79cDf300e293b3F4866'

async function main() {
  const notes = [
    {
      name: 'Safe-Hand 14 Days Note',
      symbol: 'SAFE14',
      baseURI: 'https://api.otterclam.finance/pearl_notes/metadata/',
      lockPeriod: 14 * 3,
      multiplier: 100,
      minAmount: 0,
    },
    {
      name: 'Safe-Hand 28 Days Note',
      symbol: 'SAFE28',
      baseURI: 'https://api.otterclam.finance/pearl_notes/metadata/',
      lockPeriod: 28 * 3,
      multiplier: 110,
      minAmount: 0,
    },
    {
      name: 'Safe-Hand 90 Days Note',
      symbol: 'SAFE90',
      baseURI: 'https://api.otterclam.finance/pearl_notes/metadata/',
      lockPeriod: 90 * 3,
      multiplier: 135,
      minAmount: 0,
    },
    {
      name: 'Safe-Hand 180 Days Note',
      symbol: 'SAFE180',
      baseURI: 'https://api.otterclam.finance/pearl_notes/metadata/',
      lockPeriod: 180 * 3,
      multiplier: 200,
      minAmount: 0,
    },
    {
      name: 'Furry-Hand 28 Days Note',
      symbol: 'FURRY28',
      baseURI: 'https://api.otterclam.finance/pearl_notes/metadata/',
      lockPeriod: 28 * 3,
      multiplier: 110,
      minAmount: 50,
    },
    {
      name: 'Stone-Hand 90 Days Note',
      symbol: 'STONE90',
      baseURI: 'https://api.otterclam.finance/pearl_notes/metadata/',
      lockPeriod: 90 * 3,
      multiplier: 135,
      minAmount: 50,
    },
    {
      name: 'Diamond-Hand 180 Days',
      symbol: 'DIAMOND180',
      baseURI: 'https://api.otterclam.finance/pearl_notes/metadata/',
      lockPeriod: 180 * 3,
      multiplier: 200,
      minAmount: 50,
    },
  ]

  const Note = await ethers.getContractFactory('PearlNote')
  const Lake = await ethers.getContractFactory('OtterLake')
  const lake = Lake.attach(LAKE_ADDRESS)

  for (let {
    name,
    symbol,
    baseURI,
    lockPeriod,
    multiplier,
    minAmount,
  } of notes) {
    let note = await Note.deploy(
      name,
      symbol,
      baseURI,
      PEARL_ADDRESS,
      LAKE_ADDRESS
    )
    await note.deployTransaction.wait()
    await lake.addTerm(
      note.address,
      ethers.utils.parseEther(String(minAmount)),
      lockPeriod,
      multiplier
    )

    console.log(`Note ${await note.name()} deployed at: ${note.address}`)
  }

  // await hre.run('verify:verify', {
  //   address: bond.address,
  //   constructorArguments: [
  //     addresses.CLAM_ADDRESS,
  //     addresses.sCLAM_ADDRESS,
  //     reserveAddr,
  //     addresses.TREASURY_ADDRESS,
  //     daoAddr,
  //     addresses.STAKING_ADDRESS,
  //     oracleAddr,
  //   ],
  // })
}

main()
  .then(() => console.log('done'))
  .catch((err) => console.error(err))
