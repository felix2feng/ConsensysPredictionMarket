pragma solidity ^0.4.4;

contract Owned {
  address public owner;
  

  function Owned () {
    owner = msg.sender;
  }

  modifier isOwner () {
    require(msg.sender == owner);
    _;
  }

  event LogChangeOwner(address sender, address _newOwner);
  
  function changeOwner(address newOwner) 
    public
    isOwner
    returns (bool success)
  {
      owner = newOwner;

      LogChangeOwner(msg.sender, newOwner);
      return true;
  }
}