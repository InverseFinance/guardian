// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

interface IGovernorMills {
    function cancel(uint proposalId) external;
}

contract Guardian {

    IGovernorMills public immutable governorMills;
    address public deployer;
    address public rwg;
    mapping (uint => bool) public cancellableProposals;

    constructor(IGovernorMills _governorMills, address _rwg) {
        governorMills = _governorMills;
        rwg = _rwg;
        deployer = msg.sender;
    }

    function allowCancel(uint proposalId, bool decision) external {
        require(msg.sender == deployer, "Guardian: not deployer");
        cancellableProposals[proposalId] = decision;
    }

    function executeCancel(uint proposalId) external {
        require(msg.sender == rwg, "Guardian: not rwg");
        require(cancellableProposals[proposalId], "Guardian: not cancellable");
        governorMills.cancel(proposalId);
    }

    function setRwg(address _rwg) external {
        require(msg.sender == rwg, "Guardian: not rwg");
        rwg = _rwg;
    }

    function setDeployer(address _deployer) external {
        require(msg.sender == deployer, "Guardian: not deployer");
        deployer = _deployer;
    }

}
