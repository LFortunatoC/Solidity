pragma solidity ^0.4.15;
////////////////////////////////////////////////////////////////////////////////////////////
// Author: Leandro Fortunato 
// File version: 1.0.0         Release Date: 2017-11-21
// Doubts, suggestions send me an e-mail: fortunato.c77@gmail.com
// This is a Simple Voting Smart Contract
// This source code based on Voting with delegation from Solidy documentation a dn can be found at 
// https://solidity.readthedocs.io/en/develop/solidity-by-example.html
// I added small modifications like:
// Removed support to delegation 
// Added a function in order to Contract Onwer add the list of itens that can be votted
// Added a function to export the partial voting results
// Feel free to use this source code by your own risk
////////////////////////////////////////////////////////////////////////////////////////////

	
contract Ballot {
 
    
        
	// This declares a new structure which will be used to represent a single voter.
    struct Voter {
        bool voted;  	    // if true, that person already voted
        uint vote;   	    // index of the voted proposal
        uint LastDateVoted;  //
    }

    // This is a type for a single candidate.
    struct Candidate {
        bytes32 name;   // short name (up to 32 bytes)
        uint voteCount; // number of accumulated votes
    }

    struct Election{
        uint DateofStart;
        uint DateofFinish;
        uint NumOfCandidates;
        bool ElectionRunning;
        
    }
    address private ContractOwner;

    // This declares a variable to store a `Voter` struct for each possible address.
    mapping(address => Voter) private voters;

    // A dynamically-sized array of `Candidate` structs.
    Candidate[]  Candidates;
   
    Election ElectionControl;
    
     ////////////////////////////////////////////////////////////////////////////////////////////
    // This verification only allows contratct owner to set the Election
    ////////////////////////////////////////////////////////////////////////////////////////////

    modifier IsContractOwner(){
        if(msg.sender != ContractOwner)
            revert();
        else
            _;
    }

     ////////////////////////////////////////////////////////////////////////////////////////////
    // This verification only allows votes during the election period
    ////////////////////////////////////////////////////////////////////////////////////////////

    modifier VotingNotEnded(){
        if(ElectionControl.DateofFinish < now)
            revert();
        else
            _;
    }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// Create a new ballot 
   //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   function Ballot()  {
        
        ContractOwner = msg.sender;
                    
        }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// This function as the name says kills the running election.
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function ResetElection ()  IsContractOwner() returns(bool){
        Candidates.length=0;
        ElectionControl.NumOfCandidates=0;
        ElectionControl.DateofFinish=0;
    }
    
     //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	 // This function runs only by the contract onwer, it sets up the election candidates, and the valid voting peroiod 
     //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
     function SetElection  (bytes32[] ItensNames, uint DaysAfter) IsContractOwner() returns(bool){
        // For each of the provided proposal names, create a new proposal object and add it to the end of the array.
        for (uint i = 0; i < ItensNames.length; i++) {
            // `Proposal({...})` creates a temporary Proposal object and `proposals.push(...)` appends it to the end of `proposals`.
            Candidates.push(Candidate({ name: ItensNames[i],voteCount: 0}));
            ElectionControl.NumOfCandidates++;
        }
        
        ElectionControl.DateofFinish = (now + DaysAfter *1 days);
        ElectionControl.DateofStart=(now * 1 days);
     }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // This function returns the partial Election Results for the first 5 Canditates, its returns also the Start and Finish
	// Date of the election running 
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function GetElectionDetails  () constant returns(bytes32[5] Details,uint[5]Votes,uint StartDate, uint EndDate){    

            for (uint i=0;i< ElectionControl.NumOfCandidates;i++){
                Details[i]=(Candidates[i].name);
                Votes[i]=Candidates[i].voteCount;
            }
            return (Details, Votes, ElectionControl.DateofStart,ElectionControl.DateofFinish);
        } 
        
	//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// This function accepts the Vote by candidate index (uint)
 	// Its allowed to vote only once by each election set.
	// The sender.LastDateVoted brings last date the address voted, so its possible to control the vote for every election
	// Date of Start is update every new Election is set
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////        

     /***function vote(uint Candidate) VotingNotEnded()  {
        Voter storage sender = voters[msg.sender];
        if(ElectionControl.DateofStart > sender.LastDateVoted){
            sender.voted = false;
        }
            require (!sender.voted);
            sender.voted = true;
            sender.LastDateVoted=(now * 1 days);
            sender.vote = Candidate;

            // If `proposal` is out of the range of the array,
            // this will throw automatically and revert all
            // changes.
            Candidates[Candidate].voteCount += 1;
    } ***/
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	// This function accepts the Vote by candidate Name; 
	// Its allowed to vote only once by each election set.
	// The sender.LastDateVoted brings last date the address voted, so its possible to control the vote for every election
	// Date of Start is update every new Election is set
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////        
    function vote(bytes32 MyCandidate) VotingNotEnded() returns (bool) {
        Voter storage sender = voters[msg.sender];
        if(ElectionControl.DateofStart > sender.LastDateVoted){
            sender.voted = false;
        }
        require(!sender.voted);
       bool bVoteOK=false;
       for(uint i=0; i< ElectionControl.NumOfCandidates;i++){
           if(Candidates[i].name == MyCandidate){
                Candidates[i].voteCount += 1;
                sender.voted = true;
                sender.vote = i;
                sender.LastDateVoted=(now *1 days);
                bVoteOK=true;
                
           }
        }
        return bVoteOK;
       }
    
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Computes the winning proposal taking all previous votes into account.
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function winningCandidate() constant
            returns (uint CandidateIndex)
    {
        uint winningVoteCount = 0;
        for (uint p = 0; p < Candidates.length; p++) {
            if (Candidates[p].voteCount > winningVoteCount) {
                winningVoteCount = Candidates[p].voteCount;
                CandidateIndex = p;
            }
        }
        return CandidateIndex;
    }

    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    // Calls winningProposal() function to get the index of the winner contained in the proposals array and then
    // returns the name of the winner 
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function winnerName() constant returns (bytes32 winnerName, uint votes) {
        uint p;
        p=winningCandidate();
        winnerName= Candidates[p].name;
        votes =  Candidates[p].voteCount;
        return (winnerName,votes);
    }
}