pragma solidity ^0.8.19;

contract Project {
    // Struct to represent a proposal
    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 voteCount;
        uint256 deadline;
        bool active;
        address proposer;
    }
    
    // State variables
    address public owner;
    uint256 public proposalCounter;
    uint256 public constant VOTING_DURATION = 7 days;
    
    // Mappings
    mapping(uint256 => Proposal) public proposals;
    mapping(address => bool) public hasVoted;
    mapping(uint256 => mapping(address => bool)) public proposalVotes;
    
    // Events
    event ProposalCreated(uint256 indexed proposalId, string title, address indexed proposer);
    event VoteCasted(uint256 indexed proposalId, address indexed voter);
    event ProposalEnded(uint256 indexed proposalId, uint256 totalVotes);
    
    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId < proposalCounter, "Proposal does not exist");
        _;
    }
    
    modifier proposalActive(uint256 _proposalId) {
        require(proposals[_proposalId].active, "Proposal is not active");
        require(block.timestamp < proposals[_proposalId].deadline, "Voting period has ended");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        proposalCounter = 0;
    }
    
    /**
     * @dev Core Function 1: Create a new proposal
     * @param _title The title of the proposal
     * @param _description The detailed description of the proposal
     */
    function createProposal(string memory _title, string memory _description) external {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        
        uint256 deadline = block.timestamp + VOTING_DURATION;
        
        proposals[proposalCounter] = Proposal({
            id: proposalCounter,
            title: _title,
            description: _description,
            voteCount: 0,
            deadline: deadline,
            active: true,
            proposer: msg.sender
        });
        
        emit ProposalCreated(proposalCounter, _title, msg.sender);
        proposalCounter++;
    }
    
    /**
     * @dev Core Function 2: Cast a vote for a proposal
     * @param _proposalId The ID of the proposal to vote for
     */
    function castVote(uint256 _proposalId) 
        external 
        proposalExists(_proposalId) 
        proposalActive(_proposalId) 
    {
        require(!proposalVotes[_proposalId][msg.sender], "You have already voted for this proposal");
        
        proposalVotes[_proposalId][msg.sender] = true;
        proposals[_proposalId].voteCount++;
        
        emit VoteCasted(_proposalId, msg.sender);
    }
    
    /**
     * @dev Core Function 3: End a proposal (can be called by anyone after deadline)
     * @param _proposalId The ID of the proposal to end
     */
    function endProposal(uint256 _proposalId) 
        external 
        proposalExists(_proposalId) 
    {
        require(proposals[_proposalId].active, "Proposal is already ended");
        require(block.timestamp >= proposals[_proposalId].deadline, "Voting period is still active");
        
        proposals[_proposalId].active = false;
        
        emit ProposalEnded(_proposalId, proposals[_proposalId].voteCount);
    }
    
    // View functions
    function getProposal(uint256 _proposalId) 
        external 
        view 
        proposalExists(_proposalId) 
        returns (
            uint256 id,
            string memory title,
            string memory description,
            uint256 voteCount,
            uint256 deadline,
            bool active,
            address proposer
        ) 
    {
        Proposal memory proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.title,
            proposal.description,
            proposal.voteCount,
            proposal.deadline,
            proposal.active,
            proposal.proposer
        );
    }
    
    function getTotalProposals() external view returns (uint256) {
        return proposalCounter;
    }
    
    function hasUserVoted(uint256 _proposalId, address _user) 
        external 
        view 
        proposalExists(_proposalId) 
        returns (bool) 
    {
        return proposalVotes[_proposalId][_user];
    }
    
    function getTimeRemaining(uint256 _proposalId) 
        external 
        view 
        proposalExists(_proposalId) 
        returns (uint256) 
    {
        if (block.timestamp >= proposals[_proposalId].deadline) {
            return 0;
        }
        return proposals[_proposalId].deadline - block.timestamp;
    }
}
