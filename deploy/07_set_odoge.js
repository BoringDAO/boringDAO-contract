const {
    Contract
} = require("@ethersproject/contracts");
const {
    formatBytes32String,
    formatEther,
    parseEther
} = require("ethers/lib/utils");
const {
    network,
    ethers,
    getUnnamedAccounts,
    getNamedAccounts
} = require("hardhat");

async function set_address_resolver(addrReso, tunnel_addr, feePoolAddr, oTokenAddr, pptTokenAddr,
    trusteeFeePoolAddr, insurancePoolAddr, satellitePoolFactoryAddr, liquiAddr) {
    kAs = ['DOGE']
    kAs_bytes32 = kAs.map(formatBytes32String)
    kAAddrs = [
        tunnel_addr
    ]
    // await addrReso.setMultiAddress(kAs_bytes32, kAAddrs)

    k = ['DOGE', 'DOGE', 'DOGE', 'DOGE', 'DOGE', 'DOGE', 'DOGE', ]
    kBytes32 = k.map(formatBytes32String)
    k2s = ['FeePool', 'oToken', "ppToken", "TrusteeFeePool", "InsurancePool", "SatellitePoolFactory", "Liquidation"]
    k2sBytes32 = k2s.map(formatBytes32String)
    addr = [feePoolAddr, oTokenAddr, pptTokenAddr,
        trusteeFeePoolAddr, insurancePoolAddr, satellitePoolFactoryAddr, liquiAddr
    ]

    await addrReso.setMultiKKAddr(kBytes32, k2sBytes32, addr)
}

async function addTrustees(trustees, boringDaO, tunnelKey) {
    await boringDaO.addTrustees(trustees, formatBytes32String(tunnelKey))
}

