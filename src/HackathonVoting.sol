// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
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

    IERC20 public prizeToken;
    uint256 public prizeAmount;

    // Mappings
    mapping(uint256 => Project) public projects;
    mapping(address => mapping(uint256 => bool)) public hasVotedForProject;
    mapping(address => uint256[]) public voterHistory;
    mapping(address => uint256) public voterVoteCount;

    // ============ Constructor ============

    constructor(address _prizeToken, uint256 _prizeAmount) Ownable(msg.sender) {
        prizeToken = IERC20(_prizeToken);
        prizeAmount = _prizeAmount;
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
     * @param teamAddress Address to receive prize if project wins
     */
    function registerProject(
        string memory title,
        string memory description,
        string memory teamName,
        string memory category,
        string memory imageUrl,
        string memory demoUrl,
        string memory githubUrl,
        address teamAddress
    ) external override onlyOwner {
        _registerProject(title, description, teamName, category, imageUrl, demoUrl, githubUrl, teamAddress);
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
     * @param teamAddresses Array of team addresses to receive prizes
     */
    function registerProjects(
        string[] memory titles,
        string[] memory descriptions,
        string[] memory teamNames,
        string[] memory categories,
        string[] memory imageUrls,
        string[] memory demoUrls,
        string[] memory githubUrls,
        address[] memory teamAddresses
    ) external override onlyOwner {
        uint256 length = titles.length;

        // Validate all arrays have the same length
        if (
            descriptions.length != length || teamNames.length != length || categories.length != length
                || imageUrls.length != length || demoUrls.length != length || githubUrls.length != length
                || teamAddresses.length != length
        ) revert ArrayLengthMismatch();

        // Register all projects
        for (uint256 i = 0; i < length; i++) {
            _registerProject(
                titles[i],
                descriptions[i],
                teamNames[i],
                categories[i],
                imageUrls[i],
                demoUrls[i],
                githubUrls[i],
                teamAddresses[i]
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
        string memory githubUrl,
        address teamAddress
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
            voteCount: 0,
            teamAddress: teamAddress
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

        // Find top 3 projects by vote count
        uint256[3] memory topProjectIds;
        uint256[3] memory topVoteCounts;

        for (uint256 i = 1; i <= projectCount; i++) {
            uint256 currentVotes = projects[i].voteCount;

            // Check if this project belongs in top 3
            for (uint256 j = 0; j < 3; j++) {
                if (currentVotes > topVoteCounts[j]) {
                    // Shift lower rankings down
                    for (uint256 k = 2; k > j; k--) {
                        topVoteCounts[k] = topVoteCounts[k - 1];
                        topProjectIds[k] = topProjectIds[k - 1];
                    }
                    // Insert current project
                    topVoteCounts[j] = currentVotes;
                    topProjectIds[j] = i;
                    break;
                }
            }
        }

        votingResolved = true;
        winnerProjectId = topProjectIds[0];

        // Distribute prizes to top 3 winners
        uint256 prizePerWinner = prizeAmount / 3;

        for (uint256 i = 0; i < 3; i++) {
            if (topProjectIds[i] != 0 && topVoteCounts[i] > 0) {
                // Transfer prize to project's team address
                address teamAddress = projects[topProjectIds[i]].teamAddress;
                if (teamAddress != address(0)) {
                    prizeToken.transfer(teamAddress, prizePerWinner);
                }
            }
        }

        emit VotingResolved(topProjectIds[0], projects[topProjectIds[0]].title, topVoteCounts[0]);
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
                voteCount: p.voteCount,
                teamAddress: p.teamAddress
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
