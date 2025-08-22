// const HDWalletProvider = require('@truffle/hdwallet-provider');
try {
  require('dotenv').config();
} catch (error) {
  // dotenv not installed, using default values
}

// Mnemonic for development (DO NOT use in production)
const MNEMONIC = process.env.MNEMONIC || 'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

module.exports = {
  networks: {
    // Development network (Ganache)
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*", // Match any network id
      gas: 12000000,
      gasPrice: 20000000000, // 20 gwei
      confirmations: 0,
      timeoutBlocks: 200,
      skipDryRun: true
    },

    // Ganache CLI
    ganache: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*",
      gas: 12000000,
      gasPrice: 20000000000,
      confirmations: 0,
      timeoutBlocks: 200,
      skipDryRun: true
    },

    // Local development with custom settings
    local: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "5777", // Ganache default
      gas: 12000000,
      gasPrice: 20000000000,
      confirmations: 0,
      timeoutBlocks: 200,
      skipDryRun: true,
      websockets: true
    },

    // Ethereum Goerli Testnet (uncomment when HDWalletProvider is installed)
    // goerli: {
    //   provider: () => new HDWalletProvider(
    //     MNEMONIC,
    //     `https://goerli.infura.io/v3/${process.env.INFURA_PROJECT_ID}`
    //   ),
    //   network_id: 5,
    //   gas: 8000000,
    //   gasPrice: 20000000000,
    //   confirmations: 2,
    //   timeoutBlocks: 200,
    //   skipDryRun: true
    // },

    // Ethereum Sepolia Testnet (uncomment when HDWalletProvider is installed)
    // sepolia: {
    //   provider: () => new HDWalletProvider(
    //     MNEMONIC,
    //     `https://sepolia.infura.io/v3/${process.env.INFURA_PROJECT_ID}`
    //   ),
    //   network_id: 11155111,
    //   gas: 8000000,
    //   gasPrice: 20000000000,
    //   confirmations: 2,
    //   timeoutBlocks: 200,
    //   skipDryRun: true
    // },

    // Polygon Mumbai Testnet (uncomment when HDWalletProvider is installed)
    // mumbai: {
    //   provider: () => new HDWalletProvider(
    //     MNEMONIC,
    //     `https://polygon-mumbai.infura.io/v3/${process.env.INFURA_PROJECT_ID}`
    //   ),
    //   network_id: 80001,
    //   gas: 8000000,
    //   gasPrice: 20000000000,
    //   confirmations: 2,
    //   timeoutBlocks: 200,
    //   skipDryRun: true
    // },

    // Polygon Mainnet (uncomment when HDWalletProvider is installed)
    // polygon: {
    //   provider: () => new HDWalletProvider(
    //     MNEMONIC,
    //     `https://polygon-mainnet.infura.io/v3/${process.env.INFURA_PROJECT_ID}`
    //   ),
    //   network_id: 137,
    //   gas: 8000000,
    //   gasPrice: 30000000000, // 30 gwei
    //   confirmations: 2,
    //   timeoutBlocks: 200,
    //   skipDryRun: true
    // }
  },

  // Set default mocha options here, use special reporters etc.
  mocha: {
    timeout: 100000,
    reporter: 'spec',
    useColors: true
  },

  // Configure your compilers
  compilers: {
    solc: {
      version: "0.8.19", // Fetch exact version from solc-bin
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        },
        viaIR: true,
        evmVersion: "istanbul"
      }
    }
  },

  // Plugins
  plugins: [
    'truffle-plugin-verify',
    'solidity-coverage'
  ],

  // API keys for contract verification
  api_keys: {
    etherscan: process.env.ETHERSCAN_API_KEY,
    polygonscan: process.env.POLYGONSCAN_API_KEY
  },

  // Database configuration
  db: {
    enabled: false
  },

  // Dashboard configuration
  dashboard: {
    port: 24012,
    host: "localhost"
  }
};