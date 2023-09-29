import { BigNumberish, Signer, Wallet } from "ethers";
import {
  CollectDataTokenOutput,
  CollectWithSigData,
  CyberCollectParamsStruct,
  DataTokenType,
  Chain,
  Sig,
} from "./types";
import {
  IDataToken,
  IDataToken__factory,
  IERC20__factory,
  LensFeeCollectModule__factory,
  LensHub__factory,
  LensLimitedFeeCollectModule__factory,
  LensLimitedTimedFeeCollectModule__factory,
  ProfilelessFeeCollectModule__factory,
  ProfileNFT__factory,
} from "./contracts";

import { DataTypes } from "./contracts/IDataToken";

import {
  abiCoder,
  buildLensCollectSig,
  generateCollectWithSig,
  getMwData,
} from "./helpers";
import { parseEther } from "ethers/lib/utils";
import {
  CYBER_PROFILE_CONTRACT_NAME,
  DeployedContracts,
  EMPTY_BYTES,
} from "./constants";

export class DataToken {
  env: Chain;
  type: DataTokenType;
  signer: Signer;
  instance: IDataToken;
  address: string;

  constructor({
    env,
    type,
    dataTokenAddress,
    signer,
  }: {
    env: Chain;
    type: DataTokenType;
    dataTokenAddress: string;
    signer: Signer;
  }) {
    this.env = env;
    this.type = type;
    this.signer = signer;
    this.address = dataTokenAddress;
    this.instance = IDataToken__factory.connect(dataTokenAddress, signer);
  }

  public async collect(): Promise<CollectDataTokenOutput> {
    const collector = await this.signer.getAddress();
    const meta = await this.getMetadata();
    let collectData = await this._generateCollectData(meta, collector);

    let output = {} as CollectDataTokenOutput;
    await this.instance.collect(collectData).then(async (tx: any) => {
      const r = await tx.wait();
      r.events.forEach((e: any) => {
        if (e.event === "Collected") {
          output.dataToken = e.args.dataToken;
          output.collector = e.args.collector;
          output.collectNFT = e.args.collectNFT;
          output.tokenId = e.args.tokenId.toString();
        }
      });
    });
    return output;
  }

  public async getContentURI() {
    return await this.instance.getContentURI();
  }

  public async getCollectNFT() {
    return await this.instance.getCollectNFT();
  }

  public async isCollected(account: string): Promise<boolean> {
    return await this.instance.isCollected(account);
  }

  public async getMetadata(): Promise<DataTypes.MetadataStructOutput> {
    return await this.instance.getMetadata();
  }

  public async getDataTokenOwner(): Promise<string> {
    return await this.instance.getDataTokenOwner();
  }

  private async _generateCollectData(
    meta: DataTypes.MetadataStructOutput,
    collector: string
  ) {
    let collectData: string;

    switch (this.type) {
      case DataTokenType.Profileless:
        collectData = await this._generateProfilelessCollectData(
          meta,
          collector
        );
        break;

      case DataTokenType.Lens:
        collectData = await this._generateLensCollectData(meta, collector);
        break;

      case DataTokenType.Cyber:
        collectData = await this._generateCyberCollectData(meta, collector);
        break;

      default:
        throw new Error("NotImplemented");
    }
    return collectData;
  }

  private async _getProfilelessCollectModuleInfo(
    moduleAddr: string,
    pubId: BigNumberish
  ) {
    const collectModuleInst = ProfilelessFeeCollectModule__factory.connect(
      moduleAddr,
      this.signer
    );
    return await collectModuleInst.getPublicationData(pubId);
  }

  private async _buildValidateData(
    meta: DataTypes.MetadataStructOutput,
    collector: string
  ) {
    // 1. query moduleInfo
    const moduleInfo = await this._getProfilelessCollectModuleInfo(
      meta.collectModule,
      meta.pubId
    );

    // 2. check balance of payment token
    const currencyInst = IERC20__factory.connect(
      moduleInfo.currency,
      this.signer
    );
    const userBalance = await currencyInst.balanceOf(collector);
    if (userBalance.lt(moduleInfo.amount)) {
      throw new Error("Insufficient Balance");
    }
    await currencyInst.approve(meta.collectModule, moduleInfo.amount);

    // 3. build validateData
    return abiCoder.encode(
      ["address", "uint256"],
      [moduleInfo.currency, moduleInfo.amount]
    );
  }

  private async _generateProfilelessCollectData(
    meta: DataTypes.MetadataStructOutput,
    collector: string
  ) {
    let validateData;
    let collectData;
    if (this.env !== "Mumbai") {
      throw new Error("Network Env unavailable in ProfilelessDataToken");
    }
    switch (meta.collectModule) {
      case DeployedContracts[this.env].Profileless.FeeCollectModule:
        validateData = await this._buildValidateData(meta, collector);
        collectData = abiCoder.encode(
          ["address", "bytes"],
          [collector, validateData]
        );
        break;

      case DeployedContracts[this.env].Profileless.LimitedTimedFeeCollectModule:
        validateData = await this._buildValidateData(meta, collector);
        collectData = abiCoder.encode(
          ["address", "bytes"],
          [collector, validateData]
        );
        break;

      case DeployedContracts[this.env].Profileless.FreeCollectModule:
        collectData = abiCoder.encode(
          ["address", "bytes"],
          [collector, "0x00"]
        );
        break;
      default:
        throw new Error("Invalid Collect Module");
    }
    return collectData;
  }

