// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@thirdweb-dev/contracts/eip/itnerface/IERC20.sol";
import {ownable} from "@thirdweb-dev/contracts/extensions/Ownable.sol";
import {ReentrancyGuard} from "@thirdweb-dev/contracts/external-deps/openzeppelin/ReentrancyGuard.sol";


contract Contract is Ownable, ReentrancyGuard {
    enum MarketOutcome {
        UNRESOLVED,
        OPTION_A,
        OPTION_B
    }

    struct Market {
        string question;
        unit256 endTime;
        MarketOutcome outcome;
        string optionA;
        string optionB;
        unit256 totalOptionAShares;
        unit256 totalOptionBShares;
        bool resolved;
        mapping(address => unit256) optionASharesBalance;
        mapping(address => unit256) optionBSharesBalance;

        mapping(address => bool) hasClaimed;
    }

    IERC20 public bettingToken;
    uint256 public marketCount;
    mapping(uint256 => Market) public markets;

    event MarketCreated(uint256 indexed marketId, string question, string optionA, string optionB, uint256 endTime);

    event SharesPurchased(uint256 indexed marketId, address indexed buyer, bool isOptionA, unit256 amount);

    event MarketResolved(uint256 indexed marketId, MarketOutcome outcome);

    event Claimed(uint256 indexed marketId, address indexed user, unit256 amount);

    constructor() {}
}
