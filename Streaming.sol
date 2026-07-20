// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Streaming {
    IERC20 public token;

    struct Stream {
        address sender;
        address recipient;
        uint256 totalAmount;
        uint256 startTime;
        uint256 endTime;
        uint256 withdrawn;
        bool cancelled;
    }

    uint256 public nextStreamId;
    mapping(uint256 => Stream) public streams;

    event StreamCreated(uint256 indexed streamId, address indexed sender, address indexed recipient, uint256 amount, uint256 startTime, uint256 endTime);
    event Withdrawn(uint256 indexed streamId, address indexed recipient, uint256 amount);
    event Cancelled(uint256 indexed streamId);

    constructor(address _token) {
        token = IERC20(_token);
    }

    // Yeni bir odeme akisi olustur
    function createStream(address recipient, uint256 totalAmount, uint256 durationSeconds) external returns (uint256) {
        require(recipient != address(0), "Gecersiz alici");
        require(totalAmount > 0, "Miktar sifir olamaz");
        require(durationSeconds > 0, "Sure sifir olamaz");

        token.transferFrom(msg.sender, address(this), totalAmount);

        uint256 streamId = nextStreamId++;
        streams[streamId] = Stream({
            sender: msg.sender,
            recipient: recipient,
            totalAmount: totalAmount,
            startTime: block.timestamp,
            endTime: block.timestamp + durationSeconds,
            withdrawn: 0,
            cancelled: false
        });

        emit StreamCreated(streamId, msg.sender, recipient, totalAmount, block.timestamp, block.timestamp + durationSeconds);
        return streamId;
    }

    // Su ana kadar hak edilen ama henuz cekilmemis miktar
    function withdrawable(uint256 streamId) public view returns (uint256) {
        Stream memory s = streams[streamId];
        if (s.cancelled) return 0;

        uint256 elapsed = block.timestamp >= s.endTime ? (s.endTime - s.startTime) : (block.timestamp - s.startTime);
        uint256 vested = (s.totalAmount * elapsed) / (s.endTime - s.startTime);
        return vested - s.withdrawn;
    }

    // Alici, o ana kadar hak ettigi kismi ceker
    function withdraw(uint256 streamId) external {
        Stream storage s = streams[streamId];
        require(msg.sender == s.recipient, "Sadece alici cekebilir");
        uint256 amount = withdrawable(streamId);
        require(amount > 0, "Cekilecek miktar yok");

        s.withdrawn += amount;
        token.transfer(s.recipient, amount);

        emit Withdrawn(streamId, s.recipient, amount);
    }

    // Gonderen, akisi iptal edip kalan (henuz hak edilmemis) kismi geri alir
    function cancelStream(uint256 streamId) external {
        Stream storage s = streams[streamId];
        require(msg.sender == s.sender, "Sadece gonderen iptal edebilir");
        require(!s.cancelled, "Zaten iptal edilmis");

        uint256 owedToRecipient = withdrawable(streamId);
        uint256 remainder = s.totalAmount - s.withdrawn - owedToRecipient;

        s.cancelled = true;
        s.withdrawn += owedToRecipient;

        if (owedToRecipient > 0) token.transfer(s.recipient, owedToRecipient);
        if (remainder > 0) token.transfer(s.sender, remainder);

        emit Cancelled(streamId);
    }

    // Bir kullanicinin gonderdigi/aldigi akislari listelemek icin yardimci
    function getStream(uint256 streamId) external view returns (address, address, uint256, uint256, uint256, uint256, bool) {
        Stream memory s = streams[streamId];
        return (s.sender, s.recipient, s.totalAmount, s.startTime, s.endTime, s.withdrawn, s.cancelled);
    }
}
