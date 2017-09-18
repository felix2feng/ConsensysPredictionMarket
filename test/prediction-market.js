const ethUtil = require('ethereumjs-util');
const assert = require('chai').assert;

var PredictionMarket = artifacts.require("./PredictionMarket.sol");
var PredictionMarketHub = artifacts.require("./PredictionMarketHub.sol");

contract('PredictionMarketHub', function(accounts) {
  let owner, admin, user, source, bet, hubContract;

  beforeEach(async () => {
    owner = accounts[0];
    admin = accounts[1];
    user = accounts[2];
    source = accounts[3];
    bet = web3.toWei(10, "ether");
  });

  describe('Prediction Market Hub', () => {
    beforeEach(async () => {
      hubContract = await PredictionMarketHub.new();
    });

    it('Should return a contract with the correct owner', async () => {
      assert.exists(contract, ' The contract should exist');
      
      let contractOwner = await hubContract.owner.call();
      assert.equal(contractOwner, owner, 'The owner should match');

      let marketCount = await hubContract.getMarketCount.call();
      assert.strictEqual(parseInt(marketCount.toString(10)), 0, 'There should no markets');      
    });

    describe('Prediction Market', () => {
      let txnParamsAdmin, txnParamsOwner, txnReceipt, marketAddress, marketContract;

      beforeEach(async () => {
        txnParamsAdmin = { from: admin };
        txnParamsOwner = { from: owner };
        txnReceipt = await hubContract.createNewPredictionMarket(txnParamsAdmin);
        marketAddress = txnReceipt.logs[0].args.predictionMarketAddress;
        var abi = PredictionMarket.abi;
        return web3.eth.contract(abi).at(marketAddress, function (err, _marketContract) {
          marketContract = _marketContract;
        });
      });

      it('should allow creation of a prediction market by admin', async () => {
        let firstLog = txnReceipt.logs[0];
        assert.equal(firstLog.event, 'LogNewPredictionMarket', 'It should log the correct data');

        assert.equal(firstLog.args.sponsor, admin, 'It should have the correct sponsor');

        let marketCount = await hubContract.getMarketCount.call();
        assert.strictEqual(parseInt(marketCount.toString(10)), 1, 'There should one markets');      
      });

      it('should allow the owner to pause the contract', async () => {
        let isPaused;

        isPaused = await marketContract.paused.call();
        assert.strictEqual(isPaused, false, 'It should not be paused');

        let txnObject = await hubContract.pauseMarket(marketAddress, txnParamsOwner);
        isPaused = await marketContract.paused.call();
        assert.strictEqual(isPaused, true, 'It should be paused');
      });

      it('should allow the admin to pose a question', async () => {
        var questionHash = '0xb9c76901de78e2669152447667f9ca1c19c72755';
        let txnObject = await marketContract.poseQuestion(questionHash, source, txnParamsAdmin);
        let contractQuestionHash = await marketContract.questionHash.call();
        assert.strictEqual(questionHash, contractQuestionHash.slice(0,42), 'The question hashes should match');

        let contractTrustedSource = await marketContract.trustedSource.call();
        assert.strictEqual(source, contractTrustedSource.slice(0,42), 'The sources should match');
      });

    });
  });
});
