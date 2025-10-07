// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/HackathonVoting.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address prizeToken = vm.envAddress("PRIZE_TOKEN_ADDRESS");
        uint256 prizeAmount = vm.envUint("PRIZE_AMOUNT");

        vm.startBroadcast(deployerPrivateKey);

        HackathonVoting voting = new HackathonVoting(prizeToken, prizeAmount);

        console.log("HackathonVoting deployed to:", address(voting));
        console.log("Prize Token:", prizeToken);
        console.log("Prize Amount:", prizeAmount);

        vm.stopBroadcast();
    }
}
