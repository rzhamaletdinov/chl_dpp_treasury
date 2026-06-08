require("@nomicfoundation/hardhat-toolbox");
require("@openzeppelin/hardhat-upgrades");
require("dotenv").config();

const { BSC_RPC_URL, BSC_TESTNET_RPC_URL, PRIVATE_KEY, BSCSCAN_API_KEY } =
  process.env;

const accounts = PRIVATE_KEY ? [PRIVATE_KEY] : [];

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.17",
    settings: {
      optimizer: {
        enabled: false,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {},
    bsc: {
      url: BSC_RPC_URL || "https://bsc-dataseed.binance.org",
      chainId: 56,
      accounts,
    },
    bscTestnet: {
      url:
        BSC_TESTNET_RPC_URL ||
        "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts,
    },
  },
  etherscan: {
    apiKey: {
      bsc: BSCSCAN_API_KEY || "",
      bscTestnet: BSCSCAN_API_KEY || "",
    },
  },
};
