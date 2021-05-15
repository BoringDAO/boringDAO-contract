const { network, ethers } = require("hardhat");
const {
    formatBytes32String,
    formatEther,
    parseEther
} = require("ethers/lib/utils")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, run, execute } = deployments;
    const { deployer } = await getNamedAccounts();
    bor_addr = ""
    obtc_addr = ""
    console.log(`${deployer} in ${network.name}`)
    switch (network.name) {
        case "matic_test":
            let result = await deploy("Bor", {
                from: deployer,
                args: [deployer],
                log: true
            })
            let result_obtc = await deploy("obtc", {
                from: deployer,
                contract: "OToken",
                args: ["obtc", "obtc", 18, deployer],
                log: true
            })
            bor_addr = result.address
            obtc_addr = result_obtc.address
            break
        case "matic":
            bor_addr = "0x7d8c139d5bfBafdfD1D2D0284e7fC862babE4137"
            obtc_addr = "0x90fB380DdEbAF872cc1F8d8e8C604Ff2f4697c19"
            break
    }
    // await deploy("StakingRewardsLockBorMatic", {
    //     from: deployer,
    //     contract: "StakingRewardsLock",
    //     args: [deployer, bor_addr, oDOGEResult.address, 90 * 24 * 3600, 50, 50],
    //     log: true
    // })
    const srl_result = await deploy("StakingRewardsLockoBTCMatic", {
        from: deployer,
        contract: "StakingRewardsLock",
        args: [deployer, bor_addr, obtc_addr, 90 * 24 * 3600, 50, 50],
        log: true
    })

    const bor = await ethers.getContractAt("Bor", "0x7d8c139d5bfBafdfD1D2D0284e7fC862babE4137")
    // await bor.transfer(srl_result.address, parseEther("7"))
    // await execute("StakingRewardsLockoBTCMatic", {
    //     "from": deployer,
    //     "log": true,
    // }, "notifyRewardAmount", parseEther("7"), 24 * 3600 * 7)

    await deploy("OracleV2", {
        from: deployer,
        log: true
    })
    await execute("OracleV2", {
        from: deployer,
        log: true},
        "setMultiPrice", ["BTC", "BOR"].map(formatBytes32String), ["58117", "618"].map(parseEther)
    )
}

module.exports.tags = ["10"]