pragma solidity ^0.5.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/token/ERC721/ERC721Full.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v2.5.0/contracts/ownership/Ownable.sol";
import "./PersonalityAuction.sol";

contract PersonalityMarket is ERC721Full, Ownable {

    constructor() ERC721Full("PersonalityMarket", "PERS") public {}
    using Counters for Counters.Counter;
    Counters.Counter token_ids;
    
    struct Personality {
        string temperments;
        string types;
    }

    address payable deployer= msg.sender;

    mapping(uint => PersonalityAuction) public auctions;
    mapping(uint => Personality) public personality_pool;

    modifier personalityRegistered(uint token_id) {
        require(_exists(token_id), "Personality not registered!");
        _;
    }

    function addPersonality(address owner, string memory temperments, string memory types, string memory token_uri) public returns (uint) {
        token_ids.increment();
        uint token_id = token_ids.current();
        _mint(owner, token_id);
        _setTokenURI(token_id, token_uri);
        createAuction(token_id);
        
        personality_pool[token_id] = Personality(temperments, types);
        
        return token_id;
    }

    function createAuction(uint token_id) public onlyOwner {
        auctions[token_id] = new PersonalityAuction(deployer);
    }

    function endAuction(uint token_id) public onlyOwner personalityRegistered(token_id) {
        PersonalityAuction auction = auctions[token_id];
        auction.auctionEnd();
        safeTransferFrom(owner(), auction.highestBidder(), token_id);
    }

    function auctionEnded(uint token_id) public view returns(bool) {
        PersonalityAuction auction = auctions[token_id];
        return auction.ended();
    }

    function highestBid(uint token_id) public view personalityRegistered(token_id) returns(uint) {
        PersonalityAuction auction = auctions[token_id];
        return auction.highestBid();
    }

    function pendingReturn(uint token_id, address sender) public view personalityRegistered(token_id) returns(uint) {
        PersonalityAuction auction = auctions[token_id];
        return auction.pendingReturn(sender);
    }

    function bid(uint token_id) public payable personalityRegistered(token_id) {
        PersonalityAuction auction = auctions[token_id];
        auction.bid.value(msg.value)(msg.sender);
    }

}