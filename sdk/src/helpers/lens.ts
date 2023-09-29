import { ethers, Wallet, BigNumberish } from "ethers";
import { LENS_HUB_NFT_NAME, ZERO_ADDRESS } from "../constants";
import { Sig } from "../types";
import { getSigByWallet } from "./signature";

export async function buildLensPostSig(
  profileId: BigNumberish,
  contentURI: string,
  collectModuleAddr: string,
  collectModuleInitData: string,
  referenceModuleInitData: string,
  nonce: number,
  wallet: Wallet,
  lensHubAddr: string,
  chainId: number
) {
  const ONE_DAY = 60 * 60 * 24;
  const expiredTimestamp = (Math.floor(Date.now()) + ONE_DAY).toString(); // one day

  const { v, r, s } = await getPostWithSigPartsByWallet(
    profileId,
    contentURI,
    collectModuleAddr,
    collectModuleInitData,
    ZERO_ADDRESS,
    referenceModuleInitData,
    nonce,
    expiredTimestamp,
    wallet,
    lensHubAddr,
    chainId
  );

  const sig: Sig = {
    v: v,
    s: s,
    r: r,
    deadline: expiredTimestamp,
  };
  return sig;
}

export async function buildLensCollectSig(
  profileId: BigNumberish,
  pubId: BigNumberish,
  validateData: string,
  nonce: number,
  expiredTimestamp: string,
  wallet: Wallet,
  lensHubAddr: string,
  chainId: number
) {
  const { v, r, s } = await getCollectWithSigPartsByWallet(
    profileId,
    pubId,
    validateData,
    nonce,
    expiredTimestamp,
    wallet,
    lensHubAddr,
    chainId
  );

  const sig: Sig = {
    v: v,
    s: s,
    r: r,
    deadline: expiredTimestamp,
  };
  return sig;
}

export async function getPostWithSigPartsByWallet(
  profileId: BigNumberish,
  contentURI: string,
  collectModule: string,
  collectModuleInitData: string,
  referenceModule: string,
  referenceModuleInitData: string,
  nonce: number,
  deadline: string,
  wallet: Wallet,
  lensHubAddr: string,
  chainId: number
): Promise<{ v: number; r: string; s: string }> {
  const msgParams = buildPostWithSigParams(
    profileId,
    contentURI,
    collectModule,
    collectModuleInitData,
    referenceModule,
    referenceModuleInitData,
    nonce,
    deadline,
    lensHubAddr,
    chainId
  );
  return getSigByWallet(wallet, msgParams);
}

export const buildPostWithSigParams = (
  profileId: BigNumberish,
  contentURI: string,
  collectModule: string,
  collectModuleInitData: string,
  referenceModule: string,
  referenceModuleInitData: string,
  nonce: number,
  deadline: string,
  lensHubAddr: string,
  chainId: number
) => ({
  types: {
    PostWithSig: [
      { name: "profileId", type: "uint256" },
      { name: "contentURI", type: "string" },
      { name: "collectModule", type: "address" },
      { name: "collectModuleInitData", type: "bytes" },
      { name: "referenceModule", type: "address" },
      { name: "referenceModuleInitData", type: "bytes" },
      { name: "nonce", type: "uint256" },
      { name: "deadline", type: "uint256" },
    ],
  },
  domain: lensDomain(lensHubAddr, chainId),
  value: {
    profileId: profileId,
    contentURI: contentURI,
    collectModule: collectModule,
    collectModuleInitData: collectModuleInitData,
    referenceModule: referenceModule,
    referenceModuleInitData: referenceModuleInitData,
    nonce: nonce,
    deadline: deadline,
  },
});

export function lensDomain(
  lensHubAddr: string,
  chainId: number
): {
  name: string;
  version: string;
  chainId: number;
  verifyingContract: string;
} {
  return {
    name: LENS_HUB_NFT_NAME,
    version: "1",
    chainId: chainId,
    verifyingContract: lensHubAddr,
  };
}

export async function getCollectWithSigPartsByWallet(
  profileId: BigNumberish,
  pubId: BigNumberish,
  data: string,
  nonce: number,
  deadline: string,
  wallet: Wallet,
  lensHubAddr: string,
  chainId: number
): Promise<Sig> {
  const msgParams = buildCollectWithSigParams(
    profileId,
    pubId,
    data,
    nonce,
    deadline,
    lensHubAddr,
    chainId
  );
  return (await getSigByWallet(wallet, msgParams)) as Sig;
}

export function buildCollectWithSigParams(
  profileId: BigNumberish,
  pubId: BigNumberish,
  data: string,
  nonce: number,
  deadline: string | number,
  lensHubAddr: string,
  chainId: number
) {
  return {
    types: {
      CollectWithSig: [
        { name: "profileId", type: "uint256" },
        { name: "pubId", type: "uint256" },
        { name: "data", type: "bytes" },
        { name: "nonce", type: "uint256" },
        { name: "deadline", type: "uint256" },
      ],
    },
    domain: lensDomain(lensHubAddr, chainId),
    value: {
      profileId: profileId,
      pubId: pubId,
      data: data,
      nonce: nonce,
      deadline: deadline,
    },
  };
}
