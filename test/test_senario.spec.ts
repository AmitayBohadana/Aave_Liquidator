import { Contract } from '@ethersproject/contracts';
import BigNumber from 'bignumber.js';
import { expect } from 'chai';
import { ethers, network } from 'hardhat';
import {runLiquidator, runLiquidatorWithFlashLoan} from '../scripts/aave_liquidator';
import {
    USDT_ADDRESS,
    WBTC_ADDRESS,
    WETH_ADDRESS,
    UNISWAPV2_ROUTER_ADDRESS,
    AAVE_PROTOCOL_DATA_PROVIDER_ADDRESS,
    LENDING_POOL_ADDRESS,
    AAVE_ORACLE_ADDRESS,
    LENDING_POOL_ADDRESS_PROVIDER,
    USDT_OWNER,
    WBTC_OWNER,
    oneEther
} from '../helpers/constants';

const LendingPoolV2Artifact = require('@aave/protocol-v2/artifacts/contracts/protocol/lendingpool/LendingPool.sol/LendingPool.json');
const AaveOracleV2Artifact = require('@aave/protocol-v2/artifacts/contracts/misc/AaveOracle.sol/AaveOracle.json');
const IERC20Artifact = require('@aave/protocol-v2/artifacts/@openzeppelin/contracts/token/ERC20/IERC20.sol/IERC20.json');
const AaveProtocolDataProviderrtifact = require('@aave/protocol-v2/artifacts/contracts/misc/AaveProtocolDataProvider.sol/AaveProtocolDataProvider.json');

describe("Aave Task", function () {
    let user1 , borrower, liquidator, usdtOwner;
    let oracle, pool: Contract, wbtc: Contract,  usdt: Contract, aaveDataProvider, LiquidatorHelper
    let liquidatorHelper;

    let usdtDecimals = 10**6;
    let user2BorrowAmount = 12000 * usdtDecimals; 
    before(async function() {
        [user1, borrower, , , liquidator, usdtOwner] = await ethers.getSigners();
        oracle = await ethers.getContractAt(AaveOracleV2Artifact.abi,AAVE_ORACLE_ADDRESS);
        pool = await ethers.getContractAt(LendingPoolV2Artifact.abi,LENDING_POOL_ADDRESS);
        wbtc = await ethers.getContractAt(IERC20Artifact.abi,WBTC_ADDRESS);
        usdt = await ethers.getContractAt('IUSDT',USDT_ADDRESS);
        aaveDataProvider = await ethers.getContractAt(AaveProtocolDataProviderrtifact.abi,AAVE_PROTOCOL_DATA_PROVIDER_ADDRESS)
        LiquidatorHelper = await ethers.getContractFactory('LiquidatorHelper');
        liquidatorHelper = await LiquidatorHelper.deploy(UNISWAPV2_ROUTER_ADDRESS, WETH_ADDRESS,LENDING_POOL_ADDRESS_PROVIDER,LENDING_POOL_ADDRESS);
    })

    it("Change USDT ownership & transfer usdt to users", async function () {
        
        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [USDT_OWNER],
          });
        const signer = await ethers.getSigner(USDT_OWNER)
        
        expect(signer.address).to.be.eq(USDT_OWNER)
        expect(await usdt.getOwner()).to.be.eq(USDT_OWNER)

        await user1.sendTransaction({
            to: signer.address,
            value: "10000000000000000000", // Sends exactly 10 ether
          });
        await usdt.connect(signer).transferOwnership(usdtOwner.address)

        expect(await usdt.getOwner()).to.be.eq(usdtOwner.address)

        await usdt.connect(usdtOwner).issue("1000000000000000"); //Issue 1 billion usdt tokens
        //transfer usdt to liquidator     
        await usdt.connect(usdtOwner).transfer(liquidator.address,"100000000000")
        expect(await usdt.balanceOf(liquidator.address)).to.be.equal("100000000000")
        
    })
    it("send WBTC to browwer from a WBTC holder", async function () {
    
        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: ["0x21ac4ce028d1e11cb20f227a57e30cb41e893728"],
          });
        const signer = await ethers.getSigner("0x21ac4ce028d1e11cb20f227a57e30cb41e893728")
        await user1.sendTransaction({
            to: signer.address,
            value: "2000000000000000000", // Sends exactly 2 ether
        });
        
        await wbtc.connect(signer).transfer(borrower.address,"500000000")
    
        let newBalance = await wbtc.balanceOf(borrower.address)
        expect(newBalance.toString()).to.be.equal("500000000");

    })
        
    it("Should deposit", async function () {
        //Uer2 has 5 wbtc. user2 should deposit
        await wbtc.connect(borrower).approve(pool.address,"1000000000")
        await pool.connect(borrower).deposit(WBTC_ADDRESS, "100000000",borrower.address, 0)
        expect(await wbtc.balanceOf(borrower.address)).to.be.equal("400000000");
    })
    it("Should not borrow", async function () {
        await expect(pool.connect(borrower).borrow(USDT_ADDRESS, "60000000000000000000000", 1, 0, borrower.address)).to.be.revertedWith("11");
        
    })
    it("Should borrow", async function () {
        
        await pool.connect(borrower).borrow(USDT_ADDRESS, user2BorrowAmount, 1, 0, borrower.address)
        await expect(await usdt.balanceOf(borrower.address)).to.be.equal(user2BorrowAmount);

        let userGlobalData = await pool.getUserAccountData(borrower.address);

        expect(userGlobalData.healthFactor).to.be.gt(
        oneEther.toString(),
        ""
        );
        
    })

    it("should set new price aggeragator for WBTC and drop price", async function () {
        let oracleOwnerAddress = await oracle.owner();
        let price : BigNumber = await oracle.getAssetPrice(WBTC_ADDRESS)
        let MockAggregator = await ethers.getContractFactory("MockAggregator")
        let newPrice = new BigNumber(price.toString()).multipliedBy(0.5)
        //deploy mock aggregator with new reduced price
        let mockAggregator = await MockAggregator.deploy(newPrice.toString());
        //Set new asset source to oracle
        await network.provider.request({
            method: "hardhat_impersonateAccount",
            params: [oracleOwnerAddress],
          });
        const signer = await ethers.getSigner(oracleOwnerAddress)
        
        await user1.sendTransaction({
            to: signer.address,
            value: "10000000000000000000", // Sends exactly 10 ether
          });
        await expect(oracle.connect(signer).setAssetSources([WBTC_ADDRESS],[mockAggregator.address]))
            .to.emit(oracle, "AssetSourceUpdated")
            .withArgs(WBTC_ADDRESS, mockAggregator.address);      
    })

    // it("liquidator should liquidate user2 and sell colleteral on Uniswap", async function () {
    //     let liquidatorUsdtAmountBefore = await usdt.balanceOf(liquidatorHelper.address)
    //     expect(await usdt.balanceOf(liquidator.address)).to.be.equal("100000000000")
        
    //     await runLiquidator([user2.address], liquidatorHelper.address);

    //     expect(await usdt.balanceOf(liquidatorHelper.address)).to.be.gt(liquidatorUsdtAmountBefore)
    // })

    it("liquidator should liquidate user2 using FlashLoan and sell colleteral on Uniswap", async function () {
        let liquidatorUsdtAmountBefore = await usdt.balanceOf(liquidatorHelper.address)
        expect(await usdt.balanceOf(liquidator.address)).to.be.equal("100000000000")
        
        await runLiquidatorWithFlashLoan([borrower.address], liquidatorHelper.address);

        expect(await usdt.balanceOf(liquidatorHelper.address)).to.be.gt(liquidatorUsdtAmountBefore)
    })

})
