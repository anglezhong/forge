// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./public/ERC20.sol";
import "./public/MinterAccess.sol";

contract Angle is ERC20("Angle Finance", "Angle"), MinterAccess {
    uint256 public MaximumCirculation = 330000000 * 1e18;
    function mint(address _to, uint256 _amount) external onlyMinter {
        require(totalSupply() + _amount <= MaximumCirculation, "Exceed the maximum circulation");
        super._mint(_to, _amount);
    }
    function burn( uint256 _amount) external {
        super._burn(_msgSender(), _amount);
    }
}
