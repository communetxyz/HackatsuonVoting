// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IHackathonVoting
 * @notice Interface for the HackathonVoting contract
 * @dev Defines all events, errors, enums, structs, and external functions
 */
interface IHackathonVoting {
    // ============ Structs ============

    struct Project {
        uint256 id;
        string title;
        string description;
        string teamName;
        string category;
        string imageUrl;
        string demoUrl;
        string githubUrl;
        uint256 voteCount;
        address teamAddress;
    }

    struct VotingData {
        Project[] projects; // All projects with complete details
        uint256 totalVotes; // Sum of all votes across projects
        uint256 totalVoters; // Count of unique voter addresses
        uint256[] voterProjectIds; // IDs of projects the viewer voted for (max 2)
        bool votingResolved; // Whether voting has been finalized
        uint256 winnerProjectId; // ID of winning project (0 if not resolved)
    }

    // ============ Events ============

    /**
     * @notice Emitted when a new project is registered
     * @param projectId The unique ID of the registered project
     * @param title The title of the project
     * @param teamName The name of the team
     * @param category The category of the project
     */
    event ProjectRegistered(uint256 indexed projectId, string title, string teamName, string category);

    /**
     * @notice Emitted when a vote is cast
     * @param voter The address of the voter
     * @param projectId The ID of the project voted for
     * @param newVoteCount The updated vote count for the project
     */
    event VoteCast(address indexed voter, uint256 indexed projectId, uint256 newVoteCount);

    /**
     * @notice Emitted when voting is resolved and winner is determined
     * @param winnerProjectId The ID of the winning project
     * @param winnerTitle The title of the winning project
     * @param winnerVoteCount The final vote count of the winner
     */
    event VotingResolved(uint256 indexed winnerProjectId, string winnerTitle, uint256 winnerVoteCount);

    // ============ Errors ============

    /**
     * @notice Thrown when trying to interact with a non-existent project
     */
    error ProjectNotFound();

    /**
     * @notice Thrown when a voter tries to vote for the same project twice
     */
    error AlreadyVotedForProject();

    /**
     * @notice Thrown when a voter tries to vote more than 2 times
     */
    error MaxVotesReached();

    /**
     * @notice Thrown when trying to vote or modify after voting has been resolved
     */
    error VotingAlreadyResolved();

    /**
     * @notice Thrown when trying to resolve voting with no votes cast
     */
    error NoVotesCast();

    /**
     * @notice Thrown when a non-owner tries to call owner-only functions
     */
    error Unauthorized();

    /**
     * @notice Thrown when array lengths don't match in batch operations
     */
    error ArrayLengthMismatch();

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
    ) external;

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
    ) external;

    /**
     * @notice Resolve voting and determine the winner
     * @dev Only callable by contract owner, can only be called once
     */
    function resolveVoting() external;

    // ============ User Functions ============

    /**
     * @notice Cast a vote for a project
     * @dev Each address can vote for up to 2 different projects
     * @param projectId ID of the project to vote for
     */
    function vote(uint256 projectId) external;

    /**
     * @notice Get the project IDs that the caller has voted for
     * @return Array of project IDs (max length 2)
     */
    function getMyVotes() external view returns (uint256[] memory);

    // ============ View Functions ============

    /**
     * @notice Get comprehensive voting data in a single call
     * @dev Returns all data needed by the frontend
     * @param viewer Address of the viewer (to get personalized voting history)
     * @return VotingData struct containing all voting information
     */
    function getVotingData(address viewer) external view returns (VotingData memory);

    /**
     * @notice Get details of a specific project
     * @param projectId ID of the project
     * @return Project struct
     */
    function getProject(uint256 projectId) external view returns (Project memory);

    /**
     * @notice Get the total number of votes cast
     * @return Total number of votes
     */
    function getTotalVotes() external view returns (uint256);

    // ============ State Variables (view functions) ============

    /**
     * @notice Check if voting has been resolved
     * @return True if voting is resolved, false otherwise
     */
    function votingResolved() external view returns (bool);

    /**
     * @notice Get the ID of the winning project
     * @return Winner project ID (0 if not resolved)
     */
    function winnerProjectId() external view returns (uint256);

    /**
     * @notice Get the total number of projects registered
     * @return Total project count
     */
    function projectCount() external view returns (uint256);

    /**
     * @notice Get the total number of unique voters
     * @return Total unique voter count
     */
    function totalVoters() external view returns (uint256);
}
