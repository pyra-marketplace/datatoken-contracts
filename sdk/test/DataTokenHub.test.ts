import { assert } from "chai";
import { ethers, Signer } from "ethers";
import { describe } from "mocha";
import { DataTokenHub } from "../src";
import { DeployedContracts } from "../src/constants";

describe("DataTokenHub Tests", () => {
  const rpcUrl = "http://127.0.0.1:8545";
  const network = process.env.CHAIN_ENV!;

  if (network === "MUMBAI") {
    let dataTokenHub: DataTokenHub;

    before(() => {
      const provider = new ethers.providers.JsonRpcProvider(rpcUrl, 80001);
      const signer = provider.getSigner();
      dataTokenHub = new DataTokenHub({ env: "Mumbai", signer });
    });

    it("DataTokenFactory has been whitelisted", async () => {
      const factories: string[] = [];
      factories.push(DeployedContracts.Mumbai.Lens.DataTokenFactory);
      factories.push(DeployedContracts.Mumbai.Profileless.DataTokenFactory);
      factories.map(async (factory) => {
        const isWhitelisted =
          await dataTokenHub.isDataTokenFactoryWhitelisted(factory);
        assert.equal(isWhitelisted, true);
      });
    });
  } else if (network === "BSCT") {
    let dataTokenHub: DataTokenHub;

    before(() => {
      const provider = new ethers.providers.JsonRpcProvider(rpcUrl, 97);
      const signer = provider.getSigner();
      dataTokenHub = new DataTokenHub({ env: "BSCT", signer });
    });

    it("DataTokenFactory has been whitelisted", async () => {
      const factories: string[] = [];
      factories.push(DeployedContracts.BSCT.Cyber.DataTokenFactory);
      factories.map(async (factory) => {
        const isWhitelisted =
          await dataTokenHub.isDataTokenFactoryWhitelisted(factory);
        assert.equal(isWhitelisted, true);
      });
    });
  }
});
