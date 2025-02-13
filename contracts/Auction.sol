// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract Auction {
    error YouHaveAlreadyCommittedYourBid();

    struct BidDetails {
        uint256 amount;
        string bidderChoice;
        address payable bidder;
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
        address payable auctioneer;
    }

    uint256 public auctionStartTime;
    Auctioneer[] public eachAuction;
    BidDetails[] public eachBidDetails;
    mapping(uint256 => mapping(address => CommitBid)) public commit;
    mapping(uint256 => BidDetails) public eachBidder;
    mapping(uint256 => Auctioneer) public auction;

    modifier onlyBeforeTenMinutes() {
        require(block.timestamp <= auctionStartTime + 10 * 60, "Reveal period has ended");
        _;
    }

    function createAuction(string memory _item, uint256 _miniBidPrice, uint256 _endBidTime) external {
        require(bytes(_item).length > 0, "Item can't be empty");
        require(_miniBidPrice > 0, "Include a minimum price");
        require(_endBidTime > block.timestamp, "End time must be in the future");
        eachAuction.push(Auctioneer(_item, _miniBidPrice, block.timestamp, _endBidTime, payable(msg.sender)));
    }

    function makeABid(uint256 _bidId, uint256 _amount, string memory _bidderChoice) external {
        require(_amount > 0, "Bid amount can't be zero");
        require(bytes(_bidderChoice).length > 0, "Bid choice can't be empty");
        eachBidder[_bidId] = BidDetails(_amount, _bidderChoice, payable(msg.sender));
        eachBidDetails.push(eachBidder[_bidId]);
    }

    function bidCommit(uint256 _bidId, uint256 salt) public returns (bytes32 commits) {
        if (commit[_bidId][msg.sender].hash != 0) revert YouHaveAlreadyCommittedYourBid();
        bytes32 hashedBid = keccak256(abi.encodePacked(eachBidder[_bidId].bidderChoice, salt));
        commit[_bidId][msg.sender] = CommitBid(hashedBid, false);
        return hashedBid;
    }

    function auctionEnds(uint256 _bidId, uint256 salt) external onlyBeforeTenMinutes {
        require(block.timestamp >= auction[_bidId].endBidTime, "Auction time hasn't ended");
        require(eachBidder[_bidId].amount >= auction[_bidId].miniBidPrice, "Bid amount is below minimum price");
        require(keccak256(abi.encodePacked(eachBidder[_bidId].bidderChoice, salt)) == commit[_bidId][msg.sender].hash, "Bid does not match");
        commit[_bidId][msg.sender].revealed = true;
    }

    function winnerSelection(uint256 bidId) external {
        uint256 highestBid = 0;
        address payable winner;
        for (uint256 i = 0; i < eachBidDetails.length; i++) {
            if (eachBidDetails[i].amount > highestBid) {
                highestBid = eachBidDetails[i].amount;
                winner = eachBidDetails[i].bidder;
            }
        }
        require(winner != address(0), "No valid bids found");
        auction[bidId].auctioneer.transfer(highestBid);
        
    }

    
}
