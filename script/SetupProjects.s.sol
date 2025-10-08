// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HackathonVoting.sol";

contract SetupProjectsScript is Script {
    function run() external {
        // Use gnosis-deploy.json for Gnosis Chain (chain ID 100), otherwise use holesky-deploy.json
        string memory projectFile = block.chainid == 100 ? "/gnosis-deploy.json" : "/holesky-deploy.json";
        string memory json = vm.readFile(string.concat(vm.projectRoot(), projectFile));

        // Parse individual string arrays from JSON
        string[] memory titles = abi.decode(vm.parseJson(json, ".projects[*].title"), (string[]));
        string[] memory descriptions = abi.decode(vm.parseJson(json, ".projects[*].description"), (string[]));
        string[] memory teamNames = abi.decode(vm.parseJson(json, ".projects[*].teamName"), (string[]));
        string[] memory categories = abi.decode(vm.parseJson(json, ".projects[*].category"), (string[]));
        string[] memory imageUrls = abi.decode(vm.parseJson(json, ".projects[*].imageUrl"), (string[]));
        string[] memory demoUrls = abi.decode(vm.parseJson(json, ".projects[*].demoUrl"), (string[]));
        string[] memory githubUrls = abi.decode(vm.parseJson(json, ".projects[*].githubUrl"), (string[]));
        address[] memory teamAddresses = abi.decode(vm.parseJson(json, ".projects[*].teamAddress"), (address[]));

        uint256 numProjects = titles.length;

        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        HackathonVoting(vm.envAddress("VOTING_CONTRACT_ADDRESS")).registerProjects(
            titles, descriptions, teamNames, categories, imageUrls, demoUrls, githubUrls, teamAddresses
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
    address teamAddress;
}
