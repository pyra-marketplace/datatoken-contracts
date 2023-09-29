import { ethers, Wallet, Signature, BigNumberish, utils, Signer } from "ethers";
import { getSigByWallet } from "./signature";
import { CollectPaidMw, CollectPaidMw__factory } from "../contracts";
import { CollectPaidMwSetEvent } from "../contracts/Cyber/CollectPaidMw";

export async function generateRegisterEssenceWithSig(
  signer: Wallet,
  vars: any,
  initData: string,
  nonce: BigNumberish,
  deadline: string,
  verifyingContract: string,
  contractName: string
): Promise<{ v: number; r: string; s: string }> {
  const params = buildRegisterEssenceSigParams(
    vars.profileId,
    vars.name,
    vars.symbol,
    vars.contentURI,
    vars.essenceMw,
    vars.transferable,
    vars.deployAtRegister,
    initData,
    nonce,
    deadline,
    verifyingContract,
    contractName,
    await signer.getChainId()
  );

  return await getSigByWallet(signer, params);
}

export const buildRegisterEssenceSigParams = (
  profileId: BigNumberish,
  name: string,
  symbol: string,
  essenceTokenURI: string,
  essenceMw: string,
  transferable: boolean,
  deployAtRegister: boolean,
  initData: string,
  nonce: BigNumberish,
  deadline: string,
  verifyingContract: string,
  contractName: string,
  chainId: number
) => ({
  types: {
    registerEssenceWithSig: [
      { name: "profileId", type: "uint256" },
      { name: "name", type: "string" },
      { name: "symbol", type: "string" },
      { name: "essenceTokenURI", type: "string" },
      { name: "essenceMw", type: "address" },
      { name: "transferable", type: "bool" },
      { name: "initData", type: "bytes" },
      { name: "nonce", type: "uint256" },
      { name: "deadline", type: "uint256" },
    ],
  },

  /* bytes initData,uint256 nonce,uint256 deadline */
  domain: cyberDomain(verifyingContract, contractName, chainId),
  value: {
    profileId: profileId,
    name: name,
    symbol: symbol,
    essenceTokenURI: essenceTokenURI,
    essenceMw: essenceMw,
    transferable: transferable,
    initData: initData,
    nonce: nonce,
    deadline: deadline,
  },
});

export async function generateCollectWithSig(
  signer: Wallet,
  vars: any,
  preData: string,
  postData: string,
  nonce: BigNumberish,
  deadline: string,
  verifyingContract: string,
  contractName: string
): Promise<{ v: number; r: string; s: string }> {
  const params = buildCollectWithSig(
    vars.collector,
    vars.profileId,
    vars.essenceId,
    preData,
    postData,
    nonce,
    deadline,
    verifyingContract,
    contractName,
    await signer.getChainId()
  );

  return await getSigByWallet(signer, params);
}

export const buildCollectWithSig = (
  collector: string,
  profileId: BigNumberish,
  essenceId: BigNumberish,
  data: string,
  postDatas: string,
  nonce: BigNumberish,
  deadline: string,
  verifyingContract: string,
  contractName: string,
  chainId: number
) => ({
  types: {
    collectWithSig: [
      { name: "collector", type: "address" },
      { name: "profileId", type: "uint256" },
      { name: "essenceId", type: "uint256" },
      { name: "data", type: "bytes" },
      { name: "postDatas", type: "bytes" },
      { name: "nonce", type: "uint256" },
      { name: "deadline", type: "uint256" },
    ],
  },

  /* bytes initData,uint256 nonce,uint256 deadline */
  domain: cyberDomain(verifyingContract, contractName, chainId),
  value: {
    collector: collector,
    profileId: profileId,
    essenceId: essenceId,
    data: data,
    postDatas: postDatas,
    nonce: nonce,
    deadline: deadline,
  },
});

function cyberDomain(
  verifyingContract: string,
  contractName: string,
  chainId: number
): {
  name: string;
  version: string;
  chainId: number;
  verifyingContract: string;
} {
  return {
    name: contractName,
    version: "1",
    chainId: chainId,
    verifyingContract: verifyingContract,
  };
}

export const getMwData = async ({
  signer,
  collectPaidMwAddress,
  profileId,
  essenceId,
}: {
  signer: Signer;
  collectPaidMwAddress: string;
  profileId: BigNumberish;
  essenceId: BigNumberish;
}) => {
  const collectPaidMw = CollectPaidMw__factory.connect(
    collectPaidMwAddress,
    signer
  );
  const filter = collectPaidMw.filters.CollectPaidMwSet(
    undefined,
    profileId,
    essenceId
  );

  const events: CollectPaidMwSetEvent[] = await collectPaidMw.queryFilter(filter, 33725604);

  if(events.length != 1) {
    throw new Error("Filter CollectPaidMwSet Event failed.");
  }
  return {
    currency: events[0].args[6],
    amount: events[0].args[4]
  }
};
