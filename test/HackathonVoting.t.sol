// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/HackathonVoting.sol";
import "../src/IHackathonVoting.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {
        _mint(msg.sender, 1000000 * 10 ** 18);
    }
}

contract HackathonVotingTest is Test {
    HackathonVoting public voting;
    MockERC20 public prizeToken;
    address public owner;
    address public voter1;
    address public voter2;
    address public voter3;
    address public team1;
    address public team2;
    address public team3;

    uint256 public constant PRIZE_AMOUNT = 30000 * 10 ** 18; // 30,000 tokens

    // Events from IHackathonVoting (required for vm.expectEmit testing)
    event ProjectRegistered(uint256 indexed projectId, string title, string teamName, string category);
    event VoteCast(address indexed voter, uint256 indexed projectId, uint256 newVoteCount);
    event VotingResolved(uint256 indexed winnerProjectId, string winnerTitle, uint256 winnerVoteCount);

    function setUp() public {
        owner = address(this);
        voter1 = makeAddr("voter1");
        voter2 = makeAddr("voter2");
        voter3 = makeAddr("voter3");
        team1 = makeAddr("team1");
        team2 = makeAddr("team2");
        team3 = makeAddr("team3");

        prizeToken = new MockERC20();
        voting = new HackathonVoting(address(prizeToken), PRIZE_AMOUNT);

        // Transfer prize tokens to the contract
        prizeToken.transfer(address(voting), PRIZE_AMOUNT);
    }

    // ============ Registration Tests ============

    function test_RegisterProject() public {
        vm.expectEmit(true, false, false, true);
        emit ProjectRegistered(1, "AI Project", "Team A", "AI");

        voting.registerProject(
            "AI Project",
            "An AI-powered solution",
            "Team A",
            "AI",
            "https://image.url",
            "https://demo.url",
            "https://github.url",
            team1
        );

        assertEq(voting.projectCount(), 1);

        IHackathonVoting.Project memory project = voting.getProject(1);
        assertEq(project.id, 1);
        assertEq(project.title, "AI Project");
        assertEq(project.description, "An AI-powered solution");
        assertEq(project.teamName, "Team A");
        assertEq(project.category, "AI");
        assertEq(project.imageUrl, "https://image.url");
        assertEq(project.demoUrl, "https://demo.url");
        assertEq(project.githubUrl, "https://github.url");
        assertEq(project.voteCount, 0);
        assertEq(project.teamAddress, team1);
    }

    function test_RegisterMultipleProjects() public {
        voting.registerProject("AI Project", "Description 1", "Team A", "AI", "", "", "", team1);

        voting.registerProject("Web3 Project", "Description 2", "Team B", "Web3", "", "", "", team2);

        assertEq(voting.projectCount(), 2);
    }

    function test_RegisterProjects() public {
        string[] memory titles = new string[](3);
        titles[0] = "AI Project";
        titles[1] = "Web3 Project";
        titles[2] = "IoT Project";

        string[] memory descriptions = new string[](3);
        descriptions[0] = "AI Description";
        descriptions[1] = "Web3 Description";
        descriptions[2] = "IoT Description";

        string[] memory teamNames = new string[](3);
        teamNames[0] = "Team A";
        teamNames[1] = "Team B";
        teamNames[2] = "Team C";

        string[] memory categories = new string[](3);
        categories[0] = "AI";
        categories[1] = "Web3";
        categories[2] = "IoT";

        string[] memory imageUrls = new string[](3);
        imageUrls[0] = "img1";
        imageUrls[1] = "img2";
        imageUrls[2] = "img3";

        string[] memory demoUrls = new string[](3);
        demoUrls[0] = "demo1";
        demoUrls[1] = "demo2";
        demoUrls[2] = "demo3";

        string[] memory githubUrls = new string[](3);
        githubUrls[0] = "gh1";
        githubUrls[1] = "gh2";
        githubUrls[2] = "gh3";

        address[] memory teamAddresses = new address[](3);
        teamAddresses[0] = team1;
        teamAddresses[1] = team2;
        teamAddresses[2] = team3;

        voting.registerProjects(
            titles, descriptions, teamNames, categories, imageUrls, demoUrls, githubUrls, teamAddresses
        );

        assertEq(voting.projectCount(), 3);

        IHackathonVoting.Project memory project1 = voting.getProject(1);
        assertEq(project1.title, "AI Project");
        assertEq(project1.teamName, "Team A");

        IHackathonVoting.Project memory project3 = voting.getProject(3);
        assertEq(project3.title, "IoT Project");
        assertEq(project3.teamName, "Team C");
    }

    function test_RevertWhen_RegisterProjectsArrayLengthMismatch() public {
        string[] memory titles = new string[](2);
        titles[0] = "Project 1";
        titles[1] = "Project 2";

        string[] memory descriptions = new string[](3); // Wrong length
        descriptions[0] = "Desc 1";
        descriptions[1] = "Desc 2";
        descriptions[2] = "Desc 3";

        string[] memory teamNames = new string[](2);
        string[] memory imageUrls = new string[](2);
        string[] memory demoUrls = new string[](2);
        string[] memory githubUrls = new string[](2);
        string[] memory categories = new string[](2);
        address[] memory teamAddresses = new address[](2);

        vm.expectRevert(IHackathonVoting.ArrayLengthMismatch.selector);
        voting.registerProjects(
            titles, descriptions, teamNames, categories, imageUrls, demoUrls, githubUrls, teamAddresses
        );
    }

    function test_RevertWhen_NonOwnerRegistersProject() public {
        vm.prank(voter1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", voter1));
        voting.registerProject("Project", "Description", "Team", "AI", "", "", "", address(0));
    }

    // ============ Voting Tests ============

    function test_Vote() public {
        voting.registerProject("Project 1", "Description", "Team A", "AI", "", "", "", team1);

        vm.prank(voter1);
        vm.expectEmit(true, true, false, true);
        emit VoteCast(voter1, 1, 1);
        voting.vote(1);

        IHackathonVoting.Project memory project = voting.getProject(1);
        assertEq(project.voteCount, 1);
        assertEq(voting.totalVoters(), 1);

        vm.prank(voter1);
        uint256[] memory votes = voting.getMyVotes();
        assertEq(votes.length, 1);
        assertEq(votes[0], 1);
    }

    function test_VoteTwoDifferentProjects() public {
        voting.registerProject("Project 1", "Description 1", "Team A", "AI", "", "", "", team1);

        voting.registerProject("Project 2", "Description 2", "Team B", "Web3", "", "", "", team2);

        vm.startPrank(voter1);
        voting.vote(1);
        voting.vote(2);
        vm.stopPrank();

        assertEq(voting.getProject(1).voteCount, 1);
        assertEq(voting.getProject(2).voteCount, 1);
        assertEq(voting.totalVoters(), 1); // Same voter

        vm.prank(voter1);
        uint256[] memory votes = voting.getMyVotes();
        assertEq(votes.length, 2);
        assertEq(votes[0], 1);
        assertEq(votes[1], 2);
    }

    function test_MultipleVotersVoteForSameProject() public {
        voting.registerProject("Project 1", "Description", "Team A", "AI", "", "", "", team1);

        vm.prank(voter1);
        voting.vote(1);

        vm.prank(voter2);
        voting.vote(1);

        vm.prank(voter3);
        voting.vote(1);

        assertEq(voting.getProject(1).voteCount, 3);
        assertEq(voting.totalVoters(), 3);
    }

    function test_RevertWhen_VotingForNonexistentProject() public {
        vm.prank(voter1);
        vm.expectRevert(IHackathonVoting.ProjectNotFound.selector);
        voting.vote(999);
    }

    function test_RevertWhen_VotingForProjectZero() public {
        vm.prank(voter1);
        vm.expectRevert(IHackathonVoting.ProjectNotFound.selector);
        voting.vote(0);
    }

    function test_RevertWhen_VotingForSameProjectTwice() public {
        voting.registerProject("Project 1", "Description", "Team A", "AI", "", "", "", team1);

        vm.startPrank(voter1);
        voting.vote(1);

        vm.expectRevert(IHackathonVoting.AlreadyVotedForProject.selector);
        voting.vote(1);
        vm.stopPrank();
    }

    function test_RevertWhen_VotingMoreThanTwice() public {
        voting.registerProject("Project 1", "Desc", "Team A", "AI", "", "", "", team1);
        voting.registerProject("Project 2", "Desc", "Team B", "Web3", "", "", "", team2);
        voting.registerProject("Project 3", "Desc", "Team C", "IoT", "", "", "", team3);

        vm.startPrank(voter1);
        voting.vote(1);
        voting.vote(2);

        vm.expectRevert(IHackathonVoting.MaxVotesReached.selector);
        voting.vote(3);
        vm.stopPrank();
    }

    function test_VoterCanVoteOnlyOnce() public {
        voting.registerProject("Project 1", "Desc", "Team A", "AI", "", "", "", team1);

        vm.prank(voter1);
        voting.vote(1);

        assertEq(voting.totalVoters(), 1);

        // Voter1 votes for a second project (still counts as 1 unique voter)
        voting.registerProject("Project 2", "Desc", "Team B", "Web3", "", "", "", team2);

        vm.prank(voter1);
        voting.vote(2);

        assertEq(voting.totalVoters(), 1);
    }

    // ============ Resolution Tests ============

    function test_ResolveVoting() public {
        voting.registerProject("Project 1", "Desc", "Team A", "AI", "", "", "", team1);
        voting.registerProject("Project 2", "Desc", "Team B", "Web3", "", "", "", team2);

        vm.prank(voter1);
        voting.vote(1);

        vm.prank(voter2);
        voting.vote(2);

        vm.prank(voter3);
        voting.vote(2);

        vm.expectEmit(true, false, false, true);
        emit VotingResolved(2, "Project 2", 2);
        voting.resolveVoting();

        assertTrue(voting.votingResolved());
        assertEq(voting.winnerProjectId(), 2);
    }

    function test_RevertWhen_ResolvingTwice() public {
        voting.registerProject("Project 1", "Desc", "Team A", "AI", "", "", "", team1);

        vm.prank(voter1);
        voting.vote(1);

        voting.resolveVoting();

        vm.expectRevert(IHackathonVoting.VotingAlreadyResolved.selector);
        voting.resolveVoting();
    }

    function test_RevertWhen_ResolvingWithNoVotes() public {
        voting.registerProject("Project 1", "Desc", "Team A", "AI", "", "", "", team1);

        vm.expectRevert(IHackathonVoting.NoVotesCast.selector);
        voting.resolveVoting();
    }

    function test_RevertWhen_ResolvingWithNoProjects() public {
        vm.expectRevert(IHackathonVoting.NoVotesCast.selector);
        voting.resolveVoting();
    }

    function test_RevertWhen_NonOwnerResolvesVoting() public {
        voting.registerProject("Project 1", "Desc", "Team A", "AI", "", "", "", team1);

        vm.prank(voter1);
        voting.vote(1);

        vm.prank(voter1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", voter1));
        voting.resolveVoting();
    }

    function test_RevertWhen_VotingAfterResolution() public {
        voting.registerProject("Project 1", "Desc", "Team A", "AI", "", "", "", team1);

        vm.prank(voter1);
        voting.vote(1);

        voting.resolveVoting();

        vm.prank(voter2);
        vm.expectRevert(IHackathonVoting.VotingAlreadyResolved.selector);
        voting.vote(1);
    }

    // ============ View Function Tests ============

    function test_GetVotingData() public {
        voting.registerProject("AI Project", "Desc 1", "Team A", "AI", "img1", "demo1", "gh1", team1);
        voting.registerProject("Web3 Project", "Desc 2", "Team B", "Web3", "img2", "demo2", "gh2", team2);

        vm.prank(voter1);
        voting.vote(1);

        vm.prank(voter2);
        voting.vote(1);

        vm.prank(voter2);
        voting.vote(2);

        IHackathonVoting.VotingData memory data = voting.getVotingData(voter2);

        assertEq(data.projects.length, 2);
        assertEq(data.totalVotes, 3);
        assertEq(data.totalVoters, 2);
        assertEq(data.voterProjectIds.length, 2);
        assertEq(data.voterProjectIds[0], 1);
        assertEq(data.voterProjectIds[1], 2);
        assertFalse(data.votingResolved);
        assertEq(data.winnerProjectId, 0);
    }

    function test_GetVotingDataAfterResolution() public {
        voting.registerProject("Project 1", "Desc", "Team A", "AI", "", "", "", team1);

        vm.prank(voter1);
        voting.vote(1);

        voting.resolveVoting();

        IHackathonVoting.VotingData memory data = voting.getVotingData(voter1);

        assertTrue(data.votingResolved);
        assertEq(data.winnerProjectId, 1);
    }

    function test_GetTotalVotes() public {
        voting.registerProject("Project 1", "Desc", "Team A", "AI", "", "", "", team1);
        voting.registerProject("Project 2", "Desc", "Team B", "Web3", "", "", "", team2);

        vm.prank(voter1);
        voting.vote(1);

        vm.prank(voter2);
        voting.vote(1);

        vm.prank(voter2);
        voting.vote(2);

        assertEq(voting.getTotalVotes(), 3);
    }

    // ============ Edge Case Tests ============

    function test_TieBreaker_FirstProjectWins() public {
        voting.registerProject("Project 1", "Desc", "Team A", "AI", "", "", "", team1);
        voting.registerProject("Project 2", "Desc", "Team B", "Web3", "", "", "", team2);

        vm.prank(voter1);
        voting.vote(1);

        vm.prank(voter2);
        voting.vote(2);

        voting.resolveVoting();

        // In case of tie, first project with highest votes wins
        assertEq(voting.winnerProjectId(), 1);
    }

    function test_CategoryStats() public {
        voting.registerProject("AI 1", "Desc", "Team A", "AI", "", "", "", team1);
        voting.registerProject("AI 2", "Desc", "Team B", "AI", "", "", "", team2);
        voting.registerProject("Web3 1", "Desc", "Team C", "Web3", "", "", "", team3);

        vm.prank(voter1);
        voting.vote(1);

        vm.prank(voter2);
        voting.vote(1);

        vm.prank(voter2);
        voting.vote(3);
    }

    function test_EmptyVoterHistory() public {
        voting.registerProject("Project 1", "Desc", "Team A", "AI", "", "", "", team1);

        vm.prank(voter1);
        uint256[] memory votes = voting.getMyVotes();
        assertEq(votes.length, 0);
    }

    function testFuzz_Vote(address _voter, uint256 _projectId) public {
        vm.assume(_voter != address(0));
        vm.assume(_voter != owner);

        // Register enough projects
        for (uint256 i = 0; i < 5; i++) {
            voting.registerProject("Project", "Desc", "Team", "AI", "", "", "", address(0));
        }

        // Bound project ID to valid range
        uint256 projectId = bound(_projectId, 1, 5);

        vm.prank(_voter);
        voting.vote(projectId);

        assertEq(voting.getProject(projectId).voteCount, 1);
    }

    // ============ Prize Distribution Tests ============

    function test_PrizeDistributionToTop3() public {
        // Register 5 projects with different teams
        address team4 = makeAddr("team4");
        address team5 = makeAddr("team5");

        voting.registerProject("Project 1", "Desc", "Team A", "AI", "", "", "", team1);
        voting.registerProject("Project 2", "Desc", "Team B", "Web3", "", "", "", team2);
        voting.registerProject("Project 3", "Desc", "Team C", "IoT", "", "", "", team3);
        voting.registerProject("Project 4", "Desc", "Team D", "DeFi", "", "", "", team4);
        voting.registerProject("Project 5", "Desc", "Team E", "NFT", "", "", "", team5);

        // Cast votes: Project 1 gets 5 votes, Project 2 gets 3 votes, Project 3 gets 2 votes
        address[] memory voters = new address[](10);
        for (uint256 i = 0; i < 10; i++) {
            voters[i] = makeAddr(string(abi.encodePacked("voter_", i)));
        }

        // Project 1: 5 votes (1st place)
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(voters[i]);
            voting.vote(1);
        }

        // Project 2: 3 votes (2nd place)
        for (uint256 i = 5; i < 8; i++) {
            vm.prank(voters[i]);
            voting.vote(2);
        }

        // Project 3: 2 votes (3rd place)
        for (uint256 i = 8; i < 10; i++) {
            vm.prank(voters[i]);
            voting.vote(3);
        }

        // Resolve voting and check prize distribution
        uint256 prizePerWinner = PRIZE_AMOUNT / 3;

        voting.resolveVoting();

        // Check that top 3 teams received their prizes
        assertEq(prizeToken.balanceOf(team1), prizePerWinner, "Team 1 should receive prize");
        assertEq(prizeToken.balanceOf(team2), prizePerWinner, "Team 2 should receive prize");
        assertEq(prizeToken.balanceOf(team3), prizePerWinner, "Team 3 should receive prize");
        assertEq(prizeToken.balanceOf(team4), 0, "Team 4 should not receive prize");
        assertEq(prizeToken.balanceOf(team5), 0, "Team 5 should not receive prize");

        // Verify winner
        assertEq(voting.winnerProjectId(), 1);
    }

    function test_PrizeDistributionWithLessThan3Projects() public {
        // Register only 2 projects
        voting.registerProject("Project 1", "Desc", "Team A", "AI", "", "", "", team1);
        voting.registerProject("Project 2", "Desc", "Team B", "Web3", "", "", "", team2);

        vm.prank(voter1);
        voting.vote(1);

        vm.prank(voter2);
        voting.vote(2);

        vm.prank(voter3);
        voting.vote(2);

        uint256 prizePerWinner = PRIZE_AMOUNT / 3;

        voting.resolveVoting();

        // Both teams should receive prizes (top 3, but only 2 projects exist)
        assertEq(prizeToken.balanceOf(team1), prizePerWinner, "Team 1 should receive prize (2nd place)");
        assertEq(prizeToken.balanceOf(team2), prizePerWinner, "Team 2 should receive prize (1st place)");

        // Winner should be project 2
        assertEq(voting.winnerProjectId(), 2);
    }

    // ============ Fuzz Tests ============

    function testFuzz_VotingWithRandomVoters(uint8 numVoters, uint8 projectChoice) public {
        // Bound inputs to reasonable ranges
        numVoters = uint8(bound(numVoters, 1, 100));

        // Register 3 test projects
        voting.registerProject(
            "Project 1",
            "Description 1",
            "Team 1",
            "AI",
            "https://example.com/1.png",
            "https://demo1.com",
            "https://github.com/team1",
            team1
        );
        voting.registerProject(
            "Project 2",
            "Description 2",
            "Team 2",
            "Web3",
            "https://example.com/2.png",
            "https://demo2.com",
            "https://github.com/team2",
            team2
        );
        voting.registerProject(
            "Project 3",
            "Description 3",
            "Team 3",
            "IoT",
            "https://example.com/3.png",
            "https://demo3.com",
            "https://github.com/team3",
            team3
        );

        // Bound project choice to 1-3
        uint256 chosenProject = bound(projectChoice, 1, 3);
        // Second project is different from first
        uint256 secondProject = chosenProject == 3 ? 1 : chosenProject + 1;

        // Generate random voters and have them vote
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < numVoters; i++) {
            address voter = address(uint160(uint256(keccak256(abi.encodePacked("voter", i)))));
            vm.prank(voter);

            // Each voter votes for first project
            voting.vote(chosenProject);
            totalVotes++;

            // Second vote for different project
            vm.prank(voter);
            voting.vote(secondProject);
            totalVotes++;
        }

        // Verify total votes
        assertEq(voting.getTotalVotes(), totalVotes, "Total votes should match");

        // Get project info and verify vote counts
        IHackathonVoting.Project memory project1 = voting.getProject(chosenProject);
        IHackathonVoting.Project memory project2 = voting.getProject(secondProject);
        assertEq(project1.voteCount, numVoters, "First project should have numVoters votes");
        assertEq(project2.voteCount, numVoters, "Second project should have numVoters votes");
    }

    function testFuzz_ResolveVotingWithRandomDistribution(
        uint8 votes1,
        uint8 votes2,
        uint8 votes3
    ) public {
        // Bound to reasonable ranges
        votes1 = uint8(bound(votes1, 0, 50));
        votes2 = uint8(bound(votes2, 0, 50));
        votes3 = uint8(bound(votes3, 0, 50));

        // Need at least one vote
        vm.assume(votes1 + votes2 + votes3 > 0);

        // Register 3 projects
        voting.registerProject(
            "Project 1", "Description 1", "Team 1", "AI",
            "https://example.com/1.png", "https://demo1.com",
            "https://github.com/team1", team1
        );
        voting.registerProject(
            "Project 2", "Description 2", "Team 2", "Web3",
            "https://example.com/2.png", "https://demo2.com",
            "https://github.com/team2", team2
        );
        voting.registerProject(
            "Project 3", "Description 3", "Team 3", "IoT",
            "https://example.com/3.png", "https://demo3.com",
            "https://github.com/team3", team3
        );

        // Cast votes for each project
        for (uint256 i = 0; i < votes1; i++) {
            address voter = address(uint160(uint256(keccak256(abi.encodePacked("voter1", i)))));
            vm.prank(voter);
            voting.vote(1);
        }
        for (uint256 i = 0; i < votes2; i++) {
            address voter = address(uint160(uint256(keccak256(abi.encodePacked("voter2", i)))));
            vm.prank(voter);
            voting.vote(2);
        }
        for (uint256 i = 0; i < votes3; i++) {
            address voter = address(uint160(uint256(keccak256(abi.encodePacked("voter3", i)))));
            vm.prank(voter);
            voting.vote(3);
        }

        // Resolve voting
        voting.resolveVoting();

        // Determine expected winner (project with most votes)
        uint256 expectedWinner;
        if (votes1 >= votes2 && votes1 >= votes3) {
            expectedWinner = 1;
        } else if (votes2 >= votes3) {
            expectedWinner = 2;
        } else {
            expectedWinner = 3;
        }

        assertEq(voting.winnerProjectId(), expectedWinner, "Winner should be project with most votes");

        // Verify prize distribution
        uint256 prizePerWinner = PRIZE_AMOUNT / 3;

        // Count how many projects have votes
        uint256 projectsWithVotes = 0;
        if (votes1 > 0) projectsWithVotes++;
        if (votes2 > 0) projectsWithVotes++;
        if (votes3 > 0) projectsWithVotes++;

        // At least top 1 should get prize if they have votes
        if (votes1 > 0 || votes2 > 0 || votes3 > 0) {
            uint256 totalPrizesDistributed = prizeToken.balanceOf(team1) +
                                            prizeToken.balanceOf(team2) +
                                            prizeToken.balanceOf(team3);

            // Total prizes should be (min of 3 or projectsWithVotes) * prizePerWinner
            uint256 expectedPrizes = (projectsWithVotes < 3 ? projectsWithVotes : 3) * prizePerWinner;
            assertEq(totalPrizesDistributed, expectedPrizes, "Total prizes distributed should match expected");
        }
    }

    function testFuzz_PrizeDistributionToTop3Only(
        uint8 numProjects,
        uint8 voteSeed
    ) public {
        // Bound to 4-10 projects to ensure we have more than 3
        numProjects = uint8(bound(numProjects, 4, 10));

        // Register projects
        address[] memory teams = new address[](numProjects);
        for (uint256 i = 0; i < numProjects; i++) {
            teams[i] = address(uint160(uint256(keccak256(abi.encodePacked("team", i)))));
            voting.registerProject(
                string(abi.encodePacked("Project ", vm.toString(i + 1))),
                "Description",
                string(abi.encodePacked("Team ", vm.toString(i + 1))),
                "Category",
                "https://example.com/img.png",
                "https://demo.com",
                "https://github.com/team",
                teams[i]
            );
        }

        // Cast votes with decreasing amounts (to ensure clear top 3)
        for (uint256 i = 0; i < numProjects; i++) {
            // Project i+1 gets (numProjects - i) votes
            uint256 votesForProject = numProjects - i + uint256(voteSeed) % 3;

            for (uint256 j = 0; j < votesForProject; j++) {
                address voter = address(uint160(uint256(keccak256(abi.encodePacked("voter", i, j)))));
                vm.prank(voter);
                voting.vote(i + 1);
            }
        }

        // Resolve voting
        voting.resolveVoting();

        // Only top 3 should have received prizes
        uint256 prizePerWinner = PRIZE_AMOUNT / 3;
        uint256 projectsWithPrizes = 0;

        for (uint256 i = 0; i < numProjects; i++) {
            if (prizeToken.balanceOf(teams[i]) > 0) {
                projectsWithPrizes++;
                assertEq(prizeToken.balanceOf(teams[i]), prizePerWinner, "Prize amount should be correct");
            }
        }

        // Exactly 3 projects should receive prizes (or less if fewer have votes)
        assertLe(projectsWithPrizes, 3, "No more than 3 projects should receive prizes");
        assertEq(projectsWithPrizes, 3, "Exactly 3 projects should receive prizes");
    }

    function testFuzz_CannotVoteForNonexistentProject(uint256 projectId) public {
        // Register 2 projects
        voting.registerProject(
            "Project 1", "Desc", "Team", "Cat",
            "img", "demo", "github", team1
        );
        voting.registerProject(
            "Project 2", "Desc", "Team", "Cat",
            "img", "demo", "github", team2
        );

        // Assume projectId is not 1 or 2
        vm.assume(projectId != 1 && projectId != 2);

        vm.prank(voter1);
        vm.expectRevert(IHackathonVoting.ProjectNotFound.selector);
        voting.vote(projectId);
    }

    function testFuzz_VoterCanVoteTwiceForDifferentProjects(
        uint8 project1,
        uint8 project2
    ) public {
        // Register 5 projects
        for (uint256 i = 1; i <= 5; i++) {
            voting.registerProject(
                string(abi.encodePacked("Project ", vm.toString(i))),
                "Description",
                "Team",
                "Category",
                "https://example.com/img.png",
                "https://demo.com",
                "https://github.com/team",
                address(uint160(i))
            );
        }

        // Bound to valid projects
        project1 = uint8(bound(project1, 1, 5));
        project2 = uint8(bound(project2, 1, 5));

        // Assume they're different
        vm.assume(project1 != project2);

        // Voter should be able to vote for two different projects
        vm.prank(voter1);
        voting.vote(project1);

        vm.prank(voter1);
        voting.vote(project2);

        // Verify votes were recorded
        assertEq(voting.getProject(project1).voteCount, 1);
        assertEq(voting.getProject(project2).voteCount, 1);
    }
}
