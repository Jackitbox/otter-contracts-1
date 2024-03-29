require('@nomiclabs/hardhat-waffle')
require('@nomiclabs/hardhat-etherscan')
require('@atixlabs/hardhat-time-n-mine')
require('@openzeppelin/hardhat-upgrades')

require('dotenv').config()

const fs = require('fs')
const files = fs.readdirSync('./tasks')
for (const file of files) {
  require('./tasks/' + file)
}

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
        settings: {
          outputSelection: {
            '*': {
              '*': ['storageLayout'],
            },
          },
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: '0.7.5',
        settings: {
          outputSelection: {
            '*': {
              '*': ['storageLayout'],
            },
          },
        },
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
      gasPrice: ethers.utils.parseUnits('70', 'gwei').toNumber(),
      timeout: 120000,
    },
    'polygon-mumbai': {
      url: polygonMumbaiRPC,
      accounts: dev ? [dev] : dev,
      gas: 'auto',
      gasPrice: ethers.utils.parseUnits('2', 'gwei').toNumber(),
    },
    'otterclam-fork': {
      url: 'https://fork-rpc.otterclam.finance',
      gas: 'auto',
      accounts: deployer ? [deployer] : [],
    },
    hardhat: {
      chainId,
      gas: 'auto',
      initialDate:
        process.env.NODE_ENV === 'test' ? '2021-11-02T00:00:00Z' : undefined,
      forking:
        process.env.NODE_ENV === 'test'
          ? undefined
          : { url: polygonMainnetRPC },
    },
    localhost: {
      accounts: deployer ? [deployer] : [],
      timeout: 120000,
    },
  },
  etherscan: {
    apiKey: etherscanApiKey,
  },
  mocha: {
    timeout: 5 * 60 * 10000,
  },
}
