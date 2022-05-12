// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ERC1643.sol";

//Donator ===> Donate Pool ===> Validators checks student docs & sets withdraw allowance  ===> Student withdraws eth

//Epoch : Weekly, Biweekly or Monthly cycles for validating student docs and setting allowances

/*
TODO Below:
~ TESTING AND STATIC ANALYSIS
~ We can consider using NATSPEC
~ Simplifications and optimizations can be made
~ Naming and ordering could be improved according to Solidity convention 
*/


/* What I have done:
	



*/
contract Main is Ownable, DocumentManager {
	
	struct Student {
		address receiverAddress; // address of the student
		uint256 receivedPeriod; // ?
	}

	struct Donator {
		address donatorAddress; // address of the donator
		string name;	//name -> donator could be an individual or a company, this is name of that
		string uri;		//uri -> URI of donator's website or social media profile
		uint256 donatedAmount; // total amount of donations made by donator
	}

	mapping(address => uint256) studentAddressToStudentId;	// student address -> studentId
	mapping(address => uint256) donatorAddressToDonatorId;	// donator address -> donatorId
	mapping(uint256 => mapping(bytes32 => Document)) private _documents; 	// studentId -> document name -> document
	mapping(uint256 => mapping(uint256 => bytes32)) private _docNames;	// studentId -> index -> document name
	mapping(uint256 => uint256) private _noOfDocs;	// studentId -> no of docs
	mapping(uint256 => Student) private students; // studentId -> Student struct
	mapping(uint256 => Donator) private donators; // donatorId -> Donator struct
	mapping(address => bool) private validators; // mapping to store validator addresses
	mapping(address => uint256) private withdrawAllowance; // student adress -> amount in wei  | withdrawal allowence in an epoch
	mapping(uint256 => mapping(uint256 => uint8)) private validationCounts;	//	(period	-> (studentId  -> count))
	mapping(uint256 => mapping(address => mapping(uint256 => bool))) private validatorValidatedStudent;	//	(period ->(validator address ->	 (studentId	-> validated)))
	mapping(uint256 => mapping(uint256 => bool)) private studentWithdrew; 	//	(period -> (studentId -> hasWitdrew))

	uint256 private constant MINIMUM_DONATION_AMOUNT=1000000000000000000; // floor donation amount in wei 

	uint8 private numberOfValidators; // total number of validators
	uint256 private numberOfStudents; // total number of students
	uint256 private numberOfDonators; // total number of donators


	uint256 private startTime; //timestamp of contract deployment (seconds passed since 1 Jan 1970)| its value assigned in constructor
	uint256 private periodLength; // length of a epoch in seconds

	uint8 requiredValidations; // required quantity of validator to set withdrawal allowence for a student

	event WithdrawAsStudent(address withdrawer, uint256 amount);
	event NewDonation(address donatorAddress, string name, string uri, uint256 amount);
	// other actions could be logged with events

	modifier onlyValidator() {
		require(validators[msg.sender], "YOU ARE NOT VALIDATOR!");
		_;
	}


	constructor(uint256 _periodLength, uint8 _requiredValidations){
		startTime = block.timestamp;
		periodLength = _periodLength;
		requiredValidations = _requiredValidations;
	}


	function donate(string memory name_, string memory uri_) public payable { 
		require(msg.value > MINIMUM_DONATION_AMOUNT,"DONATED AMOUNT IS BELOW LIMIT"); // floor donation amount to prevent spamming
		Donator memory donator_;
		if(donators[donatorAddressToDonatorId[msg.sender]].donatedAmount != 0){
			uint newDonatedAmount = donators[donatorAddressToDonatorId[msg.sender]].donatedAmount + msg.value;
    		donator_ = Donator(msg.sender,name_,uri_, newDonatedAmount); 
		}
		else{
    		donator_= Donator(msg.sender, name_, uri_, msg.value);
		}

		donators[donatorAddressToDonatorId[msg.sender]] = donator_;

		emit NewDonation(msg.sender,name_,uri_,msg.value);
	
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
		Student memory s = Student(studentAddress, 0); // not sure what the second argument should be.
		students[numberOfStudents] = s;
		studentAddressToStudentId[studentAddress] = numberOfStudents;
		++numberOfStudents;
	}

	function removeStudent(uint256 studentId) public onlyOwner {
		// this one is a little tricky.
		
		delete students[studentId];
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

		uint256 currentPeriod = getCurrentPeriod();

		require(validatorValidatedStudent[currentPeriod][address(msg.sender)][studentId] != false, "Already validated this address."); 
	
		++validationCounts[currentPeriod][studentId];

		validatorValidatedStudent[currentPeriod][address(msg.sender)][studentId] = true;
	}

	// this has to change.
	function withdrawAsStudent() public {
		uint256 studentId = studentAddressToStudentId[address(msg.sender)];
		uint256 currentPeriod = getCurrentPeriod();

		require(canWithdraw(studentId), "Not enough validations.");
		require(studentWithdrew[currentPeriod][studentId] == false, "You've withdrew this period.");

		studentWithdrew[currentPeriod][studentId] = true;

		// rest, I haven't touched.
		uint256 amount_ = withdrawAllowance[msg.sender];
		withdrawAllowance[msg.sender] = 0;	
		payable(msg.sender).transfer(amount_);

		emit WithdrawAsStudent(msg.sender,amount_);
		
	}


	function getCurrentPeriod() internal view returns(uint256) { 
		return (block.timestamp - startTime) % periodLength;
	}

	function canWithdraw(uint256 studentId) internal view returns (bool) { 
		uint256 currentPeriod = getCurrentPeriod();
		uint8 validatedCount = validationCounts[currentPeriod][studentId];
		return validatedCount > requiredValidations;
	}

    function getNoOfStudents() public view returns(uint){
        return numberOfStudents;
    }

}


