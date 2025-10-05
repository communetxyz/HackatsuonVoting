// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HackathonVoting.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        HackathonVoting voting = new HackathonVoting();

        console.log("HackathonVoting deployed to:", address(voting));

        vm.stopBroadcast();
    }
}
