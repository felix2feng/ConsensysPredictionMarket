pragma solidity ^0.4.4;

import './SafeMath.sol';
import './Pausable.sol';

contract PredictionMarket is Pausable {
	address public sponsor;
	address public trustedSource;
	bool public answer;
	bool public hasBeenAnsweredBySource;
	bytes32 public questionHash;

	struct Bet {
	    uint amount;
	    bool bet;
	    uint amountWithdrawn;
	}
	
	modifier isSponsor {
	    require(msg.sender == sponsor);
	    _;
	}
	
	mapping (address => Bet) public bets;
	mapping (bool => uint) public totalBetAmounts;

	event LogQuestion(bytes32 _questionHash, address source, address sender);
	event LogBet(address better, bool betDirection, uint amount);
	event LogOracleAnswer(bool decision, address oracle);
	event LogWithdraw(address requester, uint amount);

	function PredictionMarket(address _sponsor) {
		sponsor = _sponsor;
		hasBeenAnsweredBySource = false;
	}

	function poseQuestion (bytes32 _questionHash, address _trustedSource)
		public
		isSponsor
		returns (bool success)
	{
		// There is previously no question posed
		require(questionHash == 0);

		// No Source should have been set for this question
		require(trustedSource == 0);

		// The question text must not be an empty string
		require(_questionHash != 0);

		// The question should not have been answered when there is no question
		require(hasBeenAnsweredBySource == false);
		
		questionHash = _questionHash;
		trustedSource = _trustedSource;

		LogQuestion(questionHash, trustedSource, msg.sender);

		return true;
	}

	// @Param outcomeIsTrue: The participant's bet whether the question
	// is true or not
	function betOnOutcome (bool outcomeIsTrue) 
		payable
		public
		returns (bool success)
	{
		// There needs to be a question posed
		require(questionHash != 0);

		// There must be some value attached to the bet
		require(msg.value != 0);

		// A source must be designated for this question
		require(trustedSource != 0);

		// The source must not have answered the question
		require(hasBeenAnsweredBySource == false);

		// The better is only allowed to bet once
		require(bets[msg.sender].amount == 0);

		bets[msg.sender].amount = msg.value;
		bets[msg.sender].bet = outcomeIsTrue;
		bets[msg.sender].amountWithdrawn = 0;

		uint currentTotalBets = totalBetAmounts[outcomeIsTrue]; 		
		totalBetAmounts[outcomeIsTrue] =  SafeMath.add(currentTotalBets, msg.value);

		LogBet(msg.sender, outcomeIsTrue, msg.value);
		
		return true;
	}

	function answerQuestion(bool decision)
		public
		returns (bool success)
	{
		// The sender must be the trusted source
		// NOTE: Put this first so that spammers are stopped earlier
		require(msg.sender == trustedSource);

		// There needs to be a question posed
		require(questionHash != 0);

		// The question must not been answered yet
		require(hasBeenAnsweredBySource == false);

		hasBeenAnsweredBySource = true;
		
		answer = decision;

		LogOracleAnswer(decision, msg.sender);

		return true;
	}

	function withdraw () 
		public
		returns (bool success)
	{
		// The oracle must have answered the question
		require(hasBeenAnsweredBySource == true);
		
		// The withdrawer must have made the correct bet
		require(bets[msg.sender].bet == answer);

		// The amount bet must not be 0 NOTE: This would harden the codde
		require(bets[msg.sender].amount != 0);
		
		uint betAmount = bets[msg.sender].amount;
		uint amountWithdrawn = bets[msg.sender].amountWithdrawn;
		uint totalWinnerEth = totalBetAmounts[answer];
		uint totalLoserEth = totalBetAmounts[!answer];
		
		// Amount possible to withdrawn = bet + winnings - amount already withdrawn
		uint totalWinnings = SafeMath.mul(SafeMath.div(betAmount, totalWinnerEth), totalLoserEth);
		uint totalCanWithdraw = SafeMath.sub(SafeMath.add(betAmount, totalWinnings), amountWithdrawn);

		// The withdrawer must have funds to withdraw
		require((totalCanWithdraw) != 0);
		
		bets[msg.sender].amountWithdrawn = totalCanWithdraw;
		msg.sender.transfer(totalCanWithdraw);

		LogWithdraw(msg.sender, totalCanWithdraw);
		
		return true;
	}
	
}
