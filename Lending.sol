// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Lending {
    IERC20 public token;

    mapping(address => uint256) public collateralBalance;
    mapping(address => uint256) public borrowedBalance;

    // Teminatın yüzde kaçına kadar borç alınabilir (örn: 66 = %66)
    uint256 public constant COLLATERAL_FACTOR = 66;

    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event Borrowed(address indexed user, uint256 amount);
    event Repaid(address indexed user, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    // Teminat yatır
    function depositCollateral(uint256 amount) external {
        require(amount > 0, "Miktar sifir olamaz");
        token.transferFrom(msg.sender, address(this), amount);
        collateralBalance[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    // Teminat karsiliginda borc al
    function borrow(uint256 amount) external {
        uint256 maxBorrow = (collateralBalance[msg.sender] * COLLATERAL_FACTOR) / 100;
        require(borrowedBalance[msg.sender] + amount <= maxBorrow, "Teminat yetersiz");
        require(token.balanceOf(address(this)) >= amount, "Kontratta yeterli likidite yok");

        borrowedBalance[msg.sender] += amount;
        token.transfer(msg.sender, amount);
        emit Borrowed(msg.sender, amount);
    }

    // Borcu geri ode
    function repay(uint256 amount) external {
        require(amount > 0 && amount <= borrowedBalance[msg.sender], "Gecersiz miktar");
        token.transferFrom(msg.sender, address(this), amount);
        borrowedBalance[msg.sender] -= amount;
        emit Repaid(msg.sender, amount);
    }

    // Borcu yoksa teminati geri cek
    function withdrawCollateral(uint256 amount) external {
        require(amount <= collateralBalance[msg.sender], "Yetersiz teminat");
        collateralBalance[msg.sender] -= amount;

        uint256 maxBorrow = (collateralBalance[msg.sender] * COLLATERAL_FACTOR) / 100;
        require(borrowedBalance[msg.sender] <= maxBorrow, "Once borcu azalt");

        token.transfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
}
