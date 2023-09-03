// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "hardhat/console.sol";

contract Streamer is Ownable {
    event Opened(address indexed rube, uint256 indexed amount);
    event Challenged(address indexed rube);
    event Withdrawn(address indexed owner, uint256 indexed payment);
    event Closed(address indexed rube);
    event NewOpened(address indexed rube, uint256 indexed amount);

    mapping(address => uint256) balances;
    mapping(address => uint256) canCloseAt;

    bool channelIsOpen = false;

    function fundChannel() public payable {
       if (balances[msg.sender] != 0) {
            revert("Channel already opened");
    }
       balances[msg.sender] = msg.value;
       emit Opened(msg.sender, msg.value);
    }

    function timeLeft(address channel) public view returns (uint256) {
        require(canCloseAt[channel] != 0, "channel is not closing");
        return canCloseAt[channel] - block.timestamp;
    }

    function withdrawEarnings(Voucher calldata voucher) public onlyOwner{
        bytes32 hashed = keccak256(abi.encode(voucher.updatedBalance));
        bytes memory prefixed = abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            hashed
        );
        bytes32 prefixedHashed = keccak256(prefixed);

        Signature memory sig = voucher.sig;
        address signer = ecrecover(prefixedHashed, sig.v, sig.r, sig.s);
        require(signer != address(0), "ECDSA: invalid signer signature");

        console.log('withdraw', balances[signer], voucher.updatedBalance);

        require(balances[signer] > voucher.updatedBalance,"Insufficient balance");
        uint256 payment = balances[signer] - voucher.updatedBalance;
        balances[signer] = voucher.updatedBalance;
        (bool sent,) = owner().call{value: payment}("");
        require(sent, "Streamer: withdrawEarnings: payment to owner failed");
        emit Withdrawn(owner(), payment);
    }
   
   function challengeChannel() public {
        require(balances[msg.sender] >= 0, "Channel is closing");
        canCloseAt[msg.sender] = block.timestamp + 30 seconds;
        emit Challenged(msg.sender);
   }

   function defundChannel() public {
        require(canCloseAt[msg.sender] != 0, "channel is not closing");
        require(canCloseAt[msg.sender] <= block.timestamp,"cannot close channel yet");
        (bool sent,) = msg.sender.call{value: balances[msg.sender]}("");
        require(sent, "Streamer: defundChannel: repayment failed");
        balances[msg.sender] = 0;
        emit Closed(msg.sender);
   }


    struct Voucher {
        uint256 updatedBalance;
        Signature sig;
    }
    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }
}