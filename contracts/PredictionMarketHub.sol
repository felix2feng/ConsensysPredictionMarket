pragma solidity ^0.4.4;

import './Pausable.sol';
import './PredictionMarket.sol';

contract PredictionMarketHub is Pausable {
  address[] public predictionMarkets;

  mapping(address => bool) public predictionMarketExists;
  
  modifier marketExists(address marketAddress) {
      require(predictionMarketExists[marketAddress] == true);
      _;
  }

  event LogNewPredictionMarket(address sponsor, address predictionMarketAddress);
  event LogMarketPaused(address sender);
  event LogMarketUnpaused(address sender);
  event LogMarketSponsorChanged(address sender, address newSponsor);

  function PredictionMarketHub
  () {}
  
  function getCampaignCount() 
    public
    constant
    returns (uint campaignCount)
  {
      return predictionMarkets.length;
  }

  function createNewPredictionMarket() 
    public
    returns (address predictionMarketAddress)
  {
    // Learning - contract types are immediately converted to address
    PredictionMarket newMarket = new PredictionMarket(msg.sender);

    require(predictionMarketExists[newMarket] == false);
    predictionMarkets.push(newMarket);

    predictionMarketExists[newMarket] = true;

    LogNewPredictionMarket(msg.sender, newMarket);

    return newMarket;
  }
  
  // *********** Passthrough Admin Controls ***********
  
  function pauseMarket(address _marketAddress) 
    isOwner
    marketExists(_marketAddress)
    public
    returns(bool success)
  {
      PredictionMarket marketToPause = PredictionMarket(_marketAddress);
      
      LogMarketPaused(msg.sender);
      
      return marketToPause.pauseContract();
  }
  
  function unpauseMarket(address _marketAddress)
    isOwner
    marketExists(_marketAddress)
    public
    returns(bool success)
  {
      PredictionMarket marketToPause = PredictionMarket(_marketAddress);
      
      LogMarketUnpaused(msg.sender);
      
      return marketToPause.unpauseContract();
  }
  
  function changeMarketSponsor(address _marketAddress, address newSponsor) 
    isOwner
    marketExists(_marketAddress)
    public
    returns(bool success)
  {
      PredictionMarket marketToChange = PredictionMarket(_marketAddress);
      
      LogMarketSponsorChanged(msg.sender, newSponsor);
      
      return marketToChange.changeOwner(newSponsor);
  }


}