import { BigNumberish, BytesLike, Signer, Wallet } from "ethers";
import {
  CreateDataTokenInput,
  CreateDataTokenOutput,
  DataTokenType,
  Chain,
  PostWithSigData,
  ProfilelessPostData,
  Sig,
} from "./types";
import {
  LensHub__factory,
  ProfileNFT__factory,
  IDataTokenFactory,
  IDataTokenFactory__factory,
} from "./contracts";

import { CYBER_PROFILE_CONTRACT_NAME, EMPTY_BYTES, ZERO_ADDRESS } from "./constants";
import { abiCoder } from "./helpers";
import { generateRegisterEssenceWithSig, buildLensPostSig } from "./helpers";

import { DeployedContracts } from "./constants";

export class DataTokenFactory {
  env: Chain;
  signer: Signer;
  instance: IDataTokenFactory;

  constructor({
    env,
    signer,
  }: {
    env: Chain;
    signer: Signer;
  }) {
    this.env = env;
    this.signer = signer;
    this.instance = IDataTokenFactory__factory.connect(ZERO_ADDRESS, signer);
  }

  public async createDataToken(
    input: CreateDataTokenInput
  ): Promise<CreateDataTokenOutput> {
    const initData = await this._buildInitData(input);

    if (input.type === DataTokenType.Cyber) {
      if (this.env !== "BSCT") {
        throw new Error("Network Env not supported");
      }
      this.instance = this.instance.attach(
        DeployedContracts[this.env][input.type].DataTokenFactory
      );
    } else {
      if (this.env !== "Mumbai") {
        throw new Error("Network Env not supported");
      }
      this.instance = this.instance.attach(
        DeployedContracts[this.env][input.type].DataTokenFactory
      );
    }

    const output = {} as CreateDataTokenOutput;
    await this.instance.createDataToken(initData).then(async (tx: any) => {
      const r = await tx.wait();
      r.events.forEach((e: any) => {
        if (e.event === "DataTokenCreated") {
          output.creator = e.args[0];
          output.originalContract = e.args[1];
          output.dataToken = e.args[2];
        }
      });
    });
    return output;
  }

  private async _buildInitData(input: CreateDataTokenInput): Promise<string> {
    let collectModuleInitData: string;
    let nonce: BigNumberish;
    switch (input.type) {
      case DataTokenType.Profileless:
        collectModuleInitData = this._buildProfilelessModuleInitData(input);
        const data = {
          contentURI: input.contentURI,
          collectModule: input.collectModule,
          collectModuleInitData: collectModuleInitData,
        } as ProfilelessPostData;

        return abiCoder.encode(
          [
            "tuple(string contentURI, address collectModule,bytes collectModuleInitData) data",
          ],
          [data]
        );

      case DataTokenType.Lens:
        collectModuleInitData = this._buildLensModuleInitData(input);

        if (this.env !== "Mumbai") {
          throw new Error("Network Env not supported");
        }

        const lensHub = LensHub__factory.connect(
          DeployedContracts[this.env].Lens.LensHub,
          this.signer
        );

        nonce = (
          await lensHub.sigNonces(await this.signer.getAddress())
        ).toNumber();

        const sig = await buildLensPostSig(
          input.profileId!,
          input.contentURI,
          input.collectModule!,
          collectModuleInitData,
          EMPTY_BYTES,
          nonce,
          this.signer as Wallet,
          lensHub.address,
          await this.signer.getChainId()
        );

        const postWithSigData = {
          profileId: input.profileId!,
          contentURI: input.contentURI,
          collectModule: input.collectModule,
          collectModuleInitData: collectModuleInitData,
          referenceModule: ZERO_ADDRESS,
          referenceModuleInitData: "0x00",
          sig,
        } as PostWithSigData;

        return abiCoder.encode(
          [
            "tuple(uint256 profileId,string contentURI,address collectModule,bytes collectModuleInitData,address referenceModule,bytes referenceModuleInitData, tuple(uint8 v,bytes32 r,bytes32 s,uint256 deadline) sig) postWithSigData",
          ],
          [postWithSigData]
        );

      case DataTokenType.Cyber:
        if (this.env !== "BSCT") {
          throw new Error("Network Env not supported");
        }

        collectModuleInitData = await this._buildCyberModuleInitData(input);
        const walletAddr = await this.signer.getAddress();

        const cyberProfile = ProfileNFT__factory.connect(
          DeployedContracts[this.env].Cyber.CyberProfileProxy,
          this.signer
        );

        nonce = await cyberProfile.nonces(walletAddr);
        const regEssSig = await generateRegisterEssenceWithSig(
          this.signer as Wallet,
          input,
          collectModuleInitData,
          nonce,
          input.deadline as string,
          cyberProfile.address,
          CYBER_PROFILE_CONTRACT_NAME
        );

        const regEssSig712: Sig = {
          v: regEssSig.v,
          r: regEssSig.r,
          s: regEssSig.s,
          deadline: input.deadline as string,
        };

        const dataInput = {
          profileId: input.profileId,
          name: input.name,
          symbol: input.symbol,
          essenceTokenURI: input.contentURI,
          essenceMw: input.essenceMw,
          transferable: input.transferable,
          deployAtRegister: input.deployAtRegister,
        };
        return abiCoder.encode(
          [
            "tuple(uint256 profileId,string name,string symbol,string essenceTokenURI,address essenceMw,bool transferable,bool deployAtRegister) input",
            "bytes",
            "tuple(uint8 v,bytes32 r,bytes32 s,uint256 deadline) sig",
          ],
          [dataInput, collectModuleInitData, regEssSig712]
        );

      default:
        throw new Error("DataTokenType Not Supported");
    }
  }

