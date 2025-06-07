// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

contract Auction{
    struct Offer {
        address bidder;
        uint256 amount;
        bool deposited;
    }
    Offer[] private offers;
    mapping(address => uint256) deposits;
    mapping(address => uint256) amountOfOffers;

    event NewOffer(Offer indexed offer);
    event FinishAuction(address winner);

    address owner;
    uint256 minPrice;
    uint256 startTime;
    uint256 finishTime;

    constructor(uint256 _minPrice){
        startTime = block.timestamp;
        finishTime = startTime + 7 days;
        minPrice = _minPrice;
        owner = msg.sender;
    }

    modifier hasAnyOffer(){
        require(offers.length > 0, "No hay ofertas");
        _;
    }

    function winner() hasAnyOffer external view returns(Offer memory){
        return bestOffer();
    }

    function showOffers() hasAnyOffer external view returns (Offer[] memory){
        return offers;
    }

    function bestOffer() hasAnyOffer private view returns (Offer memory) {
        return offers[offers.length - 1];
    }

    modifier isActive(){
        require(block.timestamp < finishTime, "La subasta no esta activa");
        _;
    }

    modifier meetsInitialPrice(uint256 amount){
        require(amount > minPrice, "La oferta no cumple el valor minimo");
        _;
    }

    modifier meetsBetterAmount(uint256 amount){
        uint256 bestAmount = offers.length > 0 ? bestOffer().amount : minPrice; 
        require(
            amount >= bestAmount * 105 / 100, 
            "La oferta debe superar por lo menos un 5% a la oferta maxima."
        );
        _;
    }

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

    function handleOffer(Offer memory newOffer) private{
        offers.push(newOffer);
        deposits[msg.sender] += msg.value;
        amountOfOffers[msg.sender] += 1;
    }

    function handleFinishTime() private {
        if(block.timestamp > finishTime - 10 minutes){
            finishTime += 10 minutes;
        }
    }

    modifier isOwner(){
        require(msg.sender == owner, "Solo el owner puede ejecutar esta operacion");
        _;
    }


    modifier onlyAfterEnd(){
        require(block.timestamp >= finishTime, "Todavia no finalizo el periodo de subasta.");
        _;
    }

    function finishAuction() external isOwner onlyAfterEnd{
        address winnerAddress = bestOffer().bidder;
        for (uint256 i; i < offers.length; i++){
            if(offers[i].bidder != winnerAddress && deposits[offers[i].bidder] > 0){
                payable(offers[i].bidder).transfer(deposits[offers[i].bidder] * 98 / 100);
            }
        }
        emit FinishAuction(winnerAddress);
    }

    modifier hasMultipleOffers(){
        require(amountOfOffers[msg.sender] > 1, "No tiene la cantidad de ofertas necesarias para solicitar reembolso");
        _;
    }

    modifier hasDeposit(){
        require(deposits[msg.sender] > 0, "No tiene deposito");
        _;
    }

    function partialRefund() 
        external 
        hasDeposit 
        hasMultipleOffers{
        for(uint256 i = 0; i < offers.length; i++){
            if(offers[i].deposited && deposits[msg.sender] > offers[i].amount){
                handleRefound(i);
                break;
            }
        }
    }

    function handleRefound(uint256 index) private{
        payable(msg.sender).transfer(offers[index].amount);
        deposits[msg.sender] -= offers[index].amount;
        offers[index].deposited = false;
        amountOfOffers[msg.sender] -= 1;
    }

    receive() external payable {
        revert("Usa bid() para participar en la subasta");
    }
}
