const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SatelliteCity", function () {
  let owner, addr1, addr2, addr3;
  let bor, oracle, addressResolver, liquidation, satelliteCity;
  let fakeDAI, fakeWBTC, fakePair, tunnel, boringDAO, trusteeFeePool;

  beforeEach(async function () {
    [owner, addr1, addr2, addr3] = await ethers.getSigners();
    console.log(owner.address);
    console.log(addr1.address);
    const tunnelKey = ethers.utils.formatBytes32String("BTC");
    const BOR = await ethers.getContractFactory("Bor");
    const Oracle = await ethers.getContractFactory("Oracle");
    const AddressResolver = await ethers.getContractFactory("AddressResolver");
    const Liquidation = await ethers.getContractFactory("Liquidation");
    const SatelliteCity = await ethers.getContractFactory("SatelliteCity");
    const FakeDAI = await ethers.getContractFactory("FakeDAI");
    const FakeWBTC = await ethers.getContractFactory("FakeWBTC");
    const Tunnel = await ethers.getContractFactory("TunnelV2");
    const BoringDAO = await ethers.getContractFactory("BoringDAOV2");
    const TrusteeFeePool = await ethers.getContractFactory("TrusteeFeePool");
    const FakePair = await ethers.getContractFactory("FakePair");

    bor = await BOR.deploy(owner.address);
    await bor.deployed();

    oracle = await Oracle.deploy();
    await oracle.deployed();
    await oracle.setPrice(ethers.utils.formatBytes32String("FDAI"), ethers.utils.parseEther("1"));
    await oracle.setPrice(ethers.utils.formatBytes32String("FWBTC"), ethers.utils.parseEther("6"));

    addressResolver = await AddressResolver.deploy();
    await addressResolver.deployed();

    liquidation = await Liquidation.deploy(owner.address, addressResolver.address, tunnelKey);
    await liquidation.deployed();

    const height = await ethers.provider.getBlockNumber();
    satelliteCity = await SatelliteCity.deploy(bor.address, 3, height, oracle.address, liquidation.address);
    await satelliteCity.deployed();

    fakeDAI = await FakeDAI.deploy("FakeDAI", "FDAI");
    await fakeDAI.deployed();
    await fakeDAI.faucet();

    fakeWBTC = await FakeWBTC.deploy("FakeWBTC", "FWBTC");
    await fakeWBTC.deployed();
    await fakeWBTC.faucet();

    fakePair = await FakePair.deploy(fakeWBTC.address, fakeDAI.address);
    await fakePair.deployed();
    await fakePair.faucet();

    tunnel = await Tunnel.deploy(addressResolver.address, tunnelKey);
    await tunnel.deployed();

    boringDAO = await BoringDAO.deploy(addressResolver.address, 1000000000, owner.address);
    await boringDAO.deployed();

    trusteeFeePool = await TrusteeFeePool.deploy(bor.address, tunnelKey, boringDAO.address, tunnel.address);
    await trusteeFeePool.deployed();

    await addressResolver.setAddress(ethers.utils.formatBytes32String("BoringDAO"), boringDAO.address);
    await addressResolver.setKkAddr(tunnelKey, ethers.utils.formatBytes32String("TrusteeFeePool"), trusteeFeePool.address);

    await boringDAO.addTrustee(addr1.address, tunnelKey);
    await boringDAO.addTrustee(addr2.address, tunnelKey);
    await boringDAO.addTrustee(addr3.address, tunnelKey);
    await boringDAO.grantRole(ethers.utils.formatBytes32String("MONITOR_ROLE "), liquidation.address);

    await satelliteCity.addPool(true, 100, fakeDAI.address, false);
    await satelliteCity.addPool(true, 100, fakeWBTC.address, false);
    await satelliteCity.setDispatcher(owner.address);
  });
  it("Can't deposit if not approve", async function () {
    await expect(satelliteCity.connect(addr1).deposit(0, ethers.utils.parseEther("1"))).to.be.revertedWith(
      "ERC20: transfer amount exceeds balance"
    );
    await fakeDAI.transfer(addr1.address, ethers.utils.parseEther("10"));
    await expect(satelliteCity.connect(addr1).deposit(0, ethers.utils.parseEther("1"))).to.be.revertedWith(
      "ERC20: transfer amount exceeds allowance"
    );
    await fakeDAI.connect(addr1).approve(satelliteCity.address, ethers.constants.MaxUint256);
    await satelliteCity.connect(addr1).deposit(0, ethers.utils.parseEther("1"));
  });
  it("Check tvl", async function () {
    await fakeDAI.approve(satelliteCity.address, ethers.constants.MaxUint256);
    await fakeWBTC.approve(satelliteCity.address, ethers.constants.MaxUint256);
    await fakePair.approve(satelliteCity.address, ethers.constants.MaxUint256);

    expect(await satelliteCity.tvl()).to.equal(ethers.utils.parseEther("0"));

    await satelliteCity.deposit(0, ethers.utils.parseUnits("10"));
    await satelliteCity.deposit(1, ethers.utils.parseUnits("20", 8));

    expect(await satelliteCity.tvl()).to.equal(ethers.utils.parseEther("130"));

    await satelliteCity.withdraw(0, ethers.utils.parseEther("6.5"));
    expect(await satelliteCity.tvl()).to.equal(ethers.utils.parseEther("123.5"));

    await satelliteCity.addPool(false, 500, fakePair.address, false);
    await satelliteCity.deposit(2, ethers.utils.parseEther("5"));

    expect(await satelliteCity.tvl()).to.equal(ethers.utils.parseEther("183.5"));
  });
  it("Can't deposit/withdraw when paused", async function () {
    await fakeDAI.transfer(addr2.address, ethers.utils.parseEther("10"));
    await fakeWBTC.transfer(addr2.address, ethers.utils.parseUnits("10", 8));
    await fakeDAI.connect(addr2).approve(satelliteCity.address, ethers.constants.MaxUint256);
    await fakeWBTC.connect(addr2).approve(satelliteCity.address, ethers.constants.MaxUint256);

    await liquidation.setIsSatellitePool(satelliteCity.address, true);
    await liquidation.connect(addr1).pause();

    await satelliteCity.connect(addr2).deposit(0, ethers.utils.parseUnits("4"));
    await satelliteCity.connect(addr2).deposit(1, ethers.utils.parseUnits("8", 8));
    await liquidation.connect(owner).pause();
    await expect(satelliteCity.connect(addr2).deposit(0, ethers.utils.parseUnits("1"))).to.be.revertedWith("Pausable: paused");
    expect(await satelliteCity.paused()).to.equal(true);

    // liquidate
    await liquidation.connect(addr1).confirmWithdraw(satelliteCity.address, addr3.address);
    await liquidation.connect(addr2).confirmWithdraw(satelliteCity.address, addr3.address);

    await liquidation.withdrawArray(satelliteCity.address, addr3.address, [0, 1]);
    expect(await fakeDAI.balanceOf(addr3.address)).to.equal(ethers.utils.parseEther("4"));
    expect(await fakeWBTC.balanceOf(addr3.address)).to.equal(ethers.utils.parseUnits("8", 8));
  });
});
