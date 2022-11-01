import BigNumber from "bignumber.js";
import { ethers } from "hardhat";
import {
  USDT_ADDRESS,
  WBTC_ADDRESS,
  AAVE_PROTOCOL_DATA_PROVIDER_ADDRESS,
  LENDING_POOL_ADDRESS,
  oneEther
} from '../helpers/constants';

const AaveProtocolDataProviderrtifact = require('@aave/protocol-v2/artifacts/contracts/misc/AaveProtocolDataProvider.sol/AaveProtocolDataProvider.json');
const IERC20Artifact = require('@aave/protocol-v2/artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json');
let liquidator;

export async function runLiquidator(borrowers: [string], liquidationHelperAddress: string){
  [, , , , liquidator] = await ethers.getSigners();
  let pool = await ethers.getContractAt('ILendingPool',LENDING_POOL_ADDRESS);
  let aaveDataProvider = await ethers.getContractAt(AaveProtocolDataProviderrtifact.abi,AAVE_PROTOCOL_DATA_PROVIDER_ADDRESS)    
  let wbtc = await ethers.getContractAt(IERC20Artifact.abi,WBTC_ADDRESS);
  let usdt = await ethers.getContractAt('IUSDT',USDT_ADDRESS);
  let liquidatorHelper = await ethers.getContractAt('LiquidatorHelper',liquidationHelperAddress);
  
   for (let i = 0; i < borrowers.length; i++) {
      let userReserveDataBefore = await pool.getUserAccountData(borrowers[i]);
      let data = await aaveDataProvider.getUserReserveData(usdt.address, borrowers[i])

      let hf = new BigNumber(userReserveDataBefore.healthFactor.toString())
    
      if(oneEther.comparedTo(hf) == 1){ // --> Helth factor is lower then 1
        let amountToLiquidate = new BigNumber(data.principalStableDebt.toString())
        .div(2)
        .toFixed(0);

        usdt.connect(liquidator).approve(liquidatorHelper.address, '1000000000000000000000000000');
        liquidatorHelper.connect(liquidator).fundLiquidateAndSell(pool.address, wbtc.address, usdt.address, borrowers[i], amountToLiquidate, false);    
      }      
   };
    
  return(true)
}

export async function runLiquidatorWithFlashLoan(borrowers: [string], liquidationHelperAddress: string){
  [, , , , liquidator] = await ethers.getSigners();
  let pool = await ethers.getContractAt('ILendingPool',LENDING_POOL_ADDRESS);
  let aaveDataProvider = await ethers.getContractAt(AaveProtocolDataProviderrtifact.abi,AAVE_PROTOCOL_DATA_PROVIDER_ADDRESS)    
  let wbtc = await ethers.getContractAt(IERC20Artifact.abi,WBTC_ADDRESS);
  let usdt = await ethers.getContractAt('IUSDT',USDT_ADDRESS);
  let liquidatorHelper = await ethers.getContractAt('LiquidatorHelper',liquidationHelperAddress);
 
   for (let i = 0; i < borrowers.length; i++) {
      let userReserveDataBefore = await pool.getUserAccountData(borrowers[i]);
      let data = await aaveDataProvider.getUserReserveData(usdt.address, borrowers[i])

      let hf = new BigNumber(userReserveDataBefore.healthFactor.toString())
    
      if(oneEther.comparedTo(hf) == 1){ // --> Helth factor is lower then 1
        let amountToLiquidate = new BigNumber(data.principalStableDebt.toString())
        .div(2)
        .toFixed(0);

        usdt.connect(liquidator).approve(liquidatorHelper.address, '1000000000000000000000000000');
        liquidatorHelper.connect(liquidator).FlashLoanLiquidateAndSell(pool.address, wbtc.address, usdt.address, borrowers[i], amountToLiquidate, false);    
      }      
   };
    
  return(true)
}

