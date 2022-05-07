// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";



//Donator ===> Donate Pool ===> Validators checks student docs & sets withdraw allowance  ===> Student withdraws eth

//Epoch : Weekly, Biweekly or Monthly cycles for validating student docs and setting allowances




contract Main is Ownable {
	uint256 private _epoch; // very important, needs a discussion.
	
	event WithdrawAsStudent(address withdrawer, uint256 amount);

	struct Student {
		address receiverAddress;
		uint256 receivedEpoch;
		uint8 validatedCount;
		bool withdrewThisEpoch; // this might be the same thing with receivedEpoch, let's discuss which on would be bettter,
								// I think contract owner should reset epoch, we can change that though
	}

	struct Donator {
		address donatorAddress;
		string name;
		string uri;
		uint256 donatedAmount;
	}

	// would arrays be better? TODO: discuss.
	mapping(uint256 => Student) private students;
	mapping(uint256 => Donator) private donators;
	mapping(address => bool) private validators;
	mapping(address => uint256) private withdrawAllowance;

	/**
	 	epoch to (sha256(validatorAddress, studentAddress) => bool)
		to check if the validator already validated the student
	*/
	mapping(uint256 => mapping(bytes32 => bool)) private validations; 

	uint8 private numberOfValidators;
	uint256 private numberOfStudents;

	modifier onlyValidator() {
		require(validators[msg.sender], "YOU ARE NOT VALIDATOR!");
		
	}

	function nextEpoch() public onlyOwner {
		++_epoch;

		for (uint256 i = 0; i < numberOfStudents; i++){
			students[i].validatedCount = 0;
			students[i].withdrewThisEpoch = false;
		}
	}

	function addStudent(address studentAddress) public onlyOwner {
		Student memory s = Student(studentAddress, 0, 0, false, true); // not sure what the second argument should be.
		students[numberOfStudents] = s;
		++numberOfStudents;
	}

	function removeStudent(uint256 studentId) public onlyOwner {
		// this one is a little tricky.
		// if not the last student, swap "indexes" then decrease noOfStudents
		// if the last student, decrease noOfStudents.

		if(studentId != numberOfStudents - 1){
			students[studentId] = students[numberOfStudents - 1];
			delete students[numberOfStudents - 1];
		}

		--numberOfStudents;
	}

	function addValidator(address newValidator) public onlyOwner {
		validators[newValidator] = true;
		++numberOfValidators;
	}
	
	function removeValidator(address newValidator) public onlyOwner {
		validators[newValidator] = true;
		--numberOfValidators;
	}
	/**
		I put student id here because when we send validators student infos, we will loop through the mapping, so we can send ids as well.
		Id being here the key for the Student in the mapping.
	 */
	function validateStudentEpochAllowance(uint256 studentId) public onlyValidator {
		Student storage s = students[studentId];
		require(validations[_epoch][sha256(msg.sender, s.receiverAddress)], "Already validated this address.");
		
		++s.validatedCount;

		validations[_epoch][sha256(msg.sender, s.receiverAddress)] = true;
	}

	function canWithdraw(Student memory student) internal returns (bool) {
		return (student.validatedCount * 10 / numberOfValidators > 5); // validatedCount / numberOf Validators > %50, open to discussion probably lhs should be higher
	
		// maybe && block.timestamp - student.receivedEpoch > 1 epoch ?
	}

	function withdrawAsStudent() public {
		Student memory student = students[msg.sender];

		require(student.applicationApproved, "Not a valid student address.");
		require(!student.withdrewThisEpoch, "Donation for period withdrewn.");
		require(canWithdraw(student), "Not enough approvals yet.");


		student.withdrewThisEpoch = true;
		uint256 amount_ = withdrawAllowance[msg.sender];
		withdrawAllowance[msg.sender] = 0;	
		payable(msg.sender).transfer(amount_);

		emit WithdrawAsStudent(msg.sender,amount_);

		
	}

	function donate() public payable {
        
	
	
	}

}


