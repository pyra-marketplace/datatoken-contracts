import { assert } from "chai";
import { BigNumber, ethers, Signer, Wallet } from "ethers";
import { describe } from "mocha";
import { DataTokenFactory, DataToken } from "../src";
import { DeployedContracts, ZERO_ADDRESS } from "../src/constants";
import { CreateDataTokenInput, DataTokenType } from "../src/types";

describe("DataToken Tests", () => {
  const rpcUrl = "http://127.0.0.1:8545";
  const network = process.env.CHAIN_ENV!;
  const privateKey = process.env.PRIVATE_KEY!;
  const contentURI = "https://dataverse-os.com";

  describe("CyberDataToken", () => {
    if (network !== "BSCT") {
      it("Network should change to BSCT", () => {});
    } else {
      const BUSD = "0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee";
      const cyberProfileId = 2193;
      let dataTokenFactory: DataTokenFactory;
      let cyberDataToken: DataToken;
      let signer: Signer;

      before(async () => {
        const provider = new ethers.providers.JsonRpcProvider(rpcUrl, 97);
        signer = new ethers.Wallet(privateKey, provider);
        dataTokenFactory = new DataTokenFactory({ env: "BSCT", signer });

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

        const { dataToken } = await dataTokenFactory.createDataToken(input);

        cyberDataToken = new DataToken({
          env: "BSCT",
          type: DataTokenType.Cyber,
          dataTokenAddress: dataToken,
          signer,
        });
      });

      it("get contentURI successfully", async () => {
        const gettedContentURI = await cyberDataToken.getContentURI();
        assert.equal(gettedContentURI, contentURI);
      });

      it("get collected status successfully", async () => {
        const isCollected = await cyberDataToken.isCollected(
          await signer.getAddress()
        );
        assert.equal(isCollected, true);
      });

      it("get collectNFT contract successfully", async () => {
        let collectNFT = await cyberDataToken.getCollectNFT();
        assert.equal(collectNFT, ZERO_ADDRESS);

        const { collectNFT: collectNFTAddress } =
          await cyberDataToken.collect();

        collectNFT = await cyberDataToken.getCollectNFT();
        assert.equal(collectNFT, collectNFTAddress);
      });

      it("get metadata successfully", async () => {
        const metadata = await cyberDataToken.getMetadata();
        assert.equal(
          metadata.originalContract.toLowerCase(),
          DeployedContracts.BSCT.Cyber.CyberProfileProxy.toLowerCase()
        );
        assert.equal(
          BigNumber.from(cyberProfileId).eq(metadata.profileId),
          true
        );
        assert.equal(
          metadata.collectModule.toLowerCase(),
          DeployedContracts.BSCT.Cyber.CollectPaidMw.toLowerCase()
        );
      });

      it("get DataToken owner successfully", async () => {
        const owner = await cyberDataToken.getDataTokenOwner();
        assert.equal(owner, await signer.getAddress());
      });

      it("collect with CollectPaidMw successfully", async () => {
        const { dataToken, collector } = await cyberDataToken.collect();
        assert.equal(dataToken, cyberDataToken.address);
        assert.equal(collector, await signer.getAddress());
        assert.equal(await cyberDataToken.isCollected(collector), true);
      });
    }
  });

  describe("LensDataToken", () => {
    if (network !== "MUMBAI") {
      it("Network should change to MUMBAI", () => {});
    } else {
      const WMATIC = "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889";
      const lensProfileId = "0x80e4";
      let dataTokenFactory: DataTokenFactory;
      let lensDataToken: DataToken;
      let signer: Signer;

      before(async () => {
        const provider = new ethers.providers.JsonRpcProvider(rpcUrl, 80001);
        signer = new ethers.Wallet(privateKey, provider);
        dataTokenFactory = new DataTokenFactory({ env: "Mumbai", signer });

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

        const { dataToken } = await dataTokenFactory.createDataToken(input);
        lensDataToken = new DataToken({
          env: "Mumbai",
          type: DataTokenType.Lens,
          dataTokenAddress: dataToken,
          signer,
        });
      });

      it("get contentURI successfully", async () => {
        const gettedContentURI = await lensDataToken.getContentURI();
        assert.equal(gettedContentURI, contentURI);
      });

      it("get collected status successfully", async () => {
        const isCollected = await lensDataToken.isCollected(
          await signer.getAddress()
        );
        assert.equal(isCollected, true);
      });

      it("get collectNFT contract successfully", async () => {
        let collectNFT = await lensDataToken.getCollectNFT();
        assert.equal(collectNFT, ZERO_ADDRESS);

        const { collectNFT: collectNFTAddress } = await lensDataToken.collect();

        collectNFT = await lensDataToken.getCollectNFT();
        assert.equal(collectNFT, collectNFTAddress);
      });

      it("get metadata successfully", async () => {
        const metadata = await lensDataToken.getMetadata();
        assert.equal(
          metadata.originalContract,
          DeployedContracts.Mumbai.Lens.LensHub
        );
        assert.equal(
          BigNumber.from(lensProfileId).eq(metadata.profileId),
          true
        );
        assert.equal(
          metadata.collectModule,
          DeployedContracts.Mumbai.Lens.FeeCollectModule
        );
      });

      it("get DataToken owner successfully", async () => {
        const owner = await lensDataToken.getDataTokenOwner();
        assert.equal(owner, await signer.getAddress());
      });

      it("collect with FeeCollectModule successfully", async () => {
        const { dataToken, collector } = await lensDataToken.collect();
        assert.equal(dataToken, lensDataToken.address);
        assert.equal(collector, await signer.getAddress());
        assert.equal(await lensDataToken.isCollected(collector), true);
      });

      it("collect with FreeCollectModule successfully", async () => {
        const input: CreateDataTokenInput = {
          type: DataTokenType.Lens,
          profileId: lensProfileId,
          contentURI,
          collectModule: DeployedContracts.Mumbai.Lens.FreeCollectModule,
          collectLimit: 100,
          followerOnly: false,
          recipient: await signer.getAddress(),
        };
        const { dataToken: dataTokenAddress } =
          await dataTokenFactory.createDataToken(input);

        const _lensDataToken = new DataToken({
          env: "Mumbai",
          type: DataTokenType.Lens,
          dataTokenAddress,
          signer,
        });

        const { dataToken, collector } = await _lensDataToken.collect();
        assert.equal(dataToken, _lensDataToken.address);
        assert.equal(collector, await signer.getAddress());
        assert.equal(await _lensDataToken.isCollected(collector), true);
      });

      it("collect with LimitedTimeFeeCollectModule successfully", async () => {
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

        const { dataToken: dataTokenAddress } =
          await dataTokenFactory.createDataToken(input);

        const _lensDataToken = new DataToken({
          env: "Mumbai",
          type: DataTokenType.Lens,
          dataTokenAddress,
          signer,
        });

        const { dataToken, collector } = await _lensDataToken.collect();
        assert.equal(dataToken, _lensDataToken.address);
        assert.equal(collector, await signer.getAddress());
        assert.equal(await _lensDataToken.isCollected(collector), true);
      });

      it("collect with LimitedFeeCollectModule successfully", async () => {
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

        const { dataToken: dataTokenAddress } =
          await dataTokenFactory.createDataToken(input);

        const _lensDataToken = new DataToken({
          env: "Mumbai",
          type: DataTokenType.Lens,
          dataTokenAddress,
          signer,
        });

        const { dataToken, collector } = await _lensDataToken.collect();
        assert.equal(dataToken, _lensDataToken.address);
        assert.equal(collector, await signer.getAddress());
        assert.equal(await _lensDataToken.isCollected(collector), true);
      });
    }
  });

  describe("ProfilelessDataToken", () => {
    if (network !== "MUMBAI") {
      it("Network should change to MUMBAI", () => {});
    } else {
      const WMATIC = "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889";
      let dataTokenFactory: DataTokenFactory;
      let profilelessDataToken: DataToken;
      let signer: Signer;

      before(async () => {
        const provider = new ethers.providers.JsonRpcProvider(rpcUrl, 80001);
        signer = new ethers.Wallet(privateKey, provider);
        dataTokenFactory = new DataTokenFactory({ env: "Mumbai", signer });

        const input: CreateDataTokenInput = {
          type: DataTokenType.Profileless,
          contentURI,
          collectModule: DeployedContracts.Mumbai.Profileless.FeeCollectModule,
          collectLimit: 100,
          amount: ethers.utils.parseEther("0.001"),
          currency: WMATIC,
          recipient: await signer.getAddress(),
        };

        const { dataToken } = await dataTokenFactory.createDataToken(input);
        profilelessDataToken = new DataToken({
          env: "Mumbai",
          type: DataTokenType.Profileless,
          dataTokenAddress: dataToken,
          signer,
        });
      });

      it("get contentURI successfully", async () => {
        const gettedContentURI = await profilelessDataToken.getContentURI();
        assert.equal(gettedContentURI, contentURI);
      });

      it("get collected status successfully", async () => {
        const isCollected = await profilelessDataToken.isCollected(
          await signer.getAddress()
        );
        assert.equal(isCollected, true);
      });

      it("get collectNFT contract successfully", async () => {
        const collectNFT = await profilelessDataToken.getCollectNFT();
        assert.equal(collectNFT, profilelessDataToken.address);
      });

      it("get metadata successfully", async () => {
        const metadata = await profilelessDataToken.getMetadata();
        assert.equal(
          metadata.originalContract,
          DeployedContracts.Mumbai.Profileless.DataTokenFactory
        );
        assert.equal(BigNumber.from(0).eq(metadata.profileId), true);
        assert.equal(
          metadata.collectModule,
          DeployedContracts.Mumbai.Profileless.FeeCollectModule
        );
      });

      it("get DataToken owner successfully", async () => {
        const owner = await profilelessDataToken.getDataTokenOwner();
        assert.equal(owner, await signer.getAddress());
      });

      it("collect with FeeCollectModule successfully", async () => {
        const { dataToken, collector } = await profilelessDataToken.collect();
        assert.equal(dataToken, profilelessDataToken.address);
        assert.equal(collector, await signer.getAddress());
        assert.equal(await profilelessDataToken.isCollected(collector), true);
      });

      it("collect with FreeCollectModule successfully", async () => {
        const input: CreateDataTokenInput = {
          type: DataTokenType.Profileless,
          contentURI,
          collectModule: DeployedContracts.Mumbai.Profileless.FreeCollectModule,
          collectLimit: 100,
        };

        const { dataToken: dataTokenAddress } =
          await dataTokenFactory.createDataToken(input);

        const _profilelessDataToken = new DataToken({
          env: "Mumbai",
          type: DataTokenType.Profileless,
          dataTokenAddress,
          signer,
        });

        const { dataToken, collector } = await _profilelessDataToken.collect();

        assert.equal(dataToken, _profilelessDataToken.address);
        assert.equal(collector, await signer.getAddress());
        assert.equal(await _profilelessDataToken.isCollected(collector), true);
      });

      it("Collect with LimitedTimedFeeCollectModule successfully", async () => {
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

        const { dataToken: dataTokenAddress } =
          await dataTokenFactory.createDataToken(input);

        const _profilelessDataToken = new DataToken({
          env: "Mumbai",
          type: DataTokenType.Profileless,
          dataTokenAddress,
          signer,
        });

        const { dataToken, collector } = await _profilelessDataToken.collect();

        assert.equal(dataToken, _profilelessDataToken.address);
        assert.equal(collector, await signer.getAddress());
        assert.equal(await _profilelessDataToken.isCollected(collector), true);
      });
    }
  });
});
