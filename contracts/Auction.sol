// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Auction {
    using SafeERC20 for IERC20;

    error YouHaveAlreadyCommittedYourBid();
    error TransactionFailed(string debug);
    event Debug();

    struct BidDetails {
        uint256 amount;
        address bidder;
    }

    struct CommitBid {
        bytes32 hash;
        bool revealed;
    }

    struct Auctioneer {
        string item;
        uint256 miniBidPrice;
        uint256 startBidTime;
        uint256 endBidTime;
        address auctioneer;
    }

    IERC20 public _token;
    IERC20 public _token2;
    Auctioneer public auction;
    BidDetails[] public bids;
    mapping(address => CommitBid) public commitments;
    mapping(address => bool) public refunded;

    event AuctionCreated(string item, uint256 miniBidPrice, uint256 endBidTime);
    event BidCommitted(bytes32 hash, uint256 amount, address bidder);
    event BidRevealed(uint256 amount, uint256 salt, address bidder);
    event AuctionFinalized(address winner, uint256 highestBid);

    uint256 public startPrice;
    uint256 public endPrice;
    uint256 public startTime;
    uint256 public duration;

    modifier onlyBeforeEnd() {
        require(block.timestamp < auction.endBidTime, "Auction already ended");
        _;
    }

    modifier onlyAfterEnd() {
        require(block.timestamp >= auction.endBidTime, "Auction not yet ended");
        _;
    }

    constructor(address tokenAddress, address tokenAddress2, uint256 _startPrice, uint256 _endPrice, uint256 _duration, uint256 _startTime) {
         require(_startPrice > _endPrice, "Start price must be higher than end price");
         require(_duration > 0, "Duration must be greater than 0");

        startPrice = _startPrice;
        endPrice = _endPrice;
        duration = _duration;
        startTime = block.timestamp;
        
        _token = IERC20(tokenAddress);
        _token2 = IERC20(tokenAddress2);
        startTime = _startTime;
    }


    function getCurrentPrice() public view returns (uint256) {
        if (block.timestamp >= startTime + duration) {
            return endPrice; // Minimum price reached
        }

        uint256 timeElapsed = block.timestamp - startTime;
        uint256 priceDecrease = ((startPrice - endPrice) * timeElapsed) / duration;
        return startPrice - priceDecrease;
    }

    function createAuction(string memory _item, uint256, uint256 _endBidTime) external {
        uint256 getCurrentAuctionPrice =  getCurrentPrice();
        require(bytes(_item).length > 0, "Item can't be empty");
        require(getCurrentAuctionPrice > 0, "Minimum bid price must be positive");
        require(_endBidTime > block.timestamp, "End time must be in the future");
        uint256 currentPrice = getCurrentPrice();
        auction = Auctioneer(_item, currentPrice, block.timestamp, _endBidTime, msg.sender);
        emit AuctionCreated(_item, getCurrentAuctionPrice, _endBidTime);
    }

    function commitBid(bytes32 _hash, uint256 _amount) external onlyBeforeEnd {
        require(commitments[msg.sender].hash == 0, "Bid already committed");
        commitments[msg.sender] = CommitBid(_hash, false);
        bids.push(BidDetails(_amount, msg.sender));
        uint256 contractBalanceForTokenA = _token.balanceOf(address(this));
        uint256 contractBalanceForTokenB = _token2.balanceOf(address(this));  
        _token.safeTransferFrom(msg.sender, address(this), contractBalanceForTokenA);
        _token.safeTransferFrom(msg.sender, address(this), contractBalanceForTokenB);
        emit BidCommitted(_hash, _amount, msg.sender);
        
    }

    function revealBid(uint256 _myPrice, uint256 _salt) external onlyAfterEnd {

        CommitBid storage commitData = commitments[msg.sender];
        require(commitData.hash != 0, "No bid committed");
        require(!commitData.revealed, "Bid already revealed");
        require(keccak256(abi.encodePacked(_myPrice, _salt)) == commitData.hash, "Invalid bid reveal");
        commitData.revealed = true;
        emit BidRevealed(_myPrice, _salt, msg.sender);
    }

    function finalizeAuction() external onlyAfterEnd {
        uint256 highestBid = 0;
        address winner;

        for (uint256 i = 0; i < bids.length; i++) {
            if (commitments[bids[i].bidder].revealed && bids[i].amount > highestBid) {
                highestBid = bids[i].amount;
                winner = bids[i].bidder;
            }
        }

        require(highestBid >= auction.miniBidPrice, "No valid bids met minimum price");
        _token.safeTransfer(auction.auctioneer, highestBid);
        emit AuctionFinalized(winner, highestBid);

        for (uint256 i = 0; i < bids.length; i++) {
            if (bids[i].bidder != winner && !refunded[bids[i].bidder]) {
                refunded[bids[i].bidder] = true;
                _token.safeTransfer(bids[i].bidder, bids[i].amount);
            }
        }
    }
}
