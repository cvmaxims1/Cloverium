//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../interfaces/IHookCallee.sol";
import "../../voting/PoolVoting.sol";

contract VSPoolVoting is IHookCallee, PoolVoting {
    constructor(address exchangeFactory, address lp_) PoolVoting(exchangeFactory, lp_) {}

    function lpProductHarvest(address user) external override {}

    function lpProductUpdate(address user) external view override {
        require(userVotes[user] <= lp.balanceOf(user), "INSUFFICIENT_VOTE");
    }
}
