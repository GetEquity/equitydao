/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Contract, Signer } from "ethers";
import { Provider } from "@ethersproject/providers";

import type { GovernorAlpha } from "../GovernorAlpha";

export class GovernorAlpha__factory {
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): GovernorAlpha {
    return new Contract(address, _abi, signerOrProvider) as GovernorAlpha;
  }
}

const _abi = [
  {
    inputs: [],
    name: "proposalCount",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "nonpayable",
    type: "function",
  },
];
