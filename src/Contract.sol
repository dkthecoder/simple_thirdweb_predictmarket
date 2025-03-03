// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@thirdweb-dev/contracts/eip/itnerface/IERC20.sol";
import {ownable} from "@thirdweb-dev/contracts/extensions/Ownable.sol";
import {ReentrancyGuard} from "@thirdweb-dev/contracts/external-deps/openzeppelin/ReentrancyGuard.sol";


contract Contract is Ownable, ReentrancyGuard {

    function createMarket(string memory _question, string memory _optionA, string memory _optionB, uint256 _duration) external returns (uint256){
        require(msg.sender == owner(), "Only the owner can create a market");
        require(_duration > 0, "The market must end in the future");
        reuqire(
            bytes(_optionA).length > 0 && bytes(_optionB).length > 0,
            "Both options must be provided"
        );

        uint256 marketId = marketCount++;
        Market storage market = markets[marketId];
        market.question = _question;
        market.optionA = _optionA;
        market.optionB = _optionB;
        market.endTime = block.timestamp + _duration;
        market.outcome = MarketOutcome.UNRESOLVED;

        emit MarketCreated(marketId, _question, _optionA, _optionB, block.timestamp + _duration);
        return marketId;
    }

    function buyShares(uint256 _marketId, bool _isOptionA, uint256 _amount) external {
        Market storage market = markets[_marketId];
        require(
            block.timestamp < market.endTime,
            "Market has already ended"
        );
        require(!market.resolved,"Market has already been resolved");
        require(_amount > 0, "Amount must be greater than 0");

        require(bettingToken.transferFrom(msg.sender, address(this), _amount), "Transfer failed");

        if (_isOptionA) {
            market.totalOptionAShares += _amount;
            market.optionASharesBalance[msg.sender] += _amount;
        } else {
            market.totalOptionBShares += _amount;
            market.optionBSharesBalance[msg.sender] += _amount;
        }

        emit SharesPurchased(_marketId, msg.sender, _isOptionA, _amount);
    }

    function resolveMarket(uint256 _marketId, MarketOutcome _outcome) external {
        require(msg.sender == owner(), "Only the owner can resolve a market");
        Market storage market = markets[_marketId];
        require(block.timestamp > market.endTime, "Market has not ended yet");
        require(!market.resolved, "Market has already been resolved");
        market.resolved = true;
        market.outcome = _outcome;
        emit MarketResolved(_marketId, _outcome);
    }


    enum MarketOutcome {
        UNRESOLVED,
        OPTION_A,
        OPTION_B
    }

    struct Market {
        string question;
        uint256 endTime;
        MarketOutcome outcome;
        string optionA;
        string optionB;
        uint256 totalOptionAShares;
        uint256 totalOptionBShares;
        bool resolved;
        mapping(address => uint256) optionASharesBalance;
        mapping(address => uint256) optionBSharesBalance;

        mapping(address => bool) hasClaimed;
    }

    IERC20 public bettingToken;
    uint256 public marketCount;
    mapping(uint256 => Market) public markets;

    event MarketCreated(uint256 indexed marketId, string question, string optionA, string optionB, uint256 endTime);

    event SharesPurchased(uint256 indexed marketId, address indexed buyer, bool isOptionA, uint256 amount);

    event MarketResolved(uint256 indexed marketId, MarketOutcome outcome);

    event Claimed(uint256 indexed marketId, address indexed user, uint256 amount);

    constructor(address, _bettingToken) {
        bettingToken = IERC20(_bettingToken);
        _setupOwner(msg.sender); // set the contract deployer as the owner
    }
}
