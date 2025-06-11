// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

contract Auction{
    address owner;
    uint256 minPrice;
    uint256 startTime;
    uint256 finishTime;
    mapping(address => uint256) deposits;
    mapping(address => uint256) amountOfOffers;
    struct Offer {
        address bidder;
        uint256 amount;
        bool deposited;
    }
    Offer[] private offers;

    event NewOffer(Offer indexed offer);
    event FinishAuction(address winner);
    event EmergencyWithdrawal(address, uint256);

    /// @notice Constructor that initializes the auction
    /// @param _minPrice The minimum price for the auction
    constructor(uint256 _minPrice){
        startTime = block.timestamp;
        finishTime = startTime + 2 hours;
        minPrice = _minPrice;
        owner = msg.sender;
    }

    // Modifiers

    /// @notice Modifier that ensures there is at least one offer
    modifier hasAnyOffer(){
        require(offers.length > 0, "No offers");
        _;
    }

    /// @notice Modifier that ensures the auction is still active
    modifier isActive(){
        require(block.timestamp < finishTime, "Inactive");
        _;
    }

    /// @notice Modifier that ensures the offer meets the initial price
    /// @param amount The offer amount
    modifier meetsInitialPrice(uint256 amount){
        require(amount > minPrice, "Minimum value not met");
        _;
    }
    
    /// @notice Modifier that ensures the offer is at least 5% higher than the current best offer
    /// @param amount The offer amount
    modifier meetsBetterAmount(uint256 amount){
        uint256 bestAmount = offers.length > 0 ? bestOffer().amount : minPrice; 
        require(amount >= bestAmount * 105 / 100, "Bid < 5%+");
        _;
    }

    /// @notice Modifier that ensures only the owner can call the function
    modifier isOwner(){
        require(msg.sender == owner, "Owner required");
        _;
    }

    /// @notice Modifier that ensures the auction has ended
    modifier onlyAfterEnd(){
        require(block.timestamp >= finishTime, "No end of auction period");
        _;
    }

    /// @notice Modifier that ensures the sender has made more than one offer
    modifier hasMultipleOffers(){
        require(amountOfOffers[msg.sender] > 1, "Need >1 offer");
        _;
    }

    /// @notice Modifier that ensures the sender has a deposit
    modifier hasDeposit(){
        require(deposits[msg.sender] > 0, "No deposit");
        _;
    }

    // External functions

    /// @notice Function to get the best (current) offer in the auction
    /// @return The best offer in the auction
    function winner() hasAnyOffer external view returns(Offer memory){
        return bestOffer();
    }

    /// @notice Function to view all offers in the auction
    /// @return An array of all the offers made
    function showOffers() hasAnyOffer external view returns (Offer[] memory){
        return offers;
    }

    /// @notice Function to place a bid in the auction
    /// @dev The bid must meet the initial price and be at least 5% higher than the current best offer
    function bid() 
        payable
        external     
        meetsInitialPrice(msg.value) 
        meetsBetterAmount(msg.value)
        isActive
    {
        handleFinishTime();
        Offer memory newOffer = Offer(msg.sender, msg.value, true);
        handleOffer(newOffer);
        emit NewOffer(newOffer);
    }

    /// @notice Function to finalize the auction and refund non-winning bidders
    /// @dev Only the owner can finalize the auction after it has ended
    function finishAuction() external isOwner onlyAfterEnd{
        uint256 numberOfBids = offers.length;
        uint256 amountToPay;
        address winnerAddress = bestOffer().bidder;
        address bidderToPay;

        for (uint256 i = 0;i < numberOfBids; i++){
            if(offers[i].bidder != winnerAddress && deposits[offers[i].bidder] > 0){
                bidderToPay = offers[i].bidder; 
                amountToPay = deposits[bidderToPay];
                payable(bidderToPay).transfer(amountToPay * 98 / 100);
            }
        }
        emit FinishAuction(winnerAddress);
    }

    /// @notice Function for partial refund of deposits to users with multiple offers
    /// @dev The refund is triggered if the user has more than one offer and a deposit
    function partialRefund() 
        external 
        hasDeposit 
        hasMultipleOffers{
        uint256 numberOfBids = offers.length;
        for(uint256 i  =0; i < numberOfBids; i++){
            if(offers[i].deposited && deposits[msg.sender] > offers[i].amount){
                handleRefound(i);
                break;
            }
        }
    }

    /// @notice Function for the owner to recover all ETH from the contract in case of an emergency.
    /// @dev Only the owner can call this function. It allows the owner to withdraw all ETH in the contract balance if needed.
    function emergencyWithdraw() external isOwner {
        uint256 balance = address(this).balance;
        
        require(balance > 0, "No ETH");
        
        payable(owner).transfer(balance);

        emit EmergencyWithdrawal(owner, balance);
    }

    // Internal functions

    /// @notice Function to get the best (last) offer in the auction
    /// @return The last offer made in the auction
    function bestOffer() hasAnyOffer private view returns (Offer memory) {
        return offers[offers.length - 1];
    }

    /// @notice Function to handle the insertion of a new offer
    /// @param newOffer The new offer to be added
    function handleOffer(Offer memory newOffer) private{
        offers.push(newOffer);
        deposits[msg.sender] += msg.value;
        amountOfOffers[msg.sender] += 1;
    }

    /// @notice Function to handle the extension of the finish time if the auction is nearing its end
    function handleFinishTime() private {
        if(block.timestamp > finishTime - 10 minutes){
            finishTime += 10 minutes;
        }
    }

    /// @notice Function to refund a user partially based on a specific offer
    /// @param index The index of the offer to refund
    function handleRefound(uint256 index) private{
        payable(msg.sender).transfer(offers[index].amount);
        deposits[msg.sender] -= offers[index].amount;
        offers[index].deposited = false;
        amountOfOffers[msg.sender] -= 1;
    }
    

    /// @notice Fallback function to prevent direct ETH transfers
    receive() external payable {
        revert("use bid() to participate");
    }    
}