  private async _generateLensCollectData(
    meta: DataTypes.MetadataStructOutput,
    collector: string
  ) {
    let validateData;
    let collectData = "0x00";
    let info: any;
    if (this.env !== "Mumbai") {
      throw new Error("Network Env unavailable in ProfilelessDataToken");
    }
    switch (meta.collectModule) {
      case DeployedContracts[this.env].Lens.FeeCollectModule:
        info = await LensFeeCollectModule__factory.connect(
          meta.collectModule,
          this.signer
        ).getPublicationData(meta.profileId, meta.pubId);
        validateData = await this._generateLensValidateData(meta, info);
        break;

      case DeployedContracts[this.env].Lens.LimitedTimedFeeCollectModule:
        info = await LensLimitedTimedFeeCollectModule__factory.connect(
          meta.collectModule,
          this.signer
        ).getPublicationData(meta.profileId, meta.pubId);
        validateData = await this._generateLensValidateData(meta, info);
        break;

      case DeployedContracts[this.env].Lens.LimitedFeeCollectModule:
        info = await LensLimitedFeeCollectModule__factory.connect(
          meta.collectModule,
          this.signer
        ).getPublicationData(meta.profileId, meta.pubId);

        validateData = await this._generateLensValidateData(meta, info);
        break;

      case DeployedContracts[this.env].Lens.FreeCollectModule:
        validateData = "0x00";
        break;

      default:
        throw new Error("CollectModule not supported");
    }

    const network = await this.signer.provider?.getNetwork();
    if (!network) {
      throw new Error("Can not get network from provider");
    }

    const lensHub = LensHub__factory.connect(
      DeployedContracts[this.env].Lens.LensHub,
      this.signer
    );

    const nonce = (
      await lensHub.sigNonces(await this.signer.getAddress())
    ).toNumber();

    const expiredTimestamp = Math.floor(Date.now() / 1000) + 60 * 60 * 24;

    const sig = (await buildLensCollectSig(
      meta.profileId,
      meta.pubId,
      validateData,
      nonce,
      expiredTimestamp.toString(),
      this.signer as Wallet,
      lensHub.address,
      Number(network.chainId)
    )) as Sig;

    const collectWithSigData = {
      collector: collector,
      profileId: meta.profileId.toHexString(),
      pubId: meta.pubId.toHexString(),
      data: validateData,
      sig: sig,
    } as CollectWithSigData;

    collectData = abiCoder.encode(
      [
        "tuple(address collector,uint256 profileId,uint256 pubId,bytes data,tuple(uint8 v,bytes32 r,bytes32 s,uint256 deadline) sig) data",
      ],
      [collectWithSigData]
    );

    return collectData;
  }

  private async _generateLensValidateData(
    meta: DataTypes.MetadataStructOutput,
    moduleInfo: any
  ) {
    await this._checkAndApprovePaymentToken(
      moduleInfo.currency,
      moduleInfo.amount,
      meta.collectModule
    );

    return abiCoder.encode(
      ["address", "uint256"],
      [moduleInfo.currency, moduleInfo.amount]
    );
  }

  private async _generateCyberCollectData(
    meta: DataTypes.MetadataStructOutput,
    collector: string
  ) {
    if (this.env !== "BSCT") {
      throw new Error("Network Env unavailable in CyberDataToken");
    }
    const collectVars = {
      collector: collector,
      profileId: meta.profileId,
      essenceId: meta.pubId,
    } as CyberCollectParamsStruct;

    const cyberProfile = ProfileNFT__factory.connect(
      DeployedContracts[this.env].Cyber.CyberProfileProxy,
      this.signer
    );

    const mwAddr = await cyberProfile.getEssenceMw(
      meta.profileId as BigNumberish,
      meta.pubId as BigNumberish
    );
    const expiredTimestamp = Math.floor(Date.now() / 1000) + 60 * 60 * 24;

    switch (mwAddr.toLowerCase()) {
      case DeployedContracts[this.env].Cyber.CollectPaidMw.toLowerCase():
        const { currency, amount } = await getMwData({
          signer: this.signer,
          collectPaidMwAddress: mwAddr,
          profileId: meta.profileId,
          essenceId: meta.pubId,
        });

        await this._checkAndApprovePaymentToken(currency, amount, mwAddr);
        break;

      default:
        throw new Error("CollectModule not supported");
    }

    const cPreData = EMPTY_BYTES;
    const cPostData = EMPTY_BYTES;
    const cNonce = await cyberProfile.nonces(collector);

    const cltEssSig = await generateCollectWithSig(
      this.signer as Wallet,
      collectVars,
      cPreData,
      cPostData,
      cNonce,
      expiredTimestamp.toString(),
      cyberProfile.address,
      CYBER_PROFILE_CONTRACT_NAME
    );

    const cltEssSig712: Sig = {
      v: cltEssSig.v,
      r: cltEssSig.r,
      s: cltEssSig.s,
      deadline: expiredTimestamp.toString(),
    };

    return abiCoder.encode(
      [
        "tuple(address collector,uint256 profileId,uint256 essenceId) params",
        "bytes preData",
        "bytes postData",
        "address sender",
        "tuple(uint8 v,bytes32 r,bytes32 s,uint256 deadline) sig",
      ],
      [collectVars, cPreData, cPostData, collector, cltEssSig712]
    );
  }

  private async _checkAndApprovePaymentToken(
    currency: string,
    amount: BigNumberish,
    recipient: string
  ) {
    const erc20 = IERC20__factory.connect(currency, this.signer);
    const signerAddr = await this.signer.getAddress();
    const userBalance = await erc20.balanceOf(signerAddr);
    if (userBalance.lt(amount)) {
      throw new Error("NotEnoughERC20");
    }

    await erc20.approve(recipient, amount);
  }
}
