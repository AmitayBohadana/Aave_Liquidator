
<!-- GETTING STARTED -->
## Getting Started

This is an example of how you may give instructions on setting up your project locally.
To get a local copy up and running follow these simple example steps.

### Prerequisites

This is an example of how to list things you need to use the software and how to install them.
* npm
  ```sh
  npm install
  ```

### Installation

_Below is an example of how you can instruct your audience on installing and setting up your app. This template doesn't rely on any external dependencies or services._

1. Get a free API Key at [https://example.com](https://example.com)
2. Clone the repo
   ```sh
   git clone https://github.com/your_username_/Project-Name.git
   ```
3. Install NPM packages
   ```sh
   npm install
   ```
4. Create an .env file with your alchemy api key for ethereum mainnet
   ```js
   # Mnemonic, only first address will be used
    MNEMONIC=""

   # Add Alchemy or Infura provider keys, alchemy takes preference at the config level
   ALCHEMY_KEY="<key>"
   INFURA_KEY=""


   # Optional Etherscan key, for automatize the verification of the contracts at Etherscan
   ETHERSCAN_KEY=""

   # Optional, if you plan to use Tenderly scripts
   TENDERLY_PROJECT=""
   TENDERLY_USERNAME=""
   ```
<!-- USAGE EXAMPLES -->
## Usage

1. open a terminal and fork mainnet using hardhat command

   ```sh
   npx hardhat node --network hardhat
   ```
   or
   ```sh
   npx hardhat node --fork https://eth-mainnet.alchemyapi.io/v2/<key>
   ```

2. run the hardhat test file

    ```sh
   npx hardhat test
   ```

<!-- USAGE EXAMPLES -->
## Description
This project contains a liquidator ( and arbitrageur)  agent on Aave and a scenario to reduce Aave’s oracle prices to that liquidations would trigger.
it can be tested on a forked mainnet.


<!-- Methodology chosen for manipulation of Oracle prices -->
## Methodology chosen for manipulation of Oracle prices
   In order to manipulate the oracle price I have choosed to deploy a MockAggregator with the desaired asset price.
   in order to set this MockAggregator as the source of an asset I have called `setAssetSources` on AaveOracle contract.
   in that way I could change the price and the Helth factor and make a liquidation senario.


<!-- Liquidator agent -->
## Liquidator agent
   the liquidator agent is using the script under the scripts/ folder.
   first I deploy the LiquidatorHelper contract. this contract has the ability
   1. To liquidate an asset of a borrower
   2. To liquidate and then sell the asset on Uniswap (or any other uniswap clone by configuration)    
   3. To do the above using flashloan. take a laon, liquidate, sell the asset on Uniswap and pay back the loan and the leftovers are profits.


<!-- Important to notice -->
## Important to notice
   when oracle price is changed using MockAggregator the asset price on Uniswap DO NOT change.
   it is possible that on a forked mainnet without enteties that are doing arbitrage the liquidation transaction will LOOSE money. but in realety it shoudn't


<!-- Test plan -->
## Test plan
   1. user deposit colletaral (WBTC) to to aave
   2. user borrow an amount of USDT
   3. the price of WBTC drops
   4. user HF going below 1 and he can be liquidate
   5. liquidator is liquidating the user using flashloan and sell the WBTC on Uniswap and left with profit
   




