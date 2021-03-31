const { network, ethers } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { execute, get } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log(`Deployer(${deployer}), Network(${network.name})`);

  if (network.name == "localhost") {
    const fakeDAI = await get("FakeWBTC");
    const fakeWBTC = await get("FakeWBTC");

    await execute("SatelliteCity", { from: deployer, log: true }, "addPool", true, 200, fakeDAI.address, false);
    await execute("SatelliteCity", { from: deployer, log: true }, "addPool", true, 100, fakeWBTC.address, false);
  }

  if (network.name == "bsc_test") {
    const fakeDAI = await get("FakeWBTC");
    const fakeWBTC = await get("FakeWBTC");

    await execute("SatelliteCity", { from: deployer, log: true }, "addPool", true, 200, fakeDAI.address, false);
    await execute("SatelliteCity", { from: deployer, log: true }, "addPool", true, 100, fakeWBTC.address, false);
  }
};

module.exports.tags = ["AddPool"];
