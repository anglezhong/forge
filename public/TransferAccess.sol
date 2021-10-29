//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "./Ownable.sol";


contract TransferAccess is AccessControl, Ownable {

    bytes32 internal constant TRANSFER_ROLE = keccak256("TRANSFER_ROLE");
    bool private _enable;

    constructor (bool enable) {
        _enable = enable;
        address msgSender = _msgSender();
        super._setRoleAdmin(TRANSFER_ROLE, DEFAULT_ADMIN_ROLE);
        super._setupRole(TRANSFER_ROLE, msgSender);
        super._setupRole(DEFAULT_ADMIN_ROLE, msgSender);
    }

    /**
     * @dev Returns true if the contract is recipient access status, and false otherwise.
     */
    function transferAccessStatus() public view returns (bool) {
        return _enable;
    }

    function enableTransferAccess() public onlyOwner {
        _enable = true;
    }

    function disableTransferAccess() public onlyOwner {
        _enable = false;
    }

    function hasTransferRole(address account) public view returns(bool) {
        return super.hasRole(TRANSFER_ROLE, account);
    }

    function setupTransferRole(address account) public onlyOwner {
        super._setupRole(TRANSFER_ROLE, account);
    }

    function revokeTransferRole(address account) public onlyOwner {
        super.revokeRole(TRANSFER_ROLE, account);
    }

    modifier transferable(address recipient, address sender) {
        if (_enable) {
            require(hasTransferRole(recipient) || hasTransferRole(sender), "TransferAccess: recipient and sender do not have the transfer role");
        }
        _;
    }
}
