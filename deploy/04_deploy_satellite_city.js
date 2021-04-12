const { network, ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, execute, get } = deployments;

  const height = await ethers.provider.getBlockNumber();
  const { deployer } = await getNamedAccounts();
  console.log(`Deployer(${deployer}), Network(${network.name}), Height(${height})`);

  switch (network.name) {
    case "localhost":
      const bor = await get("Bor");
      const oracle = await get("Oracle");
      const Liquidation = await get("Liquidation");

      await deploy("SatelliteCity", {
        from: deployer,
        args: [bor.address, 3, height, oracle.address, Liquidation.address],
        log: true,
      });
    case "bsc_test":
      const borAddress = "0x4261bb282EB6bb678A693B4684DBdD07a0d3D245";
      const oracleAddress = "0x93eF5889DB8B3bbe9158ac97e49b5EE653907f1A";
      const liquidationAddress = "0x1F04bb02575A1fCfEb8eec148beeD36F1E5E03E1";

      await deploy("SatelliteCity", {
        from: deployer,
        args: [borAddress, 3, height, oracleAddress, liquidationAddress],
        log: true,
      });

      await execute("SatelliteCity", { from: deployer, log: true }, "setDispatcher", deployer);
  }
};

module.exports.tags = ["SatelliteCity"];
