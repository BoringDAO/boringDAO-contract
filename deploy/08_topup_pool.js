
const { parseEther } = require("@ethersproject/units");
const {
    network,
    ethers,
    getNamedAccounts
} = require("hardhat");


module.exports = async ({
    getNamedAccounts,
    deployments
}) => {
    const {
        deploy,
        run,
        execute,
        get
    } = deployments;

    const {
        deployer_addr,
        user1,
        user2
    } = await getNamedAccounts();

    const [deployer,] = await ethers.getSigners()
    console.log(`deployer ${deployer.address} in ${network.name}`)

    switch (network.name) {
        case "mainnet":
            // await get("StakingRewardsLockPPTDOGE")
            const ppt_addr = (await get("StakingRewardsLockPPTDOGE")).address
            const bor = await ethers.getContractAt("Bor", "0x3c9d6c1C73b31c837832c72E04D3152f051fc1A9")

            // await bor.transfer(ppt_addr, parseEther("28"))
            // await execute("StakingRewardsLockPPTDOGE", {
            //     "from": deployer.address,
            //     "log": true,
            // }, "notifyRewardAmount", parseEther("28"), 24*3600*14)

            const odoge_addr = (await get("StakingRewardsLockODOGE")).address
            // await bor.transfer(odoge_addr, parseEther("14"))
            await execute("StakingRewardsLockODOGE", {
                "from": deployer.address,
                "log": true,
            }, "notifyRewardAmount", parseEther("14"), 24*3600*14)


            break;
        default:
            console.log("not known network")
    }
}

module.exports.tags = ["08"]