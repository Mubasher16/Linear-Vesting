// SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
contract vesting {
    using Counters for Counters.Counter;
    Counters.Counter private lockId;
    constructor(){

    } 
    
    struct  lockValues{
        address claimAddress;
        IERC20 contractAddress;
        uint256 amount;
        uint256 lockingStartTime;
        uint256 lockingEndTime;
        uint256 alreadyTransferred;
        uint256 previousUnlockTime;
    }
    mapping(uint256 => lockValues) Information;
    mapping(address => uint256[]) Users;

    function lockTokens(address _claimAddress, IERC20 _contractAddress,uint256 _amount,uint256 _endTime, uint256 _startTime) external {
        require(msg.sender != address(0), "Invalid Address");
        require(_amount > 0, "Amount cannot be 0");
        uint256 id = lockId.current();
        Information[id] = lockValues({
        claimAddress: _claimAddress,
        contractAddress: _contractAddress,
        amount: _amount,
        lockingStartTime: _startTime,
        lockingEndTime: _endTime,
        previousUnlockTime: _startTime,
        alreadyTransferred: 0
        });
       Users[_claimAddress].push(id);
    
        IERC20(_contractAddress).transferFrom(msg.sender, address(this), _amount);
        lockId.increment();
    }
    function calculate(uint256 _id) private returns(uint256) {
        uint256 tokensToTransfer;
        uint256 vestingTime= Information[_id].lockingEndTime - Information[_id].lockingStartTime;
        uint256 unlockPerSecond= Information[_id].amount/vestingTime;
        if (block.timestamp<=Information[_id].lockingEndTime){
        tokensToTransfer= (block.timestamp- Information[_id].previousUnlockTime)*unlockPerSecond;
        Information[_id].previousUnlockTime=block.timestamp;
        Information[_id].alreadyTransferred+=tokensToTransfer;
        }
        else{
           tokensToTransfer= (Information[_id].lockingEndTime- Information[_id].previousUnlockTime)*unlockPerSecond; 
            Information[_id].previousUnlockTime=block.timestamp;
            Information[_id].alreadyTransferred+=tokensToTransfer;

        }
        return tokensToTransfer;
    }
    
     function claim( uint256 _id) external {
        lockValues memory info = Information[_id];
        require(msg.sender != address(0), "Invalid Address");
        require(msg.sender == info.claimAddress, "Invalid Address");
       // require(block.timestamp > info.unlockingTime, "Not allowed to claim right now");
       IERC20(info.contractAddress).transfer(info.claimAddress, calculate(_id));
      }

    function getVestingData( uint256 _id) external view returns(lockValues memory) {
            return Information[_id]; 
     }

    function getUserLock(address _address) public view returns(uint256[] memory) {
        return Users[_address];
    }

    function getUserTotalLockedAmount(address _address) external view returns(uint256){
        
        uint256[] memory locks= getUserLock(_address);
        uint256 lockedAmounts;
       for(uint256 i=0; i < locks.length; i++){
        lockedAmounts = lockedAmounts + Information[locks[i]].amount;
       }
       return lockedAmounts;

    }

     function getUserEachLockAmount(address _address) external view returns(uint256[] memory){
        
        uint256[] memory locks= getUserLock(_address);
        uint256[] memory lockedAmounts = new uint256[](locks.length); 
       for(uint256 i=0; i<locks.length; i++){
        lockedAmounts[i]=Information[locks[i]].amount;
       }
       return lockedAmounts;

    }

    function getUserAllLocks(address _address) external view returns(lockValues[] memory){
        
        uint256[] memory locks= getUserLock(_address);
        lockValues[] memory lockedAmounts = new lockValues[](locks.length);
       for(uint256 i = 0; i < locks.length; i++){
        lockedAmounts[i] = Information[locks[i]];
       }
       return lockedAmounts;
    }
}
