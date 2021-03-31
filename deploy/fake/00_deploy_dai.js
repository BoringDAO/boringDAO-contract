const { network, ethers } = require("hardhat");

// deploy/00_deploy_my_contract.js
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log(`Deployer(${deployer}), Network(${network.name})`);

  await deploy("FakeDAI", {
    from: deployer,
    args: ["DAI Stable coin", "DAI"],
    log: true,
  });
};

module.exports.tags = ["FakeDAI"];
