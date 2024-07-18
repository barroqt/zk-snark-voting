// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/Voting.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the Voting contract
        Voting voting = new Voting();

        console.log("Voting contract deployed at:", address(voting));

        vm.stopBroadcast();
    }
}
