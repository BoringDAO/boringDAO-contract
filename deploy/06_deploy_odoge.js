const {
    formatBytes32String
} = require("ethers/lib/utils");
const {
    network,
    ethers,
    getUnnamedAccounts,
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
    // const [deployer, user1] = await getUnnamedAccounts();
    const {
        deployer,
        user1,
        user2
    } = await getNamedAccounts();
    contracts = ""


    switch (network.name) {
        case "ropsten":
            console.log(`network ${network.name} ${deployer}`)
            contracts = {
                "bor": "0xC877Ec4f22317A30BA04A17796d4497490A76e22",
                "addressReso": "0x2891002c1A4F15B4686EBdc965de4Dc1ea384c84",
                "boringDAO": "0x5b846eD0889Bf507D2A721d81e694aFE674bB731",
                "oracle": "0xF178D2EE54Dbfb22b06404667a2c2846EEc76414",
                "addressBook": "0x90371aE783E8689eB76D4A01E65feBb50AC06B39",
                "paramBook": "0x727BE15ca0458DC8A70f7F342CF85820e80C688A",
                "mintProposal": "0xCF97557109EFC04b19eC8b329fc4f0C78FdFCbc6",
                "burnProposal": "0x5520b1FA7e54ef04BC25AF6B46bfEEC6157381A9"
            }
            break;
        case "mainnet":
            console.log(`network ${network.name} ${deployer}`)
            contracts = {
                "bor": "0x3c9d6c1C73b31c837832c72E04D3152f051fc1A9",
                "addressReso": "0xa254bBb68A73d9BBa7760ba6E1B4D0E005D8B671",
                "boringDAO": "0x58e25cCD2843caE992eFBC15C8D4C64f4f70809A",
                "oracle": "0xf9d6ab5faad5dEa4d15B35ECa0B72FfaE8A7104A",
                "addressBook": "0x1B0e954aa1b88791c8251E8328287F3FEB96D719",
                "paramBook": "0xbc91C117157D7c47135b13C97ec4a46Fa1CA1ab1",
                "mintProposal": "0xaC3bf6e1fE9Bf1F203Bf07D72F64E95f3ea39BB6",
                "burnProposal": "0xef3BB2Ab1c651DD052dD45a83fc2de306C9Ad94d"
            }
            break;
    }
    const bor = await ethers.getContractAt("Bor", contracts["bor"])
    const addressReso = await ethers.getContractAt("AddressResolver", contracts['addressReso'])
    const boringDAO = await ethers.getContractAt("BoringDAOV2", contracts["boringDAO"])
    const oracle = await ethers.getContractAt("OracleV2", contracts["oracle"])
    const addressBook = await ethers.getContractAt("AddressBook", contracts["addressBook"])
    const paramBook = await ethers.getContractAt("ParamBook", contracts["paramBook"])
    const mintProposal = await ethers.getContractAt("MintProposal", contracts["mintProposal"])
    const burnProposal = await ethers.getContractAt("BurnProposal", contracts["burnProposal"])
    // liquidation
    await deploy("LiquidationDOGE", {
        from: deployer,
        contract: "Liquidation",
        args: [deployer, addressReso.address, formatBytes32String("DOGE")],
        log: true
    })

    const tunnel_result = await deploy("TunnelV2DOGE", {
        from: deployer,
        contract: "TunnelV2",
        args: [addressReso.address, formatBytes32String("DOGE")],
        log: true
    })
    tunnel_address = tunnel_result.address

    const oDOGEResult = await deploy("OTokenDOGE", {
        from: deployer,
        contract: "OToken",
        args: ["BoringDAO DOGE", "oDOGE", 18, deployer],
        log: true
    })
    oDOGEAddress = oDOGEResult.address
    // await execute("OTokenDOGE", {
    //         from: deployer,
    //         log: true
    //     },
    //     "grantRole",
    //     formatBytes32String("MINTER_ROLE"),
    //     tunnel_address
    // )

    // await execute("OTokenDOGE", {
    //         from: deployer,
    //         log: true
    //     },
    //     "grantRole",
    //     formatBytes32String("BURNER_ROLE"),
    //     tunnel_address
    // )

    const pptokenDOGEResult = await deploy("PPTokenDOGE", {
        from: deployer,
        contract: "PPToken",
        args: ["Pledge Provider Token DOGE", "oDOGE-PPT", 18, deployer],
        log: true
    })
    pptokenDOGEAddress = pptokenDOGEResult.address
    // await execute("PPTokenDOGE", {
    //         from: deployer,
    //         log: true
    //     },
    //     "grantRole",
    //     formatBytes32String("MINTER_ROLE"),
    //     tunnel_address
    // )

    // await execute("PPTokenDOGE", {
    //         from: deployer,
    //         log: true
    //     },
    //     "grantRole",
    //     formatBytes32String("BURNER_ROLE"),
    //     tunnel_address
    // )

    // // fee pool
    await deploy("FeePoolDOGE", {
        from: deployer,
        contract: "FeePool",
        args: [addressReso.address, formatBytes32String("DOGE")],
        log: true
    })

    // // trustee fee pool
    await deploy("TrusteeFeePoolDOGE", {
        from: deployer,
        contract: "TrusteeFeePool",
        args: [oDOGEAddress, formatBytes32String("DOGE"), boringDAO.address, tunnel_address],
        log: true
    })

    // // insurance pool
    await deploy("InsurancePoolDOGE", {
        from: deployer,
        contract: "InsurancePool",
        args: [bor.address],
        log: true
    })

    // // satellite pool factory
    const spf_result = await deploy("SatellitePoolFactoryV2DOGE", {
        from: deployer,
        contract: "SatellitePoolFactoryV2",
        args: [],
        log: true
    })
    const spf_addr = spf_result.address

    await deploy("StakingRewardsLockPPTDOGE", {
        from: deployer,
        contract: "StakingRewardsLock",
        args: [deployer, bor.address, oDOGEResult.address, 90 * 24 * 3600, 50, 50],
        log: true
    })
    await deploy("StakingRewardsLockODOGE", {
        from: deployer,
        contract: "StakingRewardsLock",
        args: [deployer, bor.address, pptokenDOGEResult.address, 90 * 24 * 3600, 50, 50],
        log: true
    })
}

module.exports.tags = ["06"]