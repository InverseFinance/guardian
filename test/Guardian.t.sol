// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console2} from "forge-std/Test.sol";
import {Guardian, IGovernorMills} from "../src/Guardian.sol";

contract MockGovernorMills {
    mapping (uint => bool) public cancelled;

    function cancel(uint proposalId) external {
        cancelled[proposalId] = true;
    }
}

contract GuardianTest is Test {
    address public constant rwg = address(0xdeadbeef);
    IGovernorMills public governorMills;
    Guardian public guardian;

    function setUp() public {
        governorMills = IGovernorMills(address(new MockGovernorMills()));
        guardian = new Guardian(governorMills, rwg);
    }

    function testConstructor() public {
        assertEq(address(guardian.governorMills()), address(governorMills));
        assertEq(guardian.rwg(), rwg);
        assertEq(guardian.deployer(), address(this));
    }

    function testAllowCancel() public {
        uint proposalId = 1;
        bool decision = true;

        // Test that only the deployer can allow cancel
        vm.prank(rwg);
        try guardian.allowCancel(proposalId, decision) {
            fail("allowCancel should only be callable by deployer");
        } catch Error(string memory reason) {
            assertEq(reason, "Guardian: not deployer");
        }
        
        // Test that the deployer can allow cancel
        guardian.allowCancel(proposalId, decision);
        assertEq(guardian.cancellableProposals(proposalId), decision);
    }

    function testExecuteCancel() public {
        uint proposalId = 1;
        bool decision = true;

        // Test that only the rwg can execute cancel
        try guardian.executeCancel(proposalId) {
            fail("executeCancel should only be callable by rwg");
        } catch Error(string memory reason) {
            assertEq(reason, "Guardian: not rwg");
        }

        // Test that the rwg cannot execute cancel without allowCancel
        vm.prank(rwg);
        try guardian.executeCancel(proposalId) {
            fail("executeCancel should not be callable without allowCancel");
        } catch Error(string memory reason) {
            assertEq(reason, "Guardian: not cancellable");
        }
        assertEq(MockGovernorMills(address(governorMills)).cancelled(proposalId), false);

        // Test that the rwg can execute cancel with allowCancel
        guardian.allowCancel(proposalId, decision);
        vm.prank(rwg);
        guardian.executeCancel(proposalId);
        assertEq(MockGovernorMills(address(governorMills)).cancelled(proposalId), true);
    }

    function testSetDeployer() public {
        address newDeployer = address(0xdeadbeef);

        // Test that only the deployer can set deployer
        vm.prank(rwg);
        try guardian.setPendingDeployer(newDeployer) {
            fail("setPendingDeployer should only be callable by deployer");
        } catch Error(string memory reason) {
            assertEq(reason, "Guardian: not deployer");
        }

        // Test that the deployer can set deployer
        guardian.setPendingDeployer(newDeployer);
        assertEq(guardian.pendingDeployer(), newDeployer);
    }

    function testClaimDeployer() public {
        address newDeployer = address(0xdeadbeef);

        // Test that only the deployer can set deployer
        guardian.setPendingDeployer(newDeployer);
        vm.prank(address(0xc0ffee));
        try guardian.claimDeployer() {
            fail("claimDeployer should only be callable by pending deployer");
        } catch Error(string memory reason) {
            assertEq(reason, "Guardian: not pending deployer");
        }

        // Test that the deployer can set deployer
        vm.prank(newDeployer);
        guardian.claimDeployer();
        assertEq(guardian.deployer(), newDeployer);
    }

    function testSetPendingRwg() public {
        address newRwg = address(0xdeadbeef);

        // Test that only the rwg can set rwg
        try guardian.setPendingRwg(newRwg) {
            fail("setPendingRwg should only be callable by rwg");
        } catch Error(string memory reason) {
            assertEq(reason, "Guardian: not rwg");
        }

        // Test that the rwg can set rwg
        vm.prank(rwg);
        guardian.setPendingRwg(newRwg);
        assertEq(guardian.pendingRwg(), newRwg);
    }

    function testClaimRwg() public {
        address newRwg = address(0xdeadbeef);

        // Test that only the rwg can set rwg
        vm.prank(rwg);
        guardian.setPendingRwg(newRwg);
        try guardian.claimRwg() {
            fail("claimRwg should only be callable by rwg");
        } catch Error(string memory reason) {
            assertEq(reason, "Guardian: not pending rwg");
        }

        // Test that the rwg can set rwg
        vm.prank(newRwg);
        guardian.claimRwg();
        assertEq(guardian.rwg(), newRwg);
    }
}
