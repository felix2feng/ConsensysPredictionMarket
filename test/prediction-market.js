const expectThrow = require('./expectThrow');
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
    // Prefer to use smaller figures during tests
    bet = web3.toWei(1, "ether");
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
      assert.strictEqual(marketCount.toString(10), "0", 'There should no markets');      
    });

    describe('Prediction Market', () => {
      let txnParamsAdmin, txnParamsOwner, txnReceipt, marketAddress, marketContract, txnParamsUser;

      beforeEach(async () => {
        txnParamsAdmin = { from: admin };
        txnParamsOwner = { from: owner };
        txnParamsUser = { from: user };
        txnReceipt = await hubContract.createNewPredictionMarket(txnParamsAdmin);
        marketAddress = txnReceipt.logs[0].args.predictionMarketAddress;
        marketContract = PredictionMarket.at(marketAddress);
      });

      it('should allow creation of a prediction market by admin', async () => {
        let firstLog = txnReceipt.logs[0];
        assert.equal(firstLog.event, 'LogNewPredictionMarket', 'It should log the correct data');

        assert.equal(firstLog.args.sponsor, admin, 'It should have the correct sponsor');

        let marketCount = await hubContract.getMarketCount.call();
        assert.strictEqual(marketCount.toString(10), "1", 'There should one markets');      
      });

      it('should allow the owner to pause the contract', async () => {
        let isPaused;

        isPaused = await marketContract.paused.call();
        assert.strictEqual(isPaused, false, 'It should not be paused');

        let txnObject = await hubContract.pauseMarket(marketAddress, txnParamsOwner);
        isPaused = await marketContract.paused.call();
        assert.strictEqual(isPaused, true, 'It should be paused');
      });

      it('should not allow the admin to pause the contract', async () => {
        let isPaused;

        isPaused = await marketContract.paused.call();
        assert.strictEqual(isPaused, false, 'It should not be paused');

        try {
          await expectThrow(hubContract.pauseMarket(marketAddress, txnParamsAdmin));
          assert.fail('should have thrown before');
        } catch(error) {
          assert.isAbove(error.message.search('invalid opcode'), -1, 'Invalid opcode error must be returned');
        }
      });

      it('should allow the admin to pose a question', async () => {
        var questionHash = '0xb9c76901de78e2669152447667f9ca1c19c72755';
        let txnObject = await marketContract.poseQuestion(questionHash, source, txnParamsAdmin);
        let contractQuestionHash = await marketContract.questionHash.call();
        assert.strictEqual(questionHash, contractQuestionHash.slice(0,42), 'The question hashes should match');

        let contractTrustedSource = await marketContract.trustedSource.call();
        assert.strictEqual(source, contractTrustedSource.slice(0,42), 'The sources should match');
      });

      it('should not allow a user to pose a question', async () => {
        var questionHash = '0xb9c76901de78e2669152447667f9ca1c19c72755';
        try {
          await marketContract.poseQuestion(questionHash, source, txnParamsUser);
          assert.fail('should have thrown before');
        } catch(error) {
          assert.isAbove(error.message.search('invalid opcode'), -1, 'Invalid opcode error must be returned');
        }
      });
    });
  });
});
