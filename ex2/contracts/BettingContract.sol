pragma solidity ^0.4.15;

contract BettingContract {
	/* Standard state variables */
	address owner;
	address public gamblerA;
	bool public gamblerASet;
	bool public gamblerBSet;
	address public gamblerB;
	address public oracle;
	uint[] outcomes;

	/* Structs are custom data structures with self-defined parameters */
	struct Bet {
		uint outcome;
		uint amount;
		bool initialized;
	}

	/* Keep track of every gambler's bet */
	mapping (address => Bet) bets;
	/* Keep track of every player's winnings (if any) */
	mapping (address => uint) winnings;

	/* Add any events you think are necessary */
	event BetMade(address gambler);
	event BetClosed();

	/* Uh Oh, what are these? */
	modifier OwnerOnly() {
		if (msg.sender == owner){
			_;
		}
	}
	modifier OracleOnly() {
		if (msg.sender == oracle){
			_;
		}
	}

	/* Constructor function, where owner and outcomes are set */
	function BettingContract(uint[] _outcomes) {
		owner = msg.sender;
		outcomes = _outcomes;
		gamblerASet = false;
		gamblerBSet = false;
	}

	/* Owner chooses their trusted Oracle */
	function chooseOracle(address _oracle) OwnerOnly() returns (address) {
		oracle = _oracle;
		return oracle;
	}

	/* Gamblers place their bets, preferably after calling checkOutcomes */
	function makeBet(uint _outcome) payable returns (bool) {
		if (!gamblerASet) {
			gamblerA = msg.sender;
			gamblerASet = true;
		} else if (!gamblerBSet) {
			if (msg.sender == gamblerA) {
				return false; 
			} else {
				gamblerB = msg.sender;
				gamblerBSet = true;
			}
		} else {
			return false;
		}
		Bet memory newBet;
		newBet.outcome = _outcome;
		newBet.amount = msg.value;
		newBet.initialized = true;
		bets[msg.sender] = newBet;
		BetMade(msg.sender);
		return true;
	}

	/* The oracle chooses which outcome wins */
	function makeDecision(uint _outcome) OracleOnly() {
		uint pool = bets[gamblerA].amount + bets[gamblerB].amount;
		if (bets[gamblerA].outcome == _outcome && bets[gamblerB].outcome != _outcome) {
			winnings[gamblerA] = pool;
			winnings[gamblerB] = 0;
		}else if (bets[gamblerB].outcome == _outcome && bets[gamblerA].outcome != _outcome) {
			winnings[gamblerB] = pool;
			winnings[gamblerA] = 0;
		}
		BetClosed();	
	}

	/* Allow anyone to withdraw their winnings safely (if they have enough) */
	function withdraw(uint withdrawAmount) returns (uint remainingBal) {
		require(withdrawAmount > winnings[msg.sender]);
		msg.sender.transfer(withdrawAmount);
		winnings[msg.sender] -= withdrawAmount;
		return winnings[msg.sender];
	}
	
	/* Allow anyone to check the outcomes they can bet on */
	function checkOutcomes() constant returns (uint[]) {
		return outcomes;
	}
	
	/* Allow anyone to check if they won any bets */
	function checkWinnings() constant returns(uint) {
		return winnings[msg.sender];
	}

	/* Call delete() to reset certain state variables. Which ones? That's upto you to decide */
	function contractReset() private {
		delete outcomes;
		delete bets[gamblerA];
		delete bets[gamblerB];
		delete winnings[gamblerA];
		delete winnings[gamblerB];
		delete gamblerA;
		delete gamblerB;
	}

	/* Fallback function */
	function() {
	}

}
