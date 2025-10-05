// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./IHackathonVoting.sol";

/**
 * @title HackathonVoting
 * @notice A transparent, blockchain-based voting system for hackathon projects
 * @dev Implements a voting system where each address can vote for up to 2 different projects
 */
contract HackathonVoting is IHackathonVoting, Ownable {
    // ============ State Variables ============

    bool public override votingResolved;
    uint256 public override winnerProjectId;
    uint256 public override projectCount;
    uint256 public override totalVoters;

    // Mappings
    mapping(uint256 => Project) public projects;
    mapping(address => mapping(uint256 => bool)) public hasVotedForProject;
    mapping(address => uint256[]) public voterHistory;
    mapping(address => uint256) public voterVoteCount;

    // ============ Constructor ============

    constructor() Ownable(msg.sender) {
        // All state variables default to 0/false, no initialization needed
    }

    // ============ Admin Functions ============

    /**
     * @notice Register a new project for voting
     * @dev Only callable by contract owner
     * @param title Project title
     * @param description Project description
     * @param teamName Team name
     * @param category Project category
     * @param imageUrl URL to project image
     * @param demoUrl URL to project demo
     * @param githubUrl URL to project GitHub repository
     */
    function registerProject(
        string memory title,
        string memory description,
        string memory teamName,
        string memory category,
        string memory imageUrl,
        string memory demoUrl,
        string memory githubUrl
    ) external override onlyOwner {
        _registerProject(title, description, teamName, category, imageUrl, demoUrl, githubUrl);
    }

    /**
     * @notice Register multiple projects at once (batch registration)
     * @dev Only callable by contract owner, saves gas for multiple registrations
     * @param titles Array of project titles
     * @param descriptions Array of project descriptions
     * @param teamNames Array of team names
     * @param categories Array of project categories
     * @param imageUrls Array of image URLs
     * @param demoUrls Array of demo URLs
     * @param githubUrls Array of GitHub URLs
     */
    function registerProjects(
        string[] memory titles,
        string[] memory descriptions,
        string[] memory teamNames,
        string[] memory categories,
        string[] memory imageUrls,
        string[] memory demoUrls,
        string[] memory githubUrls
    ) external override onlyOwner {
        uint256 length = titles.length;

        // Validate all arrays have the same length
        if (
            descriptions.length != length || teamNames.length != length || categories.length != length
                || imageUrls.length != length || demoUrls.length != length || githubUrls.length != length
        ) revert ArrayLengthMismatch();

        // Register all projects
        for (uint256 i = 0; i < length; i++) {
            _registerProject(
                titles[i], descriptions[i], teamNames[i], categories[i], imageUrls[i], demoUrls[i], githubUrls[i]
            );
        }
    }

    /**
     * @notice Internal function to register a project
     * @dev Used by both registerProject and registerProjects
     */
    function _registerProject(
        string memory title,
        string memory description,
        string memory teamName,
        string memory category,
        string memory imageUrl,
        string memory demoUrl,
        string memory githubUrl
    ) internal {
        projectCount++;

        projects[projectCount] = Project({
            id: projectCount,
            title: title,
            description: description,
            teamName: teamName,
            category: category,
            imageUrl: imageUrl,
            demoUrl: demoUrl,
            githubUrl: githubUrl,
            voteCount: 0
        });

        emit ProjectRegistered(projectCount, title, teamName, category);
    }

    /**
     * @notice Resolve voting and determine the winner
     * @dev Only callable by contract owner, can only be called once
     */
    function resolveVoting() external override onlyOwner {
        if (votingResolved) revert VotingAlreadyResolved();
        if (projectCount == 0 || totalVoters == 0) revert NoVotesCast();

        uint256 highestVotes = 0;
        uint256 winnerId = 0;

        // Find project with highest vote count
        for (uint256 i = 1; i <= projectCount; i++) {
            if (projects[i].voteCount > highestVotes) {
                highestVotes = projects[i].voteCount;
                winnerId = i;
            }
        }

        votingResolved = true;
        winnerProjectId = winnerId;

        emit VotingResolved(winnerId, projects[winnerId].title, highestVotes);
    }

    // ============ User Functions ============

    /**
     * @notice Cast a vote for a project
     * @dev Each address can vote for up to 2 different projects
     * @param projectId ID of the project to vote for
     */
    function vote(uint256 projectId) external override {
        if (votingResolved) revert VotingAlreadyResolved();
        if (projectId == 0 || projectId > projectCount) revert ProjectNotFound();
        if (hasVotedForProject[msg.sender][projectId]) revert AlreadyVotedForProject();
        if (voterVoteCount[msg.sender] >= 2) revert MaxVotesReached();

        // Track if this is the voter's first vote
        if (voterVoteCount[msg.sender] == 0) {
            totalVoters++;
        }

        // Record the vote
        hasVotedForProject[msg.sender][projectId] = true;
        voterHistory[msg.sender].push(projectId);
        voterVoteCount[msg.sender]++;
        projects[projectId].voteCount++;

        emit VoteCast(msg.sender, projectId, projects[projectId].voteCount);
    }

    /**
     * @notice Get the project IDs that the caller has voted for
     * @return Array of project IDs (max length 2)
     */
    function getMyVotes() external view override returns (uint256[] memory) {
        return voterHistory[msg.sender];
    }

    // ============ View Functions ============

    /**
     * @notice Get comprehensive voting data in a single call
     * @dev Returns all data needed by the frontend
     * @param viewer Address of the viewer (to get personalized voting history)
     * @return VotingData struct containing all voting information
     */
    function getVotingData(address viewer) external view override returns (VotingData memory) {
        // Build projects array
        Project[] memory projectInfos = new Project[](projectCount);
        for (uint256 i = 1; i <= projectCount; i++) {
            Project storage p = projects[i];
            projectInfos[i - 1] = Project({
                id: p.id,
                title: p.title,
                description: p.description,
                teamName: p.teamName,
                category: p.category,
                imageUrl: p.imageUrl,
                demoUrl: p.demoUrl,
                githubUrl: p.githubUrl,
                voteCount: p.voteCount
            });
        }

        // Calculate total votes
        uint256 totalVotesCount = 0;
        for (uint256 i = 1; i <= projectCount; i++) {
            totalVotesCount += projects[i].voteCount;
        }

        // Get viewer's voting history
        uint256[] memory viewerVotes = voterHistory[viewer];

        return VotingData({
            projects: projectInfos,
            totalVotes: totalVotesCount,
            totalVoters: totalVoters,
            voterProjectIds: viewerVotes,
            votingResolved: votingResolved,
            winnerProjectId: winnerProjectId
        });
    }

    /**
     * @notice Get details of a specific project
     * @param projectId ID of the project
     * @return Project struct
     */
    function getProject(uint256 projectId) external view override returns (Project memory) {
        if (projectId == 0 || projectId > projectCount) revert ProjectNotFound();
        return projects[projectId];
    }

    /**
     * @notice Get the total number of votes cast
     * @return Total number of votes
     */
    function getTotalVotes() external view override returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 1; i <= projectCount; i++) {
            total += projects[i].voteCount;
        }
        return total;
    }
}
