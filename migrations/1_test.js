const NFTRouter = artifacts.require("NFTRouter");
const Guardian = artifacts.require("Guardian");
const AnyGuardianSocket = artifacts.require("AnyGuardianSocket");

module.exports = function (deployer) {
  // 1. deploy router
  deployer.deploy(NFTRouter, "0xE9058a6685fB99b1dDA6a8aab2865b59f7095C3d", 100000000000000);

  // 2. deploy guardian
  deployer.deploy(Guardian);

  // 3. deploy guardian socket
  deployer.deploy(AnyGuardianSocket);
};
