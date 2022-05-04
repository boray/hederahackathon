// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";



//Donator ===> Donate Pool ===> Validators checks student docs & sets withdraw allowance  ===> Student withdraws eth

//Epoch : Weekly, Biweekly or Monthly cycles for validating student docs and setting allowances




contract Main is Ownable {
		
	
	event WithdrawAsStudent(address withdrawer, uint256 amount);

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
	mapping(address => uint256) private withdrawAllowance;
	
	modifier onlyValidator() {
		require(validators[msg.sender],'YOU ARE NOT VALIDATOR!');
	
	}
	function addValidator(address newValidator) public onlyOwner {
		validators[newValidator] = true;
	}
	
        function removeValidator(address newValidator) public onlyOwner {
        	validators[newValidator] = true;
        }
	
	function validateStudentEpochAllowance() public onlyValidator {
	
	}

	function withdrawAsStudent() public {
	uint256 amount_ = withdrawAllowance[msg.sender];
	withdrawAllowance[msg.sender] = 0;	
	payable(msg.sender).transfer(amount_);

        emit WithdrawAsStudent(msg.sender,amount_);
	}

	function donate() public payable {
        
	
	
	}

}


