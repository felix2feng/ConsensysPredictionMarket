var PredictionMarketHub = artifacts.require("./PredictionMarketHub.sol");

module.exports = function(deployer) {
  deployer.deploy(PredictionMarketHub);
};
