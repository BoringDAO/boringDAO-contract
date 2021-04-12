const { network, ethers } = require("hardhat");

// deploy/00_deploy_my_contract.js
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, get } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log(`Deployer(${deployer}), Network(${network.name})`);

  switch (network.name) {
    case "localhost":
      const addressResolver = await get("AddressResolver");
      await deploy("Liquidation", {
        from: deployer,
        args: [deployer, addressResolver.address, ethers.utils.formatBytes32String("BTC")],
        log: true,
      });
    case "bsc_test":
      await deploy("Liquidation", {
        from: deployer,
        args: [deployer, addressResolver.address, ethers.utils.formatBytes32String("BTC")],
        log: true,
      });
  }
};

module.exports.tags = ["Liquidation"];
