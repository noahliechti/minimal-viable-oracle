// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./IOracle.sol";

contract CardsClient is IOracle {

    address public owner;
    address payable public oracle;
    bytes2[] public cards;
    uint32 public pendingRequestId;
        
    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    constructor(address payable _oracle) {
        owner = msg.sender;
        oracle = _oracle;
    }

    function drawNCardsWithShuffle(uint8 _nrOfCards) public payable returns (uint32){
        return drawNCards(_nrOfCards, true);
    }

    function drawNCardsWithoutShuffle(uint8 _nrOfCards) public payable returns (uint32){
        return drawNCards(_nrOfCards, false);
    }

    function drawNCards(uint8 _nrOfCards, bool shuffle) internal returns (uint32){
        require(pendingRequestId == 0, "There is already a pending request");
        require(_nrOfCards > 0 && _nrOfCards < 53, "Draw at least one card"); // A card deck has 52 cards
        
        Request memory request = Request(_nrOfCards, shuffle, address(this), this.fulfill.selector, false);
        (bool success, bytes memory data) = oracle.call{value: msg.value}(abi.encodeWithSignature("receiveRequest((uint8,bool,address,bytes4,bool))", request));
    
        if(!success) {
            pendingRequestId = 0;
            revert("Call to Oracle was not successful");
        }
       
        return pendingRequestId = abi.decode(data, (uint16));
    }

    function fulfill(uint32 _requestId, bytes2[] calldata _cards) external {
        require(msg.sender == oracle, "Caller is not the oracle");
        require(_requestId == pendingRequestId, "Invalid request id");

        // TODO: event
        pendingRequestId = 0;
        cards = _cards;
    }

    function setOracle(address payable _oracle) external onlyOwner {
        oracle = _oracle;
    }

    function withdraw(address payable _to) external onlyOwner {
        (bool success,) = _to.call{value: address(this).balance}("");
        require(success, "Withdrawal failed");
    }
}

