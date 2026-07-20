// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Escrow {
    IERC20 public token;

    enum Status { Active, Released, Refunded }

    struct Deal {
        address depositor;
        address beneficiary;
        address arbiter;
        uint256 amount;
        Status status;
    }

    uint256 public nextDealId;
    mapping(uint256 => Deal) public deals;

    event DealCreated(uint256 indexed dealId, address indexed depositor, address indexed beneficiary, address arbiter, uint256 amount);
    event Released(uint256 indexed dealId);
    event Refunded(uint256 indexed dealId);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function createDeal(address beneficiary, address arbiter, uint256 amount) external returns (uint256) {
        require(beneficiary != address(0), "Gecersiz alici");
        require(amount > 0, "Miktar sifir olamaz");

        token.transferFrom(msg.sender, address(this), amount);

        uint256 dealId = nextDealId++;
        deals[dealId] = Deal({
            depositor: msg.sender,
            beneficiary: beneficiary,
            arbiter: arbiter,
            amount: amount,
            status: Status.Active
        });

        emit DealCreated(dealId, msg.sender, beneficiary, arbiter, amount);
        return dealId;
    }

    function release(uint256 dealId) external {
        Deal storage d = deals[dealId];
        require(d.status == Status.Active, "Islem aktif degil");
        require(msg.sender == d.depositor || msg.sender == d.arbiter, "Yetkin yok");

        d.status = Status.Released;
        token.transfer(d.beneficiary, d.amount);
        emit Released(dealId);
    }

    function refund(uint256 dealId) external {
        Deal storage d = deals[dealId];
        require(d.status == Status.Active, "Islem aktif degil");
        require(msg.sender == d.beneficiary || msg.sender == d.arbiter, "Yetkin yok");

        d.status = Status.Refunded;
        token.transfer(d.depositor, d.amount);
        emit Refunded(dealId);
    }

    function getDeal(uint256 dealId) external view returns (address, address, address, uint256, Status) {
        Deal memory d = deals[dealId];
        return (d.depositor, d.beneficiary, d.arbiter, d.amount, d.status);
    }
}
