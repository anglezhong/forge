//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./public/Pausable.sol";
import "./public/MinterAccess.sol";
import "./public/SafeToken.sol";
import "./public/ReentrancyGuard.sol";


contract Forge is Pausable, Ownable, MinterAccess, ReentrancyGuard {
    
    using SafeToken for address;

    address public FIL;
    address public stkFIL;
    uint256 public expScale = 1e18;

    // a[n]= d(hfil)/totalSfil + a[n-1]
    uint256[] public cumulativeNetWorths;
    
    uint256 public currentDeposit;

    uint256 public totalStkFILBalance;
    
    uint256 public T = 1;

    struct UserInfo {
        uint256 rewardDebt;
        uint256 cumulative;
        uint256 balance;
        uint256 currentDeposit;
        uint256 depositPeriod;
    }

    mapping(address => UserInfo) public userInfo;

    event Settlement(uint256 indexed period, uint256 totalDopsited, uint256 currentDeposit,uint256 filBalance);

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event ClaimFIL(address indexed user, uint256 amount);

    constructor(
        address _fil,
        address _stkFIL
    ) {
        FIL = _fil;
        stkFIL = _stkFIL;
        cumulativeNetWorths.push(expScale);
    }

    function setT(uint256 _t) public onlyOwner {
        T = _t;
    }

    function totalPeriod() public view returns(uint256) {
        return cumulativeNetWorths.length;
    }

    function cumulative( ) public view returns(uint256) {
        return cumulativeNetWorths[totalPeriod() - 1];
    }

    function deposit(uint256 _amount) external nonReentrant {
        stkFIL.safeTransferFrom(_msgSender(), address(this), _amount);
        currentDeposit += _amount;
        UserInfo storage user = checkUserInfo(_msgSender());
        user.currentDeposit += _amount;
        user.depositPeriod = totalPeriod() + T;
        emit Deposit(_msgSender(), _amount);
    }

    function withdraw(uint256 _amount) external nonReentrant {
        claimFIL();
        UserInfo storage user = checkUserInfo(_msgSender());
        uint256 _a = _amount;
        if ( user.currentDeposit >= _amount ) {
            user.currentDeposit -= _amount;
            currentDeposit -= _amount;
        } else {
            
            uint256 _currentDeposit = currentDeposit - user.currentDeposit;
            
            _amount -= user.currentDeposit;
            user.balance -= _amount;
            user.currentDeposit = 0;
            
            if ( _currentDeposit >= _amount ) {
                currentDeposit = _currentDeposit - _amount;
            } else {
                totalStkFILBalance -= (_amount - _currentDeposit);
                currentDeposit = 0;
            }
        }
        stkFIL.safeTransfer(_msgSender(), _a);
        emit Withdraw(_msgSender(), _a);
    }

    function claimFIL() public returns(uint256 rewardDebt) {
        UserInfo storage user = checkUserInfo(_msgSender());
        rewardDebt = user.rewardDebt;
        user.rewardDebt = 0;
        FIL.safeTransfer(_msgSender(), rewardDebt);
        emit ClaimFIL(_msgSender(), rewardDebt);
    }

    function filEarned(address _account) view public returns(UserInfo memory) {
        return _checkUserInfo(_account);
    } 

    function productionInterest(uint256 _filNumber) public onlyMinter {
        FIL.safeTransferFrom(_msgSender(), address(this), _filNumber);
        uint256 _cumulative = 0;
        if ( totalStkFILBalance > 0 ) {
            _cumulative = _filNumber * expScale / totalStkFILBalance;
        }
        cumulativeNetWorths.push(
            cumulative() + _cumulative
        );
        emit Settlement(totalPeriod(), totalStkFILBalance, currentDeposit, _filNumber);
        totalStkFILBalance += currentDeposit;
        currentDeposit = 0;
    }

    function _checkUserInfo(address _user) internal view returns(UserInfo memory user){
        user = userInfo[_user];
        if ( stkFIL.myBalance() > 0) {
            uint256 _cumulativeExpScale = cumulative();
            user.rewardDebt += (_cumulativeExpScale - (user.cumulative)) * user.balance / expScale ;
            user.cumulative = _cumulativeExpScale;
            if ( user.currentDeposit > 0 && totalPeriod() >= user.depositPeriod ) {
                user.rewardDebt += (_cumulativeExpScale - cumulativeNetWorths[user.depositPeriod - 1]) * user.currentDeposit / expScale;
                user.balance += user.currentDeposit;
                user.currentDeposit = 0;
            }
        }
    }
    function checkUserInfo(address _user) internal returns(UserInfo storage) {
        userInfo[_user] = _checkUserInfo(_user);
        return userInfo[_user];
    }
}