module.exports = async ({
    getNamedAccounts,
    deployments
}) => {
    const {
        get,
        execute,
        deploy
    } = deployments;
    const {
        deployer,
        user1,
        user2
    } = await getNamedAccounts()
    contracts = ""
    trustees = []
    multiaddr = ""
    switch (network.name) {
        case "ropsten":
            //
            contracts = {
                "bor": "0xC877Ec4f22317A30BA04A17796d4497490A76e22",
                "addressReso": "0x2891002c1A4F15B4686EBdc965de4Dc1ea384c84",
                "boringDAO": "0x5b846eD0889Bf507D2A721d81e694aFE674bB731",
                "oracle": "0xF178D2EE54Dbfb22b06404667a2c2846EEc76414",
                "addressBook": "0x90371aE783E8689eB76D4A01E65feBb50AC06B39",
                "paramBook": "0x727BE15ca0458DC8A70f7F342CF85820e80C688A",
                "mintProposal": "0xCF97557109EFC04b19eC8b329fc4f0C78FdFCbc6",
                "burnProposal": "0xAB3863FfDe898937BBa30270Df1499bf99D067b9",
                "tunnelV2": (await get("TunnelV2DOGE")).address,
                "feePool": (await get("FeePoolDOGE")).address,
                "liqui": (await get("LiquidationDOGE")).address,
                "otoken": (await get("OTokenDOGE")).address,
                "pptoken": (await get("PPTokenDOGE")).address,
                "trusteeFeePool": (await get("TrusteeFeePoolDOGE")).address,
                "insurancePool": (await get("InsurancePoolDOGE")).address,
                "spf": (await get("SatellitePoolFactoryV2DOGE")).address
            }
            trustees = ["0xC213ef4E4AcB689655Fc476D30EFf0fb865Eb28a", "0x9A789011918926d4C4Bbc2CBFC5c9269a39c0961", "0xC5ECF1E0CaF1EE47658F77b667aFFC47033B582B", "0x817016163775AaF0B25DF274fB4b18edB67E1F26"]
            multiaddr = "AEb9MwXZ4PtChUSenAJ1ST23LggokA5ofR"

            break;
        case "mainnet":
            contracts = {
                "bor": "0x3c9d6c1C73b31c837832c72E04D3152f051fc1A9",
                "addressReso": "0xa254bBb68A73d9BBa7760ba6E1B4D0E005D8B671",
                "boringDAO": "0x58e25cCD2843caE992eFBC15C8D4C64f4f70809A",
                "oracle": "0xf9d6ab5faad5dEa4d15B35ECa0B72FfaE8A7104A",
                "addressBook": "0x1B0e954aa1b88791c8251E8328287F3FEB96D719",
                "paramBook": "0xbc91C117157D7c47135b13C97ec4a46Fa1CA1ab1",
                "mintProposal": "0xaC3bf6e1fE9Bf1F203Bf07D72F64E95f3ea39BB6",
                "burnProposal": "0xef3BB2Ab1c651DD052dD45a83fc2de306C9Ad94d",
                "tunnelV2": (await get("TunnelV2DOGE")).address,
                "feePool": (await get("FeePoolDOGE")).address,
                "liqui": (await get("LiquidationDOGE")).address,
                "otoken": (await get("OTokenDOGE")).address,
                "pptoken": (await get("PPTokenDOGE")).address,
                "trusteeFeePool": (await get("TrusteeFeePoolDOGE")).address,
                "insurancePool": (await get("InsurancePoolDOGE")).address,
                "spf": (await get("SatellitePoolFactoryV2DOGE")).address,
                "srlPPTDOGE": (await get("StakingRewardsLockPPTDOGE")).address,
                "srlODOGE": (await get("StakingRewardsLockODOGE")).address
            }
            trustees = ["0x900BD2379d5774dcb8A280691e7E1a2DE850d324", "0x246A7a453C2F3f398405F5DE1609D2bA86063e0e", "0x2F847c7a099420ab0477bD9CD91f1108bc702BF0"]
            multiaddr = "ADtFL3nE265yiLr5WzuxwgnSBD2f1L99rd"
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
    // await addressBook.setAssetMultiSignAddress("DOGE", multiaddr)
    names1 = ['DOGE', 'DOGE', 'DOGE', 'DOGE', 'DOGE', 'DOGE', 'DOGE', 'DOGE', 'DOGE']
    names1_bytes32 = names1.map(formatBytes32String)
    names2 = ['mint_fee', 'burn_fee', 'mint_fee_trustee', 'mint_fee_pledger', 'mint_fee_dev', 'burn_fee_insurance', 'burn_fee_pledger', 'pledge_rate', 'network_fee']
    names2_bytes32 = names2.map(formatBytes32String)
    values = ['0.002', '0.002', '0.15', '0.7', '0.15', '0.5', '0.5', '0.05', '800']
    values_wei = values.map(parseEther)
    // console.log(`${names1_bytes32} \n ${names2_bytes32} \n ${values_wei}`)
    // await  paramBook.setMultiParams2(names1_bytes32, names2_bytes32, values_wei)
    console.log(contracts)
    // await set_address_resolver(addressReso, contracts.tunnelV2, contracts.feePool, contracts.otoken,
    //     contracts.pptoken, contracts.trusteeFeePool, contracts.insurancePool, contracts.spf, contracts.liqui)

    // // trustees
    // console.log(`add trustee ${trustees}`)
    // await addTrustees(trustees, boringDAO, "DOGE")
    // await execute("TunnelV2DOGE", {
    //         "from": deployer,
    //         "log": true,
    //     },
    //     "unpause"
    // )
    await oracle.setMultiPrice(['DOGE'].map(formatBytes32String), ['0.71'].map(parseEther))
    // console.log(formatBytes32String("DOGE"))
    // let rate = await paramBook.params2(formatBytes32String("DOGE"), formatBytes32String("pledge_rate"))
    // let price = await oracle.getPrice(formatBytes32String("DOGE"))
    // console.log(`${rate} ${price}`)
    // const bd = await burnProposal.trustee()
    // const bd = await burnProposal.trustee()
    // const result = await boringDAO.hasRole(formatBytes32String("DOGE"), "0x9a789011918926d4c4bbc2cbfc5c9269a39c0961")
    // console.log(`trustee in  burn proposal: ${bd}`)
    // console.log(`result in  boringdao: ${result}`)

    // await deploy("BurnProposalLTC_DOGE", {
    //     from: deployer,
    //     contract: "BurnProposal",
    //     args: [contracts["boringDAO"]],
    //     logs: true
    // })



}

module.exports.tags = ["07"]