  private _buildProfilelessModuleInitData(input: CreateDataTokenInput) {
    if (this.env !== "Mumbai" || input.type !== DataTokenType.Profileless) {
      throw new Error("Chain Or DataTokenType Not Supported");
    }
    let collectModuleInitData: string;
    switch (input.collectModule) {
      case DeployedContracts[this.env][input.type].FeeCollectModule:
        collectModuleInitData = abiCoder.encode(
          ["uint256", "uint256", "address", "address"],
          [input.collectLimit, input.amount!, input.currency!, input.recipient!]
        );
        break;

      case DeployedContracts[this.env][input.type].FreeCollectModule:
        collectModuleInitData = abiCoder.encode(
          ["uint256"],
          [input.collectLimit]
        );
        break;

      case DeployedContracts[this.env][input.type].LimitedTimedFeeCollectModule:
        collectModuleInitData = abiCoder.encode(
          ["uint256", "uint256", "address", "address", "uint40"],
          [
            input.collectLimit,
            input.amount,
            input.currency,
            input.recipient,
            input.endTimestamp!,
          ]
        );
        break;

      default:
        throw new Error("CollectModule Not Supported");
    }
    return collectModuleInitData;
  }

  private _buildLensModuleInitData(input: CreateDataTokenInput): string {
    if (this.env !== "Mumbai" || input.type !== DataTokenType.Lens) {
      throw new Error("Chain Or DataTokenType Not Supported");
    }
    let collectModuleInitData: string;
    switch (input.collectModule) {
      case DeployedContracts[this.env][input.type].FreeCollectModule:
        collectModuleInitData = abiCoder.encode(
          ["bool"],
          [input.followerOnly!]
        );
        break;

      case DeployedContracts[this.env][input.type].FeeCollectModule:
        collectModuleInitData = abiCoder.encode(
          ["uint256", "address", "address", "uint16", "bool"],
          [
            input.amount,
            input.currency,
            input.recipient,
            input.referralFee,
            input.followerOnly!,
          ]
        );
        break;

      case DeployedContracts[this.env][input.type].LimitedTimedFeeCollectModule:
        collectModuleInitData = abiCoder.encode(
          ["uint256", "uint256", "address", "address", "uint16", "bool"],
          [
            input.collectLimit,
            input.amount,
            input.currency,
            input.recipient,
            input.referralFee,
            input.followerOnly,
          ]
        );
        break;

      case DeployedContracts[this.env][input.type].LimitedFeeCollectModule:
        collectModuleInitData = abiCoder.encode(
          ["uint256", "uint256", "address", "address", "uint16", "bool"],
          [
            input.collectLimit,
            input.amount,
            input.currency,
            input.recipient,
            input.referralFee,
            input.followerOnly,
          ]
        );
        break;

      default:
        throw new Error("NotSupported");
    }

    return collectModuleInitData;
  }

  private async _buildCyberModuleInitData(
    input: CreateDataTokenInput
  ): Promise<string> {
    if (this.env !== "BSCT" || input.type !== DataTokenType.Cyber) {
      throw new Error("Chain Or DataTokenType Not Supported");
    }
    let initData = EMPTY_BYTES;

    switch (input.essenceMw) {
      case DeployedContracts[this.env][input.type].CollectPaidMw:
        initData = abiCoder.encode(
          ["uint256", "uint256", "address", "address", "bool"],
          [
            input.totalSupply,
            input.amount,
            input.recipient,
            input.currency,
            input.subscribeRequired,
          ]
        );
        break;

      case ZERO_ADDRESS:
        initData = EMPTY_BYTES;
        break;

      default:
        throw new Error("Middleware Not Supported");
    }
    return initData;
  }
}
