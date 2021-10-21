const { ethers } = require("hardhat");
const fs = require('fs');

const polygonAlchemyKey = fs.readFileSync("secretPolygon").toString().trim();

async function main() {

  await network.provider.request({
    method: "hardhat_reset",
    params: [
    {
      forking: 
      {
        jsonRpcUrl: `${polygonAlchemyKey}`,
        blockNumber: 19876870
      },
    },
    ],
  });

  /* ABIs */
  const LendingPoolAbi = require("../external_abi/LendingPool.json");
  const WETHabi = require("../external_abi/WETH.json");
  const DAIabi = require("../external_abi/DAI.json");
  const variableDebtTokenABI = require("../external_abi/variableDebtToken.json");

  /* Addresses */
  // DAI
  const DAI = "0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063";     
  const DAIdebt = "0x75c4d1Fb84429023170086f06E682DcbBF537b7d";

  // WETH
  const WETH = "0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619";
  const WETHdebt = "0xeDe17e9d79fc6f9fF9250D9EEfbdB88Cc18038b5";

  // AAVE Lending Pool 
  const LENDINGPOOL = "0x8dFf5E27EA6b7AC08EbFdf9eB090F32ee9a30fcf";

  // AAVE Data Provider
  const DATAPROVIDER = "0x7551b5D2763519d4e37e8B81929D336De671d46d";


  /* Provider */
  const provider = new ethers.providers.JsonRpcProvider();

  // Instantiating the existing mainnet fork contracts
  aave = new ethers.Contract(LENDINGPOOL, LendingPoolAbi, provider);
  weth = new ethers.Contract(WETH, WETHabi, provider);
  wethDebt = new ethers.Contract(WETHdebt, variableDebtTokenABI, provider);
  dai = new ethers.Contract(DAI, DAIabi, provider);
  daiDebt = new ethers.Contract(DAIdebt, variableDebtTokenABI, provider);
  
  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: ["0xd3d176F7e4b43C70a68466949F6C64F06Ce75BB9"],
  });
  whaleWETH = await ethers.getSigner("0xd3d176F7e4b43C70a68466949F6C64F06Ce75BB9");   

  // Define the signers
  [delegator, borrower, _] = await ethers.getSigners();   

  const amountToTransfer = 10;
  const weiAmountToTransfer = ethers.utils.parseEther(amountToTransfer.toString());
  await weth.connect(whaleWETH).transfer(delegator.address, weiAmountToTransfer);

  const amountToDeposit = 10;
  const weiAmountToDeposit = ethers.utils.parseEther(amountToDeposit.toString());

  await weth.connect(delegator).approve(LENDINGPOOL, weiAmountToDeposit);
  await aave.connect(delegator).deposit(WETH, weiAmountToDeposit, delegator.address, 0);

  const amountToDelegate = 1;
  const weiAmountToDelegate = ethers.utils.parseEther(amountToDelegate.toString());

  await wethDebt.connect(delegator).approveDelegation(borrower.address, weiAmountToDelegate);

  borrowAllowance = await wethDebt.borrowAllowance(delegator.address, borrower.address);
  console.log("--------------------------------------------------------------------------------");
  console.log("Borrower can borrow up to %d WETH", ethers.utils.formatEther(borrowAllowance.toString()));

  await aave.connect(borrower).borrow(weth.address, borrowAllowance, 2, 0, delegator.address);
  await aave.connect(delegator).borrow(weth.address, borrowAllowance, 2, 0, delegator.address);

  delegatorDebtBal = await wethDebt.balanceOf(delegator.address);
  borrowerDebtBal = await wethDebt.balanceOf(borrower.address);
  delegatorDebtScaledBal = await wethDebt.scaledBalanceOf(delegator.address);
  borrowerDebtScaledBal = await wethDebt.scaledBalanceOf(borrower.address);
  console.log("Delegator debt balance is : %d WETH", ethers.utils.formatEther(delegatorDebtBal.toString()));
  console.log("Borrower debt balance is : %d WETH", ethers.utils.formatEther(borrowerDebtBal.toString()));
  console.log("Delegator debt scaled balance is : %d WETH", ethers.utils.formatEther(delegatorDebtScaledBal.toString()));
  console.log("Borrower debt scaled balance is : %d WETH", ethers.utils.formatEther(borrowerDebtScaledBal.toString()));
  console.log("--------------------------------------------------------------------------------");

  await network.provider.send("evm_mine");
  await network.provider.send("evm_mine");

  borrowAllowance = await wethDebt.borrowAllowance(delegator.address, borrower.address);
  console.log("Borrower can borrow up to %d WETH", ethers.utils.formatEther(borrowAllowance.toString()));
  delegatorDebtBal = await wethDebt.balanceOf(delegator.address);
  borrowerDebtBal = await wethDebt.balanceOf(borrower.address);
  delegatorDebtScaledBal = await wethDebt.scaledBalanceOf(delegator.address);
  borrowerDebtScaledBal = await wethDebt.scaledBalanceOf(borrower.address);
  console.log("Delegator debt balance is : %d WETH", ethers.utils.formatEther(delegatorDebtBal.toString()));
  console.log("Borrower debt balance is : %d WETH", ethers.utils.formatEther(borrowerDebtBal.toString()));
  console.log("Delegator debt scaled balance is : %d WETH", ethers.utils.formatEther(delegatorDebtScaledBal.toString()));
  console.log("Borrower debt scaled balance is : %d WETH", ethers.utils.formatEther(borrowerDebtScaledBal.toString()));
  console.log("--------------------------------------------------------------------------------");
  
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });