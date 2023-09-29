import { Signer } from "ethers";
import { DeployedContracts } from "./constants";
import {
  IDataTokenHub__factory,
  IDataTokenHub,
} from "./contracts";
import { Chain } from "./types";
export class DataTokenHub {
  env: Chain;
  signer: Signer;
  instance: IDataTokenHub;
  
  constructor({env, signer}:{env: Chain, signer: Signer}) {
    if(env === "BSC" || env === "Polygon") {
      throw new Error("Chain Not Supported");
    }
    this.env = env;
    this.signer = signer;
    this.instance = IDataTokenHub__factory.connect(DeployedContracts[env].DataTokenHub, signer);
  }

  public async whitelistDataTokenFactory(dataTokenFactory: string) {
    const tx = await this.instance.whitelistDataTokenFactory(dataTokenFactory, true);
    return tx.wait();
  }

  public async setGovernor(governor: string) {
    const tx = await this.instance.setGovernor(governor);
    return tx.wait();
  }

  public getVersion() {
    return this.instance.version();
  }

  public getGovernor() {
    return this.instance.getGovernor();
  }

  public isDataTokenRegistered(dataToken: string) {
    return this.instance.isDataTokenRegistered(dataToken);
  }

  public isDataTokenFactoryWhitelisted(dataTokenFactory: string) {
    return this.instance.isDataTokenFactoryWhitelisted(dataTokenFactory);
  }
}
