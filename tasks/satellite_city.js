task("satelliteCity", "Interact with SatelliteCity contract").setAction(async (args, hre) => {
  const SatelliteCity = await hre.ethers.getContractFactory("SatelliteCity");
  const satelliteCity = SatelliteCity.attach("0xa3c63d5edb827c34028c4e59acD6a4A3B871B682");

  console.log(`Network(${hre.network.name})`);
  console.log(`SatelliteCity: ${satelliteCity.address}`);

  const poolInfoLength = await satelliteCity.poolLength();
  console.log(`borToken: ${await satelliteCity.borToken()}`);
  console.log(`borTokenPerBlock: ${await satelliteCity.borTokenPerBlock()}`);
  console.log(`poolInfo length: ${poolInfoLength}`);
  console.log(`tvl: ${await satelliteCity.satelliteTVL()}`);
  console.log(`totalAllocPoint: ${await satelliteCity.totalAllocPoint()}`);

  console.log(`========POOL=======`);
  for (let i = 0; i < poolInfoLength; i++) {
    const poolInfo = await satelliteCity.poolInfo(i);

    console.log(`pool${i}:`);
    console.log(
      `   isSingle: ${poolInfo.isSingle}, lpToken: ${poolInfo.lpToken}, allocPoint: ${poolInfo.allocPoint}, lastRewardBlock: ${poolInfo.lastRewardBlock}, accTokenPerShare: ${poolInfo.accTokenPerShare} `
    );
    if (poolInfo.isSingle) {
      const Token = await hre.ethers.getContractFactory("BaseToken");
      const token = Token.attach(poolInfo.lpToken);
      console.log(`   ${await token.symbol()}`);
    } else {
      const Pair = await hre.ethers.getContractFactory("IPair");
      const pair = Pair.attach(poolInfo.lpToken);
    }
  }
});

module.exports = {};
