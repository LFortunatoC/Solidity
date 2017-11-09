////////////////////////////////////////////////////////////////////////////////////////////
// Author: Leandro Fortunato 
// File version: 1.0.0         Release Date: 2017-11-08
// Doubts, suggestions send me an e-mail: fortunato.c77@gmail.com
// This is my First Contratc I'm learning solidity from very beginning.
// This source code based on a YouTube fromvideo example from David Kajpust 
// @ https://www.youtube.com/watch?v=T-FsPDV5VCE
// I added samll improvements like:
// An event to export the winner address and his Prize
// A function to get the Last winner and the last Prize
// The function "IsGameSet" tell us whether player1 and player2 has already registered
// and also whether player1 has made his choice.
// Feel free to use this source code by your own risk
// This is a simple contract to handle Paper-Rock-Scissors where two playes put their bets after
// being registred.
////////////////////////////////////////////////////////////////////////////////////////////

pragma solidity ^0.4.15;

contract FirstBet{
    mapping (string =>mapping(string =>int)) payoffMatrix;
    
    address player1;
    address player2;
    address LastWinner;
    
    string public player1Choice;
    string public player2Choice;

    uint amount;
    uint LastPrize;

    event BetEnded(address winner, uint amount);
    
    //constructor function
    function FirstBet(){
        payoffMatrix["rock"]["rock"] =0;
        payoffMatrix["rock"]["paper"] =2;
        payoffMatrix["rock"]["scissors"] =1;
        payoffMatrix["paper"]["rock"] =1;
        payoffMatrix["paper"]["paper"] =0;
        payoffMatrix["paper"]["scissors"] =2;
        payoffMatrix["scissors"]["rock"] =2;
        payoffMatrix["scissors"]["paper"] =1;
        payoffMatrix["scissors"]["scissors"] =0;
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////
    // This verification avoids same sender to play as player1 and player2
    ////////////////////////////////////////////////////////////////////////////////////////////

    modifier notRegisteredYet(){
        if(msg.sender == player1 || msg.sender==player2)
            revert();
        else
            _;
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////
    // Check for enough Cash, 
    // Further Improvement suggestion:  Only accepts a limited range of value in order to avoid a player win
    // a disporportionaol Prize comparade to the amount he sent in order to play
    ////////////////////////////////////////////////////////////////////////////////////////////
    modifier sentEnoughCash(uint amount){
        if (msg.value < amount)
            revert();
        else
            _;
    }
    
    ////////////////////////////////////////////////////////////////////////////////////////////
    // Before putting the bet is necesasary to register
    ////////////////////////////////////////////////////////////////////////////////////////////
    
    function register() payable notRegisteredYet() sentEnoughCash (5 wei){
        if(player1 ==0)
            player1 = msg.sender;
        else if (player2 ==0)
            player2= msg.sender;
   }
   
   ////////////////////////////////////////////////////////////////////////////////////////////
   // Player Chooses and put his bet
   ////////////////////////////////////////////////////////////////////////////////////////////
   function play (string choice) returns (uint w){
       if(msg.sender==player1)
            player1Choice=choice;
        else if (msg.sender == player2)
            player2Choice = choice;
        if (bytes(player1Choice).length !=0 && bytes(player2Choice).length !=0 ) {
            int winner = payoffMatrix[player1Choice][player2Choice];
            amount= this.balance;
            LastPrize= amount;
            if(winner == 1){
                LastWinner = player1;
                player1.transfer(amount);   
            
            }
            else if (winner ==2){
                player2.transfer(amount);
                LastWinner = player2;
            }
            else {
                amount= amount/2;
                LastPrize = amount;
                LastWinner= 0;
                player1.transfer(amount);
                player2.transfer(amount);
                
            }
            
          
           ////////////////////////////////////////////////////////////////////////////////////////////
           //Reset the game by setting choices and addresses to "" and 0 
            ////////////////////////////////////////////////////////////////////////////////////////////    
            player1Choice = "";
            player2Choice = "";
            player1 = 0;
            player2 = 0;
            amount =0;
            
             
            BetEnded(LastWinner,LastPrize);  //
             
            return uint(winner);
              
        }
        else
            return uint(-1);
   }
   
    ////////////////////////////////////////////////////////////////////////////////////////////
    //Getter functions - used to call for data from blockchain does not write to blocblockchain
    ////////////////////////////////////////////////////////////////////////////////////////////

   function getContractBalance () constant returns (uint amount){
       return this.balance;
       
   }
  
   ////////////////////////////////////////////////////////////////////////////////////////////
   //Check current sender adrress is registred as player1 / player 2 or not registred
   ////////////////////////////////////////////////////////////////////////////////////////////
   function checkPlayer() constant returns (uint x){
       if (msg.sender == player1)
            return 1;
        else if (msg.sender == player2)                
            return 2;
       else
            return 0;
   }
   
   ////////////////////////////////////////////////////////////////////////////////////////////
   //Check if player1 and player2 is registred and also whether player1 as put his bet
   ////////////////////////////////////////////////////////////////////////////////////////////
   function IsGameSet () constant   returns (bool x) {
       return  (player1 != 0 && player2 !=0 && bytes(player1Choice).length != 0 );
   }
   
    ////////////////////////////////////////////////////////////////////////////////////////////
   //This function returns the LastWinner and the last prize, in case of tie LastEWinner returns with 0 
   // and LastPrize returns the value sent for each player
   ////////////////////////////////////////////////////////////////////////////////////////////
   function getLatWinner ()constant returns (address addLastWinner, uint value) {
       return (LastWinner, LastPrize);
   }
   
   
   
}
