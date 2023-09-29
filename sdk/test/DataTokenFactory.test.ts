import { assert } from "chai";
import { ethers, Signer, Wallet } from "ethers";
import { describe } from "mocha";
import { DataTokenFactory } from "../src";
import { DeployedContracts, ZERO_ADDRESS } from "../src/constants";
import { CreateDataTokenInput, DataTokenType } from "../src/types";

describe("DataTokenFactory Tests", () => {
  const rpcUrl = "http://127.0.0.1:8545";
  const network = process.env.CHAIN_ENV!;
  const privateKey = process.env.PRIVATE_KEY!;
  const contentURI = "https://dataverse-os.com";

  describe("CyberDataTokenFactory", () => {
    if (network !== "BSCT") {
      it("Network should change to BSCT", () => {});
    } else {
      const BUSD = "0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee";
      const cyberProfileId = 2193;
      let dataTokenFactory: DataTokenFactory;
      let signer: Signer;

      before(() => {
        const provider = new ethers.providers.JsonRpcProvider(rpcUrl, 97);
        signer = new ethers.Wallet(privateKey, provider);
        dataTokenFactory = new DataTokenFactory({ env: "BSCT", signer });
      });

      it("create with CollectPaidMw successfully", async () => {
        const input = {
          type: DataTokenType.Cyber,
          profileId: cyberProfileId,
          name: "EssByCollectPay",
          symbol: "DEMO",
          contentURI,
          essenceMw: DeployedContracts.BSCT.Cyber.CollectPaidMw,
          transferable: true,
          deployAtRegister: false,
          totalSupply: 10,
          amount: ethers.utils.parseEther("0.001"),
          recipient: await signer.getAddress(),
          currency: BUSD,
          subscribeRequired: false,
          deadline: (Math.floor(Date.now() / 1000) + 60 * 60 * 24).toString(),
        };

        const { creator, originalContract, dataToken } =
          await dataTokenFactory.createDataToken(input);
        assert.equal(creator, await signer.getAddress());
        assert.equal(
          originalContract,
          DeployedContracts.BSCT.Cyber.CyberProfileProxy
        );
        assert.notEqual(dataToken, ZERO_ADDRESS);
      });
    }
  });

  describe("LensDataTokenFactory", () => {
    if (network !== "MUMBAI") {
      it("Network should change to MUMBAI", () => {});
    } else {
      const WMATIC = "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889";
      const lensProfileId = "0x80e4";
      let dataTokenFactory: DataTokenFactory;
      let signer: Signer;

      before(() => {
        const provider = new ethers.providers.JsonRpcProvider(rpcUrl, 80001);
        signer = new ethers.Wallet(privateKey, provider);
        dataTokenFactory = new DataTokenFactory({ env: "Mumbai", signer });
      });

      it("create with FeeCollectModule successfully", async () => {
        const input: CreateDataTokenInput = {
          type: DataTokenType.Lens,
          profileId: lensProfileId,
          contentURI,
          collectModule: DeployedContracts.Mumbai.Lens.FeeCollectModule,
          collectLimit: 100,
          followerOnly: false,
          recipient: await signer.getAddress(),
          referralFee: 0,
          currency: WMATIC,
          amount: ethers.utils.parseEther("0.001"),
        };

        const { creator, originalContract, dataToken } =
          await dataTokenFactory.createDataToken(input);
        assert.equal(creator, await signer.getAddress());
        assert.equal(originalContract, DeployedContracts.Mumbai.Lens.LensHub);
        assert.notEqual(dataToken, ZERO_ADDRESS);
      });

      it("create with FreeCollectModule successfully", async () => {
        const input: CreateDataTokenInput = {
          type: DataTokenType.Lens,
          profileId: lensProfileId,
          contentURI,
          collectModule: DeployedContracts.Mumbai.Lens.FreeCollectModule,
          collectLimit: 100,
          followerOnly: false,
          recipient: await signer.getAddress(),
        };

        const { creator, originalContract, dataToken } =
          await dataTokenFactory.createDataToken(input);
        assert.equal(creator, await signer.getAddress());
        assert.equal(originalContract, DeployedContracts.Mumbai.Lens.LensHub);
        assert.notEqual(dataToken, ZERO_ADDRESS);
      });

      it("create with limitedTimeFeeCollectModule successfully", async () => {
        const input: CreateDataTokenInput = {
          type: DataTokenType.Lens,
          profileId: lensProfileId,
          contentURI,
          collectModule:
            DeployedContracts.Mumbai.Lens.LimitedTimedFeeCollectModule,
          collectLimit: 100,
          followerOnly: false,
          recipient: await signer.getAddress(),
          referralFee: 0,
          currency: WMATIC,
          amount: ethers.utils.parseEther("0.001"),
        };

        const { creator, originalContract, dataToken } =
          await dataTokenFactory.createDataToken(input);
        assert.equal(creator, await signer.getAddress());
        assert.equal(originalContract, DeployedContracts.Mumbai.Lens.LensHub);
        assert.notEqual(dataToken, ZERO_ADDRESS);
      });

      it("create with limitedFeeCollectModule successfully", async () => {
        const input: CreateDataTokenInput = {
          type: DataTokenType.Lens,
          profileId: lensProfileId,
          contentURI,
          collectModule: DeployedContracts.Mumbai.Lens.LimitedFeeCollectModule,
          collectLimit: 100,
          followerOnly: false,
          recipient: await signer.getAddress(),
          referralFee: 0,
          currency: WMATIC,
          amount: ethers.utils.parseEther("0.001"),
        };

        const { creator, originalContract, dataToken } =
          await dataTokenFactory.createDataToken(input);
        assert.equal(creator, await signer.getAddress());
        assert.equal(originalContract, DeployedContracts.Mumbai.Lens.LensHub);
        assert.notEqual(dataToken, ZERO_ADDRESS);
      });
    }
  });

  describe("ProfilelessDataTokenFactory", () => {
    if (network !== "MUMBAI") {
      it("Network should change to MUMBAI", () => {});
    } else {
      const WMATIC = "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889";
      let dataTokenFactory: DataTokenFactory;
      let signer: Signer;

      before(() => {
        const provider = new ethers.providers.JsonRpcProvider(rpcUrl, 80001);
        signer = new ethers.Wallet(privateKey, provider);
        dataTokenFactory = new DataTokenFactory({ env: "Mumbai", signer });
      });

      it("create with FeeCollectModule successfully", async () => {
        const input: CreateDataTokenInput = {
          type: DataTokenType.Profileless,
          contentURI,
          collectModule: DeployedContracts.Mumbai.Profileless.FeeCollectModule,
          collectLimit: 100,
          amount: ethers.utils.parseEther("0.001"),
          currency: WMATIC,
          recipient: await signer.getAddress(),
        };

        const { creator, originalContract, dataToken } =
          await dataTokenFactory.createDataToken(input);
        assert.equal(creator, await signer.getAddress());
        assert.equal(
          originalContract,
          DeployedContracts.Mumbai.Profileless.DataTokenFactory
        );
        assert.notEqual(dataToken, ZERO_ADDRESS);
      });

      it("create with FreeCollectModule successfully", async () => {
        const input: CreateDataTokenInput = {
          type: DataTokenType.Profileless,
          contentURI,
          collectModule: DeployedContracts.Mumbai.Profileless.FreeCollectModule,
          collectLimit: 100,
        };

        const { creator, originalContract, dataToken } =
          await dataTokenFactory.createDataToken(input);
        assert.equal(creator, await signer.getAddress());
        assert.equal(
          originalContract,
          DeployedContracts.Mumbai.Profileless.DataTokenFactory
        );
        assert.notEqual(dataToken, ZERO_ADDRESS);
      });

      it("create with LimitedTimedFeeCollectModule successfully", async () => {
        const input: CreateDataTokenInput = {
          type: DataTokenType.Profileless,
          contentURI,
          collectModule:
            DeployedContracts.Mumbai.Profileless.LimitedTimedFeeCollectModule,
          collectLimit: 100,
          amount: ethers.utils.parseEther("0.001"),
          currency: WMATIC,
          recipient: await signer.getAddress(),
          endTimestamp: Math.floor(Date.now() / 1000) + 60 * 60 * 24,
        };

        const { creator, originalContract, dataToken } =
          await dataTokenFactory.createDataToken(input);
        assert.equal(creator, await signer.getAddress());
        assert.equal(
          originalContract,
          DeployedContracts.Mumbai.Profileless.DataTokenFactory
        );
        assert.notEqual(dataToken, ZERO_ADDRESS);
      });
    }
  });
});
