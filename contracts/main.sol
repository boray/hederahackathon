// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Main is Ownable {
	
	struct Student {
	address receiverAddress;
	uint256 receivedEpoch;
	}

	struct Donator {
	address donatorAddress;
	string name;
	string uri;
	uint256 donatedAmount;
	}

	mapping(uint256 => Student) private students;
	mapping(uint256 => Donator) private donators;
	mapping(address => bool) private validators;


	function addValidator(address newValidator) public onlyOwner {
	validators[newValidator] = true;
	}
	
        function removeValidator(address newValidator) public onlyOwner {
        validators[newValidator] = true;
        }
	


}


