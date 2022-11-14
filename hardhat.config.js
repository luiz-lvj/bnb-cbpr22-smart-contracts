require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.17",
  networks: {
    localhost: {
      url: "http://localhost:8545"
    },
    localhost2: {
      url: "http://localhost:8546"
    }
  }
};
