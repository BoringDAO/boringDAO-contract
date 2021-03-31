const { network, ethers } = require("hardhat");

// deploy/00_deploy_my_contract.js
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, get } = deployments;
  const { deployer } = await getNamedAccounts();

  console.log(`Deployer(${deployer}), Network(${network.name})`);

  await deploy("AddressResolver", {
    from: deployer,
    log: true,
  });
};

module.exports.tags = ["AddressResolver"];
