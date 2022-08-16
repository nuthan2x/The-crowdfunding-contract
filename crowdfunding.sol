//SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.16;

contract Crowdfund{

    mapping(address => uint) public contributor;
    address public admin;
    uint public contributors;
    uint public target;
    uint public raisedamount;
    uint public minimumcontribution;
    uint public deadline;  

    struct Request{
        string  description;
        uint voters;
        uint payvalue;
        bool voted;
        address payable recepient;
        mapping(address => bool)  vote;
    }

    mapping(uint => Request) public requests;
    uint requestindex;


    constructor(uint _target,uint _deadline ){
        admin = msg.sender;
        target = _target;
        deadline = block.timestamp + _deadline ;
        minimumcontribution = 100  ;

    }

    event Contribute(address contributor, uint valuecontributed, uint raisedamount);
    event VotersCount(string _description,uint _voterscount);
    event TransferRequest(string _description,address _recepient, uint _voterscount);

    modifier onlyowner(){
        require(msg.sender == admin,"you arent admin");
        _;
    }


    function contribute() public payable{
        require(msg.value >= minimumcontribution,"not mininum");
        require(block.timestamp <= deadline,"time up");

        if( contributor[msg.sender] == 0){
            contributors++ ;
        }
        raisedamount += msg.value ;
        contributor[msg.sender] += msg.value;

        emit Contribute(msg.sender,contributor[msg.sender], raisedamount );

    }

    receive()external payable{
        contribute();
    }


    function refund() public {
        require(block.timestamp > deadline , "deadline not passed");
        require(contributor[msg.sender] > 0 , "no balance");
        require(raisedamount < target ,"target reached");

        address payable recepient = payable(msg.sender) ;
        uint amount = contributor[msg.sender];

        
        recepient.transfer(amount) ;
        contributor[msg.sender] = 0 ;
    }

    function createRequest(string memory _description,uint _payvalue, address payable _recepient) public onlyowner{
        Request storage newRequest = requests[requestindex];
        requestindex++ ;

        newRequest.description = _description;
        newRequest.recepient = _recepient;
        newRequest.payvalue = _payvalue;
        newRequest.voted = false ;
        newRequest.voters= 0;
    }

    function voterRequest(uint _requestindex) public{
        require(contributor[msg.sender] > 0,"you didnt contribute");

        Request storage voteRequest = requests[_requestindex];

        require(voteRequest.vote[msg.sender]== false, "you voted already");
        voteRequest.vote[msg.sender]= true ;

        emit VotersCount(voteRequest.description, voteRequest.voters);
        voteRequest.voters++ ;
    }

    function transferRequest(uint _requestindex) public onlyowner {
        require(target <= raisedamount,"not enough raised");

        Request storage voteRequest = requests[_requestindex];
    
        require(voteRequest.voted == false,"already transferred");
        require(voteRequest.voters > (contributors / 2));

        voteRequest.recepient.transfer(voteRequest.payvalue);
        emit TransferRequest(voteRequest.description, voteRequest.recepient,voteRequest.payvalue );

        voteRequest.voted = true;

    }
}