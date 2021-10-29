//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./public/ERC20.sol";
import "./public/Pausable.sol";
import "./public/TransferAccess.sol";
import "./public/MinterAccess.sol";
import "./public/SafeToken.sol";


contract StkFil is ERC20, Pausable, Ownable, MinterAccess {
    
    using SafeToken for address;
    

    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    address public FIL;
    address public admin_fee;
    uint256 private _admin_balnace;
    
    uint16 public fee = 1000;
    
    event Released(address indexed _from, address indexed _to, uint256 amount, bytes data);
    event Minted(address indexed _from, address indexed _to, uint256 amount);
    
    modifier onlyOperator() {
        require(hasRole(OPERATOR_ROLE, _msgSender()), "onlyOperator: sender do not have the operator role");
        _;
    }

    constructor (
        address _fil,
        address _operator,
        address _admin_fee
    )
    ERC20("zhonglian Staked FIL", "stkFIL") {
        FIL = _fil;
        super._setupRole(OPERATOR_ROLE, _operator);
        admin_fee = _admin_fee;
    }

    // staked FIL
    function stakeFIL(uint256 _amounts) external {
        _stakeFIL(msg.sender, _amounts);
    }

    function _stakeFIL(address _form, uint256 _amounts) internal {
        FIL.safeTransferFrom(_form, address(this), _amounts);
        super._mint(_form, _amounts);
        _admin_balnace += _amounts * fee / 10000;
    }
    
    function mint(address recipient, uint256 amount) external onlyMinter {
        super._mint(recipient, amount);
        emit Minted(address(0), recipient, amount);
    }
    
    function withdraw() external onlyOperator {
        FIL.safeTransfer(_msgSender(), FIL.myBalance());
    }

    function withdraw_fee() external onlyOperator {
        super._mint(admin_fee,_admin_balnace);
        _admin_balnace = 0;
    }

    function setFee(uint16 _fee) external onlyOperator {
        fee = _fee;
    }

    function setAdminFee(address _admin_fee) external onlyOperator {
        admin_fee = _admin_fee;
    }
    
    function setOperator(address _operator) external onlyMinter {
        super._setupRole(OPERATOR_ROLE, _operator);
    }
}