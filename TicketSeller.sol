pragma solidity ^0.4.15;
////////////////////////////////////////////////////////////////////////////////////////////
// Author: Leandro Fortunato 
// File version: 1.0.0         Release Date: 2017-11-22
// Doubts, suggestions send me an e-mail: fortunato.c77@gmail.com
// This is a configurable contract for selling tickets
// It has support for selling 3 kinds of tickets Platinum, Gold and Silver.
// This contract also support refund, this operation should be allowed by the Contract Owner.
// Once the refund is allowed the Purchaser should claim his refund.
// The contract itself does not send the cash back, its upt  to the Purchaser to claim his credits
// Feel free to use this source code by your own risk
////////////////////////////////////////////////////////////////////////////////////////////

	
contract TicketSeller{
    
    struct Ticket{
        uint NumberOfTickets;
        uint Value;

    }
    Ticket private TicketPlatinum;
    Ticket private TicketGold;
    Ticket private TicketSilver;
    
    enum TicketTypes { _Platinum, _Gold, _Silver}
    address private ContractOwner;
    
    struct SalesDetail{
        uint StardDate;   // Start date for selling
        uint FinishDate;  // Last date for selling
    }
    
	///////////////////////////////////////////////////////////
	//This struct controls the tickets bough by a purchaser
	///////////////////////////////////////////////////////////   
   struct TicketsBought{  
       uint NumOFtickets;   	// Total number of the same tickets bought
       uint ValuePaid;			// Actual value paid, once value supports changes during the selling period.
       bool boAllowedRefund; 	// This flag allows the Credit to be refund;
       uint ValuetoRefund; 		// Holds the value to be refund
   }


	///////////////////////////////////////////////////////////
	//This struct holds an array for every ticket types in this case 
	// 3 arrays --> Platinum,Gold and Silver;
	///////////////////////////////////////////////////////////   
	struct BuyerDat{
        TicketsBought[3] ticketBought;
    }
	
    ///////////////////////////////////////////////////////////   
    // This declares a variable to store a `BuyerData` struct for 
	// every possible address (Purchaser).
	///////////////////////////////////////////////////////////   
    mapping(address => BuyerDat) private BuyerData;

    
    SalesDetail SalesDetails;
	
    ////////////////////////////////////////////////////////////////////////////////////////////
    // This verification only allows contratct owner to setup the Ticket Selling
    ////////////////////////////////////////////////////////////////////////////////////////////
    modifier IsContractOwner(){
        if(msg.sender != ContractOwner)
            revert();
        else
            _;
    }

     ////////////////////////////////////////////////////////////////////////////////////////////
    // This verification only allows buying tickets during the sales period
    ////////////////////////////////////////////////////////////////////////////////////////////
    modifier IsSalesOpen(){
        if((SalesDetails.StardDate <= now) &&( SalesDetails.FinishDate >= now))
            revert();
        else
            _;
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////
    // Constructor
    ////////////////////////////////////////////////////////////////////////////////////////////
    function TicketSeller () {
        ContractOwner= msg.sender;
    }

    ////////////////////////////////////////////////////////////////////////////////////////////
	// The Sales setup function allows Contract Owner to start or update the tickets amounts,
	// values and selling period
	// For this example the tickets are sold in etherium units, but can easily set to wei, finney
	// or szabo
    ////////////////////////////////////////////////////////////////////////////////////////////          
    function SalesSetup(uint Platinum, uint PlatinumValue,uint Gold, uint GoldValue, uint Silver, uint SilverValue, uint DaysSelling) IsContractOwner() returns (bool){
        TicketPlatinum.NumberOfTickets= Platinum;
        TicketPlatinum.Value=(PlatinumValue * 1 ether);

        TicketGold.NumberOfTickets= Gold;
        TicketGold.Value=(GoldValue * 1 ether);

        TicketSilver.NumberOfTickets= Silver;
        TicketSilver.Value=(SilverValue * 1 ether);
        
        SalesDetails.StardDate= (now * 1 days);
        SalesDetails.FinishDate = (now + DaysSelling * 1 days);
    }
	
    ////////////////////////////////////////////////////////////////////////////////////////////
	// This function shows the ticket status, how many left and the actual value for it.
	// The parameter TicketType tells to function what kind of ticket to consult.
    ////////////////////////////////////////////////////////////////////////////////////////////       
    function GetTicketStatus (TicketTypes TicketType) constant returns (uint TicketsAvailable, uint Value){
        
        if (TicketType == TicketTypes._Platinum ){
                TicketsAvailable=TicketPlatinum.NumberOfTickets;
                Value=TicketPlatinum.Value;
        }
        else if (TicketType == TicketTypes._Gold) {
            TicketsAvailable=TicketGold.NumberOfTickets;
            Value=TicketGold.Value;
        }
        
        else if (TicketType == TicketTypes._Silver){
            TicketsAvailable=TicketSilver.NumberOfTickets;
            Value=TicketSilver.Value;
        }
        else{
            revert();
        }
        return (TicketsAvailable, Value);
    }
    
   ////////////////////////////////////////////////////////////////////////////////////////////
   // The function BuyTickets lets the purchaser choose the kind and the amount of ticket he wants to buy
   // The function supports only one kind of ticket per call.
   // Purshaser only is allowed to buy tickets if the Sales is already open.
   // To buy the tickets the value sent must be the exact value, according to amount and kind of ticket
   ////////////////////////////////////////////////////////////////////////////////////////////       
    function BuyTickets(TicketTypes TicketType,uint amount)  IsSalesOpen() payable {
	BuyerDat storage buyer = BuyerData[msg.sender];
        if (TicketType == TicketTypes._Platinum ){
                if((TicketPlatinum.NumberOfTickets>= amount) && ( msg.value == (amount * TicketPlatinum.Value ))){
					buyer.ticketBought[uint256(TicketTypes._Platinum)].NumOFtickets += amount;
					buyer.ticketBought[uint256(TicketTypes._Platinum)].ValuePaid= TicketPlatinum.Value;
					TicketPlatinum.NumberOfTickets-=amount;
				}
                else{
				revert();
				}
        }
        else if (TicketType == TicketTypes._Gold) {
                 if((TicketGold.NumberOfTickets>= amount) && ( msg.value == (amount * TicketGold.Value ))){
					buyer.ticketBought[uint256(TicketTypes._Gold)].NumOFtickets += amount;
					buyer.ticketBought[uint256(TicketTypes._Gold)].ValuePaid= TicketGold.Value;
					TicketGold.NumberOfTickets-=amount;
				}
                else{
				revert();
				}
        }
        
        else if (TicketType == TicketTypes._Silver){
                if((TicketSilver.NumberOfTickets>= amount) && ( msg.value == (amount * TicketSilver.Value ))){
					buyer.ticketBought[uint256(TicketTypes._Silver)].NumOFtickets += amount;
					buyer.ticketBought[uint256(TicketTypes._Silver)].ValuePaid= TicketSilver.Value;
					TicketSilver.NumberOfTickets-=amount;
				}
                else{
				revert();
				}
        }
        else{
            revert();
        }
    }
    ////////////////////////////////////////////////////////////////////////////////////////////
	// The contract onwer can allows the refund for purchaser Claimant
	// The refund is only allowed after passing the folling checks:
	// Only the contract Owner can call CheckRefund function
	//	The number if tickets to return must be lesser or equal than the amount of the ticket bought
	// The ticket to return must be the same kind of ticket bought
	// The value to return must be lesser or equal to contract balance
	// The value to be returned must be the same spent, even the tickets values has been changed since 
	// the Claimant last purchase
    ////////////////////////////////////////////////////////////////////////////////////////////       
    function CheckRefund(address Claimant, TicketTypes TicketType, uint NumOfTicketstoReturn) IsContractOwner ()  IsSalesOpen() returns (bool ReadtoRefund){
         uint CalcValue;
         BuyerDat storage buyer = BuyerData[Claimant];
         if(buyer.ticketBought[uint256(TicketType)].NumOFtickets >=NumOfTicketstoReturn){
             CalcValue = NumOfTicketstoReturn * buyer.ticketBought[uint256(TicketType)].ValuePaid;
             if (CalcValue <= this.balance){
                 buyer.ticketBought[uint256(TicketType)].ValuetoRefund = CalcValue;
                 buyer.ticketBought[uint256(TicketType)].NumOFtickets -= NumOfTicketstoReturn;
                 
                if (TicketType == TicketTypes._Platinum ){
                        TicketPlatinum.NumberOfTickets+=NumOfTicketstoReturn;
                }
                else if (TicketType == TicketTypes._Gold) {
                         TicketGold.NumberOfTickets+=NumOfTicketstoReturn;
                }
                else if (TicketType == TicketTypes._Silver){
                     TicketSilver.NumberOfTickets+=NumOfTicketstoReturn;  
                }
                 
                 buyer.ticketBought[uint256(TicketType)].boAllowedRefund=true;
                 return true;
             }
         }
         return false;
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////
	// Once the refund has been accepted, Claimant can get his credits back;
    // The function checks all the possible tickets to be refunded and transfer the total amount
	// available.
	////////////////////////////////////////////////////////////////////////////////////////////       
    function ClaimRefund()  IsSalesOpen() returns (bool Sucess){
        BuyerDat storage buyer = BuyerData[msg.sender];
		uint	ValuetoRefund=0;
		if (buyer.ticketBought[uint256(TicketTypes._Platinum)].boAllowedRefund==true){
			buyer.ticketBought[uint256(TicketTypes._Platinum)].boAllowedRefund=false;
			ValuetoRefund+= buyer.ticketBought[uint256(TicketTypes._Platinum)].ValuetoRefund;
		}
		if (buyer.ticketBought[uint256(TicketTypes._Gold)].boAllowedRefund==true){
			buyer.ticketBought[uint256(TicketTypes._Gold)].boAllowedRefund=false;
			ValuetoRefund+= buyer.ticketBought[uint256(TicketTypes._Gold)].ValuetoRefund;		
		
		}
		if (buyer.ticketBought[uint256(TicketTypes._Silver)].boAllowedRefund==true){
			buyer.ticketBought[uint256(TicketTypes._Silver)].boAllowedRefund=false;
			ValuetoRefund+= buyer.ticketBought[uint256(TicketTypes._Silver)].ValuetoRefund;
		}
		
		if(ValuetoRefund >0){
			msg.sender.transfer(ValuetoRefund);
			return true;
		}
		else{
		    return false;
		}
    }
}
