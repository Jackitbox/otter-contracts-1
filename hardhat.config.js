require('@nomiclabs/hardhat-waffle')
require('@nomiclabs/hardhat-etherscan')
require('@atixlabs/hardhat-time-n-mine')
require('@openzeppelin/hardhat-upgrades')

require('dotenv').config()

const { ethers } = require('ethers')
const dev = process.env.DEV_PRIVATE_KEY
const deployer = process.env.DEPLOYER_PRIVATE_KEY
const etherscanApiKey = process.env.ETHERSCAN_API_KEY
const polygonMainnetRPC =
  process.env.POLYGON_MAINNET_RPC || 'https://polygon-rpc.com'
const polygonMumbaiRPC =
  process.env.POLYGON_MUMBAI_RPC || 'https://rpc-mumbai.maticvigil.com/'
const chainId = Number(process.env.FORK_CHAIN_ID) || 31337

module.exports = {
  solidity: {
    compilers: [
      {
        version: '0.8.9',
      },
      {
        version: '0.7.5',
      },
      {
        version: '0.6.6',
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
    ],
  },
  networks: {
    'polygon-mainnet': {
      url: polygonMainnetRPC,
      accounts: deployer ? [deployer] : deployer,
      gasPrice: ethers.utils.parseUnits('50', 'gwei').toNumber(),
    },
    'polygon-mumbai': {
      url: polygonMumbaiRPC,
      accounts: dev ? [dev] : dev,
      gas: 'auto',
      gasPrice: ethers.utils.parseUnits('1.2', 'gwei').toNumber(),
    },
    'otterclam-fork': {
      url: 'https://fork-rpc.otterclam.finance',
      gas: 'auto',
    },
    hardhat: {
      chainId,
      gas: 'auto',
      forking:
        process.env.NODE_ENV === 'test'
          ? undefined
          : { url: polygonMainnetRPC },
    },
  },
  etherscan: {
    apiKey: etherscanApiKey,
  },
  mocha: {
    timeout: 5 * 60 * 10000,
  },
}
