const TimeDistribution = artifacts.require("TimeDistribution");
const Bor = artifacts.require("Bor");

module.exports = async (deployer, network, accounts) => {
    // if (network === "development") {
        let bor = await Bor.deployed();
        await deployer.deploy(TimeDistribution, bor.address, accounts[0]);
    // }
}