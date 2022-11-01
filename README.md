
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
4. Create an .env file with your alchemy api key
   ```js
   # Mnemonic, only first address will be used
    MNEMONIC=""

   # Add Alchemy or Infura provider keys, alchemy takes preference at the config level
   ALCHEMY_KEY="https://eth-mainnet.g.alchemy.com/v2/iK90jGtrwumtlgRlWWGbwW0Ep0I8cWLN"
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
   npx hardhat node --fork https://eth-mainnet.alchemyapi.io/v2/<key>
   ```

2. run the hardhat test file

    ```sh
   npx hardhat test
   ```




