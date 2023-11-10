// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {Guardian, IGovernorMills} from "../src/Guardian.sol";

contract GuardianScript is Script {
    function setUp() public {}

    IGovernorMills constant governorMills = IGovernorMills(0xBeCCB6bb0aa4ab551966A7E4B97cec74bb359Bf6);
    address constant rwg = address(0xE3eD95e130ad9E15643f5A5f232a3daE980784cd);

    function run() public {
        vm.startBroadcast();
        new Guardian(governorMills, rwg);
    }
}
