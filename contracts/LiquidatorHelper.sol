// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import {ILendingPool} from "@aave/protocol-v2/contracts/interfaces/ILendingPool.sol";
import {ILendingPoolAddressesProvider} from '@aave/protocol-v2/contracts/interfaces/ILendingPoolAddressesProvider.sol';
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import {IUniswapV2Router02} from "@aave/protocol-v2/contracts/interfaces/IUniswapV2Router02.sol";
import 'hardhat/console.sol';

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

  function fund(address debtAsset, uint256 debtToCover) external {
    IERC20(debtAsset).safeTransferFrom(msg.sender, address(this), debtToCover);
  }

  function fundAndLiquidate(
    address pool,
    address collateralAsset,
    address debtAsset,
    address borrower,
    uint256 debtToCover,
    bool receiveAToken
  ) external {
    IERC20(debtAsset).safeTransferFrom(msg.sender, address(this), debtToCover);

    IERC20(debtAsset).safeApprove(pool, debtToCover);

    ILendingPool(pool).liquidationCall(
      collateralAsset,
      debtAsset,
      borrower,
      debtToCover,
      receiveAToken
    );
  }

  function fundLiquidateAndSell(
    address pool,
    address collateralAsset,
    address debtAsset,
    address borrower,
    uint256 debtToCover,
    bool receiveAToken
  ) external {
    IERC20(debtAsset).safeTransferFrom(msg.sender, address(this), debtToCover);

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

    uint256 amountMin = getAmountOutMin(collateralAsset, debtAsset, newBalance);

    swap(collateralAsset, debtAsset, newBalance, amountMin, address(this));
  }

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

    console.log("after flash loan");
  }

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
    console.log("in excecution");
    IERC20(debtAsset).safeApprove(pool, debtToCover);
    ILendingPool(pool).liquidationCall(collateralAsset, debtAsset, borrower, debtToCover, false);

    uint256 newBalance = IERC20(collateralAsset).balanceOf(address(this));
    IERC20(collateralAsset).safeApprove(v2Router02, newBalance);
    uint256 amountMin = getAmountOutMin(collateralAsset, debtAsset, newBalance);
    swap(collateralAsset, debtAsset, newBalance, amountMin, address(this));

    IERC20(debtAsset).safeApprove(lendingPool, 2 * debtToCover);

    return true;
  }

  function ADDRESSES_PROVIDER() external view returns (ILendingPoolAddressesProvider) {
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

    uint256[] memory amountOutMins = IUniswapV2Router02(v2Router02).getAmountsOut(_amountIn, path);
    return amountOutMins[path.length - 1];
  }
}
