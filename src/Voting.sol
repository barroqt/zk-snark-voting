// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Voting Smart Contract
/// @author [Your Name or Organization]
/// @notice This contract manages a voting system with proposals and registered voters
/// @dev Inherits from OpenZeppelin's Ownable contract for access control
contract Voting is Ownable {
    uint256 public winningProposalID;
    bool public isTie;

    /// @notice Structure to store voter information
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    /// @notice Structure to store proposal information
    struct Proposal {
        string description;
        uint256 voteCount;
    }

    /// @notice Enum to represent the different stages of the voting process
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }

    WorkflowStatus public workflowStatus;
    Proposal[] public proposalsArray;
    mapping(address => Voter) public voters;

    // Events
    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint256 indexed proposalId, string description);
    event Voted(address voter, uint256 proposalId);
    event VotingReset();
    event VotesTallied(uint256 winningProposalId, uint256 winningVoteCount, bool isTie);

    // Errors
    error NotVoter();
    error VoterRegistrationClosed();
    error AlreadyRegistered();
    error ProposalsNotAllowed();
    error EmptyProposal();
    error VotingSessionNotStarted();
    error AlreadyVoted();
    error ProposalNotFound();
    error InvalidWorkflowStatus();
    error CannotResetBeforeTallying();

    /// @notice Modifier to restrict access to registered voters only
    modifier onlyVoters() {
        if (!voters[msg.sender].isRegistered) revert NotVoter();
        _;
    }

    // ::::::::::::: GETTERS ::::::::::::: //

    /// @notice Retrieves voter information
    /// @param _addr The address of the voter
    /// @return Voter struct containing voter information
    function getVoter(address _addr) external view onlyVoters returns (Voter memory) {
        return voters[_addr];
    }

    /// @notice Retrieves a specific proposal
    /// @param _id The ID of the proposal
    /// @return Proposal struct containing proposal information
    function getOneProposal(uint256 _id) external view onlyVoters returns (Proposal memory) {
        return proposalsArray[_id];
    }

    // ::::::::::::: REGISTRATION ::::::::::::: //

    /// @notice Adds a new voter to the system
    /// @param _addr The address of the voter to be added
    function addVoter(address _addr) external onlyOwner {
        if (workflowStatus != WorkflowStatus.RegisteringVoters) {
            revert VoterRegistrationClosed();
        }
        if (voters[_addr].isRegistered) {
            revert AlreadyRegistered();
        }

        voters[_addr].isRegistered = true;
        emit VoterRegistered(_addr);
    }

    // ::::::::::::: PROPOSAL ::::::::::::: //

    /// @notice Adds a new proposal to the system
    /// @param _desc The description of the proposal
    function addProposal(string calldata _desc) external onlyVoters {
        if (workflowStatus != WorkflowStatus.ProposalsRegistrationStarted) {
            revert ProposalsNotAllowed();
        }
        if (bytes(_desc).length == 0) {
            revert EmptyProposal();
        }

        Proposal memory proposal;
        proposal.description = _desc;
        proposalsArray.push(proposal);
        emit ProposalRegistered(proposalsArray.length - 1, _desc);
    }

    // ::::::::::::: VOTE ::::::::::::: //

    /// @notice Allows a voter to cast their vote
    /// @param _id The ID of the proposal being voted for
    function setVote(uint256 _id) external onlyVoters {
        if (workflowStatus != WorkflowStatus.VotingSessionStarted) {
            revert VotingSessionNotStarted();
        }
        if (voters[msg.sender].hasVoted) {
            revert AlreadyVoted();
        }
        if (_id >= proposalsArray.length) {
            revert ProposalNotFound();
        }

        voters[msg.sender].votedProposalId = _id;
        voters[msg.sender].hasVoted = true;
        proposalsArray[_id].voteCount++;

        emit Voted(msg.sender, _id);
    }

    /// @notice Tallies the votes and determines the winning proposal
    function tallyVotes() external onlyOwner {
        if (workflowStatus != WorkflowStatus.VotingSessionEnded) {
            revert InvalidWorkflowStatus();
        }

        uint256 winningVoteCount = 0; // eliminates the need to access the proposals array twice in each loop
        uint256 _winningProposalId;
        bool _isTie = false;

        for (uint256 i = 0; i < proposalsArray.length; i++) {
            if (proposalsArray[i].voteCount > winningVoteCount) {
                winningVoteCount = proposalsArray[i].voteCount;
                _winningProposalId = i;
                _isTie = false;
            } else if (proposalsArray[i].voteCount == winningVoteCount && winningVoteCount > 0) {
                _isTie = true;
            }
        }

        winningProposalID = _winningProposalId;
        isTie = _isTie;
        workflowStatus = WorkflowStatus.VotesTallied;

        emit VotesTallied(_winningProposalId, winningVoteCount, _isTie);
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, WorkflowStatus.VotesTallied);
    }

    /// @notice Resets the voting process for a new round
    function resetVoting() external onlyOwner {
        if (workflowStatus != WorkflowStatus.VotesTallied) {
            revert CannotResetBeforeTallying();
        }

        delete winningProposalID;
        delete isTie;
        delete proposalsArray;

        for (uint256 i = 0; i < voters.length; i++) {
            voters[i].hasVoted = false;
            voters[i].votedProposalId = 0;
        }

        workflowStatus = WorkflowStatus.RegisteringVoters;

        emit VotingReset();
        emit WorkflowStatusChange(WorkflowStatus.VotesTallied, WorkflowStatus.RegisteringVoters);
    }

    // ::::::::::::: STATE ::::::::::::: //

    /// @notice Starts the proposal registration phase
    function startProposalsRegistering() external onlyOwner {
        if (workflowStatus != WorkflowStatus.RegisteringVoters) {
            revert InvalidWorkflowStatus();
        }
        workflowStatus = WorkflowStatus.ProposalsRegistrationStarted;

        Proposal memory proposal;
        proposal.description = "GENESIS";
        proposalsArray.push(proposal);

        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, WorkflowStatus.ProposalsRegistrationStarted);
    }

    /// @notice Ends the proposal registration phase
    function endProposalsRegistering() external onlyOwner {
        if (workflowStatus != WorkflowStatus.ProposalsRegistrationStarted) {
            revert InvalidWorkflowStatus();
        }
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded
        );
    }

    /// @notice Starts the voting session
    function startVotingSession() external onlyOwner {
        if (workflowStatus != WorkflowStatus.ProposalsRegistrationEnded) {
            revert InvalidWorkflowStatus();
        }
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    /// @notice Ends the voting session
    function endVotingSession() external onlyOwner {
        if (workflowStatus != WorkflowStatus.VotingSessionStarted) {
            revert InvalidWorkflowStatus();
        }
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }
}
