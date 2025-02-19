// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IAuction {
    function createAuction(string memory _item, uint256 _miniBidPrice, uint256 _endBidTime) external;

    function commitBid(bytes32 _hash, uint256 _amount) external;

    function revealBid(uint256 _amount, uint256 _salt) external;

    function finalizeAuction() external;
}