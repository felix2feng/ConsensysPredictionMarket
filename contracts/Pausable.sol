pragma solidity ^0.4.4;

import './Owned.sol';

contract Pausable is Owned {
  bool paused;

  event LogIsPaused(bool isPaused);

  modifier isNotPaused {
    require(paused == false);
    _;
  }

  function Pausable() {
    paused = false;
  }

  function pauseContract() 
    public
    isOwner
    returns (bool success)
  {
    paused = true;
    LogIsPaused(true);
    return true;
  }

  function unpauseContract() 
    public
    isOwner
    returns (bool success)
  {
    paused = false;
    LogIsPaused(false);
    return true;
  }
}