// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HackathonVoting.sol";

contract SetupProjectsScript is Script {
    function run() external {
        string memory json = vm.readFile(string.concat(vm.projectRoot(), "/projects.json"));
        bytes memory projectsRaw = vm.parseJson(json, ".projects");
        Project[] memory projectsList = abi.decode(projectsRaw, (Project[]));

        uint256 numProjects = projectsList.length;
        string[] memory titles = new string[](numProjects);
        string[] memory descriptions = new string[](numProjects);
        string[] memory teamNames = new string[](numProjects);
        string[] memory categories = new string[](numProjects);
        string[] memory imageUrls = new string[](numProjects);
        string[] memory demoUrls = new string[](numProjects);
        string[] memory githubUrls = new string[](numProjects);

        for (uint256 i = 0; i < numProjects; i++) {
            titles[i] = projectsList[i].title;
            descriptions[i] = projectsList[i].description;
            teamNames[i] = projectsList[i].teamName;
            categories[i] = projectsList[i].category;
            imageUrls[i] = projectsList[i].imageUrl;
            demoUrls[i] = projectsList[i].demoUrl;
            githubUrls[i] = projectsList[i].githubUrl;
        }

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        HackathonVoting(vm.envAddress("VOTING_CONTRACT_ADDRESS")).registerProjects(
            titles, descriptions, teamNames, categories, imageUrls, demoUrls, githubUrls
        );
        vm.stopBroadcast();

        console.log("Successfully registered", numProjects, "projects");
    }
}

struct Project {
    string title;
    string description;
    string teamName;
    string category;
    string imageUrl;
    string demoUrl;
    string githubUrl;
}
