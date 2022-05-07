// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./erc1643.sol";

//Donator ===> Donate Pool ===> Validators checks student docs & sets withdraw allowance  ===> Student withdraws eth

//Epoch : Weekly, Biweekly or Monthly cycles for validating student docs and setting allowances


contract Main is Ownable {
	uint256 private _epoch; // very important, needs a discussion.
	
	event WithdrawAsStudent(address withdrawer, uint256 amount);

	struct Student {
		address receiverAddress;
		uint256 receivedEpoch;
		bool isRemoved;
	}

	struct Donator {
		address donatorAddress;
		string name;
		string uri;
		uint256 donatedAmount;
	}

	mapping(address => uint256) studentAddressToStudentId;
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


	//		period				studentId   count
	mapping(uint256 => mapping(uint256 => uint8)) private validationCounts;
	//	period				validator addr.	     studentId	validated
	mapping(uint256 => mapping(address => mapping(uint256 => bool))) private validatorValidatedStudent;
	//		period			  studentId		hasWitdrew
	mapping(uint256 => mapping(uint256 => bool)) private studentWithdrew;

	uint8 private numberOfValidators;
	uint256 private numberOfStudents;

	uint256 private startTime;
	uint256 private periodLength;

	uint8 requiredValidations;

	constructor(uint256 _periodLength, uint8 _requiredValidations){
		startTime = block.timestamp;
		periodLength = _periodLength;
		requiredValidations = _requiredValidations;
	}

	modifier onlyValidator() {
		require(validators[msg.sender], "YOU ARE NOT VALIDATOR!");
		_;
	}

	function getCurrentPeriod() internal view returns(uint256) {
		return (block.timestamp - startTime) % periodLength;
	}

	function getDocument(uint256 _studentId, bytes32 _name) public view  returns (string memory, bytes32, uint256){
        Document memory doc = _documents[_studentId][_name];
        return (doc.uri, doc.documentHash, doc.timestamp);
    }

	function getAllDocuments(uint256 _studentId) public view  returns (bytes32[] memory){
        bytes32[] memory names = new bytes32[](_noOfDocs[_studentId]);
        for(uint256 i = 0; i < _noOfDocs[_studentId]; i++){
            names[i] = _docNames[_studentId][i];
        }
        return names;
    }

	function setDocument(uint256 _studentId, bytes32 _name, string memory _uri, 
			bytes32 _documentHash) public {
		require(msg.sender == students[_studentId].receiverAddress);
        Document storage doc = _documents[_studentId][_name];
        if(doc.timestamp == 0){
            _docNames[_studentId][_noOfDocs[_studentId]] = _name;
            _noOfDocs[_studentId] += 1;
        }
        else{
            //emit DocumentUpdated(_name, _uri, _documentHash);
        }
        doc.timestamp = block.timestamp;
        doc.uri = _uri;
        doc.documentHash = _documentHash;
    }

	function removeDocument(uint256 _studentId, bytes32 _name) public  {
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
        _noOfDocs[_studentId] -= 1;
        //emit DocumentRemoved(_name, doc.uri, doc.documentHash);
    }


	function addStudent(address studentAddress) public onlyOwner {
		Student memory s = Student(studentAddress, 0, false); // not sure what the second argument should be.
		students[numberOfStudents] = s;
		studentAddressToStudentId[studentAddress] = numberOfStudents;
		++numberOfStudents;
	}

	function removeStudent(uint256 studentId) public onlyOwner {
		// this one is a little tricky.
		// if not the last student, swap "indexes" then decrease noOfStudents
		// if the last student, decrease noOfStudents.
		
		students[studentId].isRemoved = true;
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
	function validateStudentPeriodAllowance(uint256 studentId) public onlyValidator {
		Student storage s = students[studentId];

		require(s.isRemoved == false, "Student has been removed.");

		uint256 curPeriod = getCurrentPeriod();

		require(validatorValidatedStudent[curPeriod][address(msg.sender)][studentId] == false, "Already validated this address.");
		
		++validationCounts[curPeriod][studentId];

		validatorValidatedStudent[curPeriod][address(msg.sender)][studentId] = true;
	}

	function canWithdraw(uint256 studentId) internal returns (bool) {
		uint256 curPeriod = getCurrentPeriod();
		uint8 validatedCount = validationCounts[curPeriod][studentId];
		return validatedCount > requiredValidations;
	}


	// this has to change.
	function withdrawAsStudent() public {
		uint256 studentId = studentAddressToStudentId[address(msg.sender)];
		Student memory student = students[studentId];
		uint256 curPeriod = getCurrentPeriod();

		require(student.isRemoved == false, "You have been removed from the project"); // see removeStudent.
		require(canWithdraw(studentId), "Not enough validations.");
		require(studentWithdrew[curPeriod][studentId] == false, "You've withdrew this period.");

		studentWithdrew[curPeriod][studentId] = true;

		// rest, I haven't touched.
		uint256 amount_ = withdrawAllowance[msg.sender];
		withdrawAllowance[msg.sender] = 0;	
		payable(msg.sender).transfer(amount_);

		emit WithdrawAsStudent(msg.sender,amount_);
		
	}

	function donate() public payable {
        
	
	
	}

}


