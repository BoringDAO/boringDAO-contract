const { task } = require("hardhat/config");

task("erc20", "Interact with erc20 token")
  .addParam("token", "ERC20 token address")
  .setAction(async (args, hre, run) => {
    const Token = await hre.ethers.getContractFactory("BaseToken");
    const token = Token.attach(args.token);

    const decimals = await token.decimals();
    const total = await token.totalSupply();
    console.log(`Network: ${hre.network.name}`);
    console.log(`Token: ${args.token} ${await token.symbol()} ${decimals}`);
    console.log(`TotalSupply: ${hre.ethers.utils.formatUnits(total.toString(), decimals)}`);
  });

task("erc20:balance", "Prints account balance")
  .addParam("token", "ERC20 token address")
  .addOptionalParam("account", "Account address")
  .setAction(async (args, hre) => {
    let account = args.account;
    if (!account) {
      const { deployer } = await hre.getNamedAccounts();
      account = deployer;
    }

    const Token = await hre.ethers.getContractFactory("BaseToken");
    const token = Token.attach(args.token);
    const decimals = await token.decimals();
    const balance = await token.balanceOf(account);

    console.log(`Network: ${hre.network.name}`);
    console.log(`Token: ${args.token} ${await token.symbol()} ${decimals}`);
    console.log(`Account: ${account}`);
    console.log(`Balance: ${hre.ethers.utils.formatUnits(balance.toString(), decimals)}`);
  });

task("erc20:approve", "ERC20 approve")
  .addParam("token", "ERC20 token address")
  .addOptionalParam("account", "Account address")
  .addParam("spender", "Spender account")
  .setAction(async (args, hre) => {
    const { deployer } = await hre.getNamedAccounts();
    const Token = await hre.ethers.getContractFactory("BaseToken");
    const token = Token.attach(args.token);
    const decimals = await token.decimals();

    console.log(`Network: ${hre.network.name}`);
    console.log(`Token: ${args.token} ${await token.symbol()} ${decimals}`);
    console.log(`Account: ${deployer}`);

    await token.approve(args.spender, hre.ethers.constants.MaxUint256);
  });

task("erc20:allowance", "ERC20 allowance")
  .addParam("token", "ERC20 token address")
  .addOptionalParam("account", "Account address")
  .addParam("spender", "Spender account")
  .setAction(async (args, hre) => {
    let account = args.account;
    if (!account) {
      const { deployer } = await hre.getNamedAccounts();
      account = deployer;
    }

    const Token = await hre.ethers.getContractFactory("BaseToken");
    const token = Token.attach(args.token);
    const decimals = await token.decimals();
    const allowance = await token.allowance(account, args.spender);

    console.log(`Network: ${hre.network.name}`);
    console.log(`Token: ${args.token} ${await token.symbol()} ${decimals}`);
    console.log(`Account: ${account}`);
    console.log(`Spender: ${args.spender}`);
    console.log(`Allowance: ${hre.ethers.utils.formatUnits(allowance, decimals)}`);
  });

module.exports = {};
