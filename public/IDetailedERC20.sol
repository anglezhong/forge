//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import './IERC20.sol';

interface IDetailedERC20 is IERC20 {
  function name() external returns (string memory);
  function symbol() external returns (string memory);
  function decimals() external returns (uint8);
}