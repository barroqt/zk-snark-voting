// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Voting is Ownable {
    uint256 public winningProposalID;
    bool public isTie;

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }

    struct Proposal {
        string description;
        uint256 voteCount;
    }

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

    event VoterRegistered(address voterAddress);
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint256 indexed proposalId, string description);
    event Voted(address voter, uint256 proposalId);
    event VotingReset();
    event VotesTallied(uint256 winningProposalId, uint256 winningVoteCount, bool isTie);

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

    modifier onlyVoters() {
        if (!voters[msg.sender].isRegistered) revert NotVoter();
        _;
    }

    // ::::::::::::: GETTERS ::::::::::::: //

    function getVoter(address _addr) external view onlyVoters returns (Voter memory) {
        return voters[_addr];
    }

    function getOneProposal(uint256 _id) external view onlyVoters returns (Proposal memory) {
        return proposalsArray[_id];
    }

    // ::::::::::::: REGISTRATION ::::::::::::: //

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

    function tallyVotes() external onlyOwner {
        if (workflowStatus != WorkflowStatus.VotingSessionEnded) {
            revert InvalidWorkflowStatus();
        }

        uint256 winningVoteCount = 0; // eliminates the need to access the proposals array twice in each loop
        uint256 _winningProposalId;
        bool _isTie = false;

        for (uint256 i = 0; p < proposalsArray.length; i++) {
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

    function endProposalsRegistering() external onlyOwner {
        if (workflowStatus != WorkflowStatus.ProposalsRegistrationStarted) {
            revert InvalidWorkflowStatus();
        }
        workflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(
            WorkflowStatus.ProposalsRegistrationStarted, WorkflowStatus.ProposalsRegistrationEnded
        );
    }

    function startVotingSession() external onlyOwner {
        if (workflowStatus != WorkflowStatus.ProposalsRegistrationEnded) {
            revert InvalidWorkflowStatus();
        }
        workflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, WorkflowStatus.VotingSessionStarted);
    }

    function endVotingSession() external onlyOwner {
        if (workflowStatus != WorkflowStatus.VotingSessionStarted) {
            revert InvalidWorkflowStatus();
        }
        workflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, WorkflowStatus.VotingSessionEnded);
    }
}
