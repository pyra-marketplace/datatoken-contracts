import { BigNumberish, Signer } from "ethers";

type Chain = "Polygon" | "Mumbai" | "BSC" | "BSCT";

enum DataTokenType {
  Lens = "Lens",
  Profileless = "Profileless",
  Cyber = "Cyber",
}

type CreateDataTokenInput = {
  type: DataTokenType;
  contentURI: string;
  collectModule?: string;
  collectLimit?: BigNumberish;
  amount?: BigNumberish;
  currency?: string;
  recipient?: string;
  endTimestamp?: BigNumberish;
} & LensDataTokenInput &
  CyberDataTokenInput;

type LensDataTokenInput = {
  profileId?: BigNumberish;
  followerOnly?: boolean;
  referralFee?: BigNumberish;
  deadline?: string;
};

type CyberDataTokenInput = {
  profileId?: BigNumberish;
  essenceMw?: string;
  totalSupply?: BigNumberish;
  subscribeRequired?: boolean;
  signerAddr?: string;
  root?: string;
  name?: string;
  symbol?: string;
  // essenceTokenURI?: string;
  transferable?: boolean;
  deployAtRegister?: boolean;
};

type CreateDataTokenOutput =  {
  creator: string;
  originalContract: string;
  dataToken: string;
}

type CollectDataTokenOutput = {
  dataToken: string;
  collector: string;
  collectNFT: string;
  tokenId: BigNumberish;
};

type CyberCollectParamsStruct = {
  collector: string;
  profileId: BigNumberish;
  essenceId: BigNumberish;
};

type Metadata = {
  originalContract: string;
  profileId: string;
  pubId: string;
  collectModule: string;
};

type Sig = {
  r: string;
  s: string;
  v: number;
  deadline: string;
};

// Lens
type CollectWithSigData = {
  collector: string;
  profileId: BigNumberish;
  pubId: BigNumberish;
  data: string;
  sig: Sig;
};

type PostWithSigData = {
  profileId: BigNumberish;
  contentURI: string;
  collectModule: string;
  collectModuleInitData: string;
  referenceModule: string;
  referenceModuleInitData: string;
  sig: Sig;
};

type ProfilelessPostData = {
  contentURI: string;
  collectModule: string;
  collectModuleInitData: string;
};

type CollectModuleParam = {};

export {
  Chain,
  DataTokenType,
  // CollectModuleType,
  ProfilelessPostData,
  CreateDataTokenOutput,
  // Metadata,
  Sig,
  PostWithSigData,
  CollectWithSigData,
  CreateDataTokenInput,
  CollectDataTokenOutput,
  CyberCollectParamsStruct,
  // CollectDataTokenInput,
};
