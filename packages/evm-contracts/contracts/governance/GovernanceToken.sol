// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";

contract GovernanceToken is ERC20, Ownable, Pausable {
    // Mapping to track delegation of voting power
    mapping(address => address) public delegates;
    mapping(address => uint256) public delegatedVotes;
    mapping(uint256 => mapping(address => bool)) public hasVoted;

    // Events for delegation and proposal actions
    event Delegated(address indexed from, address indexed to);
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        string description,
        address target,
        bytes data
    );
    event Voted(
        uint256 proposalId,
        address voter,
        bool support,
        uint256 weight
    );
    event ProposalExecuted(uint256 proposalId, address target, bytes data);

    // Struct for a proposal
    struct Proposal {
        string description;
        address target;
        bytes data;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 endTime;
        bool executed;
    }

    Proposal[] public proposals;
    uint256 public proposalTimelockDuration = 1 days;

    // Constructor
    constructor() ERC20("GovernanceToken", "GT") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10 ** decimals()); // Mint 1M tokens to the deployer
    }

    // Mint new tokens (only owner)
    function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
        _mint(to, amount);
    }

    // Burn tokens (only owner)
    function burn(
        address from,
        uint256 amount
    ) external onlyOwner whenNotPaused {
        _burn(from, amount);
    }

    // Delegate voting power
    function delegate(address to) external whenNotPaused {
        require(to != msg.sender, "Cannot delegate to self");
        address currentDelegate = delegates[msg.sender];
        if (currentDelegate != address(0)) {
            delegatedVotes[currentDelegate] -= balanceOf(msg.sender);
        }
        delegates[msg.sender] = to;
        delegatedVotes[to] += balanceOf(msg.sender);

        emit Delegated(msg.sender, to);
    }

    modifier onlyTokenHolders() {
        require(
            balanceOf(msg.sender) > 0,
            "Only token holders can create proposals"
        );
        _;
    }

    // Create a proposal
    function createProposal(
        string calldata description
    ) external onlyTokenHolders whenNotPaused {
        address target = address(0);
        bytes memory data = "";
        uint256 endTime = block.timestamp + proposalTimelockDuration;
        proposals.push(
            Proposal({
                description: description,
                target: target,
                data: data,
                votesFor: 0,
                votesAgainst: 0,
                endTime: endTime,
                executed: false
            })
        );
        emit ProposalCreated(
            proposals.length - 1,
            msg.sender,
            description,
            target,
            data
        );
    }

    function createProposal(
        string calldata description,
        address target,
        bytes calldata data
    ) external onlyTokenHolders whenNotPaused {
        uint256 endTime = block.timestamp + proposalTimelockDuration;
        proposals.push(
            Proposal({
                description: description,
                target: target,
                data: data,
                votesFor: 0,
                votesAgainst: 0,
                endTime: endTime,
                executed: false
            })
        );
        emit ProposalCreated(
            proposals.length - 1,
            msg.sender,
            description,
            target,
            data
        );
    }

    // Vote on a proposal
    function vote(uint256 proposalId, bool support) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(block.timestamp < proposal.endTime, "Voting period has ended");
        require(!hasVoted[proposalId][msg.sender], "Already voted");
        require(
            delegates[msg.sender] == address(0),
            "Delegated voters cannot vote directly"
        );

        uint256 votingPower = balanceOf(msg.sender);
        require(votingPower > 0, "No voting power");

        hasVoted[proposalId][msg.sender] = true;

        if (support) {
            proposal.votesFor += votingPower;
        } else {
            proposal.votesAgainst += votingPower;
        }

        emit Voted(proposalId, msg.sender, support, balanceOf(msg.sender));
    }

    // Execute a proposal
    function executeProposal(uint256 proposalId) external whenNotPaused {
        Proposal storage proposal = proposals[proposalId];
        require(
            block.timestamp >= proposal.endTime,
            "Proposal is still in timelock period"
        );
        require(
            block.timestamp >= proposal.endTime + proposalTimelockDuration,
            "Proposal can not be executed yet"
        );
        require(!proposal.executed, "Proposal already executed");
        require(
            proposal.votesFor > 0 || proposal.votesAgainst > 0,
            "No votes cast"
        );
        require(proposal.votesFor > proposal.votesAgainst, "Proposal rejected");

        // Execute the proposal's on-chain logic
        // if the target exists, and data exists then call the target with the data

        if (proposal.target == address(0) || proposal.data.length == 0) {
            proposal.executed = true;
            emit ProposalExecuted(proposalId, proposal.target, proposal.data);
            return;
        }

        (bool success, ) = proposal.target.call(proposal.data); // bytes memory returnData
        require(success, "Proposal execution failed");

        proposal.executed = true;
        emit ProposalExecuted(proposalId, proposal.target, proposal.data);

        // Add logic for executing the proposal action here
    }

    // Emergency shutdown
    function emergencyShutdown() external onlyOwner {
        _pause(); // Pause all functions
    }

    // Reactivate the contract after shutdown
    function reactivate() external onlyOwner {
        _unpause(); // Resume all functions
    }
}
