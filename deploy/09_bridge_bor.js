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

    const {deployer} = await getNamedAccounts();
    
    switch (network.name) {
        case "okex_test":
            break
        case "okex":
            break
        default:
            console.log(`Not known network ${network.name}`)
            break
    }
}

module.exports.tags = ["09"]


