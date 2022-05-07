// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./erc1643.sol";

//Donator ===> Donate Pool ===> Validators checks student docs & sets withdraw allowance  ===> Student withdraws eth

//Epoch : Weekly, Biweekly or Monthly cycles for validating student docs and setting allowances


contract Main is Ownable, IERC1643 {
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

	struct Document {
        string uri;
        bytes32 documentHash;
        uint256 timestamp;
    }

	// studentId -> document name -> document
	mapping(uint256 => mapping(bytes32 => Document)) private _documents; 
	// studentId -> index -> document name
	mapping(uint256 => mapping(uint256 => bytes32)) private _docNames;
	//studentId -> no of docs
	mapping(uint256 => uint256) private _noOfDocs;

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

	function getDocument(uint256 _studentId, bytes32 _name) public view override returns (string memory, bytes32, uint256){
        Document memory doc = _documents[_studentId][_name];
        return (doc.uri, doc.documentHash, doc.timestamp);
    }

	function getAllDocuments(uint256 _studentId) public view override returns (bytes32[] memory){
        bytes32[] memory names = new bytes32[](_noOfDocs[_studentId]);
        for(uint256 i = 0; i < _noOfDocs[_studentId]; i++){
            names[i] = _docNames[_studentId][i];
        }
        return names;
    }

	function setDocument(uint256 _studentId, bytes32 _name, string memory _uri, 
			bytes32 _documentHash) public override{
		require(msg.sender == students[_studentId].receiverAddress);
        Document storage doc = _documents[_studentId][_name];
        if(doc.timestamp == 0){
            _docNames[_studentId][_noOfDocs[_studentId]] = _name;
            _noOfDocs[_studentId] += 1;
        }
        else{
            emit DocumentUpdated(_name, _uri, _documentHash);
        }
        doc.timestamp = block.timestamp;
        doc.uri = _uri;
        doc.documentHash = _documentHash;
    }

	function removeDocument(uint256 _studentId, bytes32 _name) public override {
		require(msg.sender == students[_studentId].receiverAddress);
        bool arrivedIdx = false;
        for(uint256 i = 0; i < _noOfDocs[_studentId]; i++){
            if(_docNames[_studentId][i] == _name){
                arrivedIdx = true;
            }
            if(arrivedIdx){
                _docNames[_studentId][i] = _docNames[_studentId][i + 1];
            }
        }
        Document memory doc = _documents[_studentId][_name];
        require(doc.timestamp != 0);
        delete _documents[_studentId][_name];
        noOfDocs -= 1;
        emit DocumentRemoved(_name, doc.uri, doc.documentHash);
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
	

  function removeValidator(address validatorToRemove) public onlyOwner {
    validators[validatorToRemove] = false;
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


