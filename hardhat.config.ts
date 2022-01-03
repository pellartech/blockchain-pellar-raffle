import { config } from 'dotenv'

import '@nomiclabs/hardhat-etherscan'
import '@nomiclabs/hardhat-waffle'
import 'hardhat-gas-reporter'
import 'solidity-coverage'
import '@typechain/hardhat'
import '@nomiclabs/hardhat-ethers'

config()

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: '0.8.9',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      initialBaseFeePerGas: 0,
      blockGasLimit: 30000000,
      allowUnlimitedContractSize: true,
      accounts: require('./accounts.json'),
    },
    polygon: {
      url: process.env.POLYGON_FULLNODE_URL,
      accounts: [process.env.POLYGON_PRIVATE_KEY],
    },
    rinkeby: {
      url: process.env.RINKEBY_FULLNODE_URL,
      accounts: [process.env.RINKEBY_PRIVATE_KEY],
    },
    // mainnet: {
    //   url: process.env.MAINNET_FULLNODE_URL,
    //   accounts: [process.env.MAINNET_PRIVATE_KEY],
    // },
  },
  mocha: {
    timeout: 200000
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: 'USD',
  },
  etherscan: {
    apiKey: process.env.SCAN_API_KEY,
  }
}
