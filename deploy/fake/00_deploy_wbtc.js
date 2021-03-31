const { network } = require("hardhat");

// deploy/00_deploy_my_contract.js
module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log(`Deployer(${deployer}), Network(${network.name})`);

  await deploy("FakeWBTC", {
    from: deployer,
    args: ["Wrapped BTC", "WBTC"],
    log: true,
  });
};

module.exports.tags = ["FakeWBTC"];
