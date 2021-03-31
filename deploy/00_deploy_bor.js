const { network } = require("hardhat");

// deploy/00_deploy_my_contract.js
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log(`Deployer(${deployer}), Network(${network.name})`);

  await deploy("Bor", {
    from: deployer,
    args: [deployer],
    log: true,
  });
};

module.exports.tags = ["Bor"];
