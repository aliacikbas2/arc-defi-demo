// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFaucetCheck { function lastClaim(address) external view returns (uint256); }
interface IStakingCheck { function stakedBalance(address) external view returns (uint256); }
interface ILendingCheck { function borrowedBalance(address) external view returns (uint256); }

contract Badges {
    IFaucetCheck public faucet;
    IStakingCheck public staking;
    ILendingCheck public lending;

    mapping(address => mapping(uint8 => bool)) public hasBadge;

    event BadgeClaimed(address indexed user, uint8 indexed badgeId);

    constructor(address _faucet, address _staking, address _lending) {
        faucet = IFaucetCheck(_faucet);
        staking = IStakingCheck(_staking);
        lending = ILendingCheck(_lending);
    }

    function claimFaucetBadge() external {
        require(!hasBadge[msg.sender][0], "Zaten alinmis");
        require(faucet.lastClaim(msg.sender) > 0, "Once faucet kullan");
        hasBadge[msg.sender][0] = true;
        emit BadgeClaimed(msg.sender, 0);
    }

    function claimStakerBadge() external {
        require(!hasBadge[msg.sender][1], "Zaten alinmis");
        require(staking.stakedBalance(msg.sender) > 0, "Once stake et");
        hasBadge[msg.sender][1] = true;
        emit BadgeClaimed(msg.sender, 1);
    }

    function claimBorrowerBadge() external {
        require(!hasBadge[msg.sender][2], "Zaten alinmis");
        require(lending.borrowedBalance(msg.sender) > 0, "Once borc al");
        hasBadge[msg.sender][2] = true;
        emit BadgeClaimed(msg.sender, 2);
    }

    function getBadges(address user) external view returns (bool, bool, bool) {
        return (hasBadge[user][0], hasBadge[user][1], hasBadge[user][2]);
    }
}
