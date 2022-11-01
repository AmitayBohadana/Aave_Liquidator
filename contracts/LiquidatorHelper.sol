// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from "@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IUniswapV2Router02} from "@aave/protocol-v2/contracts/interfaces/IUniswapV2Router02.sol";

contract LiquidatorHelper {
    using SafeERC20 for IERC20;

    address private lendingPool;
    address private v2Router02;
    address private weth;
    address private lendingPoolAddressesProvider;

    constructor(
        address _v2Router02,
        address _weth,
        address _lendingPoolAddressesProvider,
        address _lendingPool
    ) public {
        v2Router02 = _v2Router02;
        weth = _weth;
        lendingPoolAddressesProvider = _lendingPoolAddressesProvider;
        lendingPool = _lendingPool;
    }

    /**
     * @notice fund and then liquidate the borrower on aave protocol
     * @param pool address on of the token to be funded
     * @param collateralAsset the collateral asset of the borowwer
     * @param debtAsset the debt asset
     * @param user the borrower address
     * @param debtToCover the amount of debt to cover
     * @param receiveAToken boolean - if true the liquidation call will return the AToken, if false it will return the collateral asset
     **/
    function liquidationCall(
        address pool,
        address collateralAsset,
        address debtAsset,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) external {
        ILendingPool(pool).liquidationCall(
            collateralAsset,
            debtAsset,
            user,
            debtToCover,
            receiveAToken
        );
    }

    /**
     * @notice fund the LiquidatorHelper with tokens
     * @param token address on of the token to be funded
     * @param amount the amount
     **/
    function fund(address token, uint256 amount) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
    }

    /**
     * @notice fund and then liquidate the borrower on aave protocol
     * @param pool address on of the token to be funded
     * @param collateralAsset the collateral asset of the borowwer
     * @param debtAsset the debt asset
     * @param borrower the borrower address
     * @param debtToCover the amount of debt to cover
     * @param receiveAToken boolean - if true the liquidation call will return the AToken, if false it will return the collateral asset
     **/
    function fundAndLiquidate(
        address pool,
        address collateralAsset,
        address debtAsset,
        address borrower,
        uint256 debtToCover,
        bool receiveAToken
    ) external {
        IERC20(debtAsset).safeTransferFrom(
            msg.sender,
            address(this),
            debtToCover
        );

        IERC20(debtAsset).safeApprove(pool, debtToCover);

        ILendingPool(pool).liquidationCall(
            collateralAsset,
            debtAsset,
            borrower,
            debtToCover,
            receiveAToken
        );
    }

    /**
     * @notice fund, liquidate the borrower on aave protocol and then sell the asset on a dex
     * @param pool address on of the token to be funded
     * @param collateralAsset the collateral asset of the borowwer
     * @param debtAsset the debt asset
     * @param borrower the borrower address
     * @param debtToCover the amount of debt to cover
     * @param receiveAToken boolean - if true the liquidation call will return the AToken, if false it will return the collateral asset
     **/
    function fundLiquidateAndSell(
        address pool,
        address collateralAsset,
        address debtAsset,
        address borrower,
        uint256 debtToCover,
        bool receiveAToken
    ) external {
        IERC20(debtAsset).safeTransferFrom(
            msg.sender,
            address(this),
            debtToCover
        );

        IERC20(debtAsset).safeApprove(pool, debtToCover);

        ILendingPool(pool).liquidationCall(
            collateralAsset,
            debtAsset,
            borrower,
            debtToCover,
            receiveAToken
        );

        uint256 newBalance = IERC20(collateralAsset).balanceOf(address(this));

        IERC20(collateralAsset).safeApprove(v2Router02, newBalance);

        uint256 amountMin = getAmountOutMin(
            collateralAsset,
            debtAsset,
            newBalance
        );

        swap(collateralAsset, debtAsset, newBalance, amountMin, address(this));
    }

    /**
     * @notice fund with flashlaon, liquidate the borrower on aave protocol, sell the asset on a dex and pay the loan back
     * @param pool address on of the token to be funded
     * @param collateralAsset the collateral asset of the borowwer
     * @param debtAsset the debt asset
     * @param borrower the borrower address
     * @param debtToCover the amount of debt to cover
     * @param receiveAToken boolean - if true the liquidation call will return the AToken, if false it will return the collateral asset
     **/
    function FlashLoanLiquidateAndSell(
        address pool,
        address collateralAsset,
        address debtAsset,
        address borrower,
        uint256 debtToCover,
        bool receiveAToken
    ) external {
        bytes memory params = abi.encode(pool, collateralAsset, borrower);
        uint256[] memory modes = new uint256[](1);
        modes[0] = 0;
        address[] memory assets = new address[](1);
        assets[0] = debtAsset;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = debtToCover;
        uint16 referal = 0;

        ILendingPool(lendingPool).flashLoan(
            address(this),
            assets,
            amounts,
            modes,
            address(this),
            params,
            referal
        );
    }

    /**
     * @notice Executes an operation after receiving the flash-borrowed assets
     * @dev Ensure that the contract can return the debt + premium, e.g., has
     *      enough funds to repay and has approved the Pool to pull the total amount
     * @param assets The addresses of the flash-borrowed assets
     * @param amounts The amounts of the flash-borrowed assets
     * @param premiums The fee of each flash-borrowed asset
     * @param initiator The address of the flashloan initiator
     * @param params The byte-encoded params passed when initiating the flashloan
     * @return True if the execution of the operation succeeds, false otherwise
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external returns (bool) {
        uint256 debtToCover = amounts[0];
        address debtAsset = assets[0];
        (address pool, address collateralAsset, address borrower) = abi.decode(
            params,
            (address, address, address)
        );
        IERC20(debtAsset).safeApprove(pool, debtToCover);
        ILendingPool(pool).liquidationCall(
            collateralAsset,
            debtAsset,
            borrower,
            debtToCover,
            false
        );

        uint256 newBalance = IERC20(collateralAsset).balanceOf(address(this));
        IERC20(collateralAsset).safeApprove(v2Router02, newBalance);
        uint256 amountMin = getAmountOutMin(
            collateralAsset,
            debtAsset,
            newBalance
        );
        swap(collateralAsset, debtAsset, newBalance, amountMin, address(this));

        IERC20(debtAsset).safeApprove(lendingPool, 2 * debtToCover);

        return true;
    }

    function ADDRESSES_PROVIDER()
        external
        view
        returns (ILendingPoolAddressesProvider)
    {
        return ILendingPoolAddressesProvider(lendingPoolAddressesProvider);
    }

    function LENDING_POOL() external view returns (ILendingPool) {
        return ILendingPool(lendingPool);
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _amountOutMin,
        address _to
    ) internal {
        IERC20(_tokenIn).approve(v2Router02, _amountIn);

        address[] memory path;
        if (_tokenIn == weth || _tokenOut == weth) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = weth;
            path[2] = _tokenOut;
        }
        IUniswapV2Router02(v2Router02).swapExactTokensForTokens(
            _amountIn,
            _amountOutMin,
            path,
            _to,
            block.timestamp
        );
    }

    function getAmountOutMin(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn
    ) internal view returns (uint256) {
        address[] memory path;
        if (_tokenIn == weth || _tokenOut == weth) {
            path = new address[](2);
            path[0] = _tokenIn;
            path[1] = _tokenOut;
        } else {
            path = new address[](3);
            path[0] = _tokenIn;
            path[1] = weth;
            path[2] = _tokenOut;
        }
        uint256[] memory amountOutMins = IUniswapV2Router02(v2Router02)
            .getAmountsOut(_amountIn, path);
        return amountOutMins[path.length - 1];
    }
}
