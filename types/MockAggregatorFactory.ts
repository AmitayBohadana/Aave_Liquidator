/* Autogenerated file. Do not edit manually. */
/* tslint:disable */
/* eslint-disable */

import { Signer, BigNumberish } from "ethers";
import { Provider, TransactionRequest } from "@ethersproject/providers";
import { Contract, ContractFactory, Overrides } from "@ethersproject/contracts";

import type { MockAggregator } from "./MockAggregator";

export class MockAggregatorFactory extends ContractFactory {
  constructor(signer?: Signer) {
    super(_abi, _bytecode, signer);
  }

  deploy(
    _initialAnswer: BigNumberish,
    overrides?: Overrides
  ): Promise<MockAggregator> {
    return super.deploy(
      _initialAnswer,
      overrides || {}
    ) as Promise<MockAggregator>;
  }
  getDeployTransaction(
    _initialAnswer: BigNumberish,
    overrides?: Overrides
  ): TransactionRequest {
    return super.getDeployTransaction(_initialAnswer, overrides || {});
  }
  attach(address: string): MockAggregator {
    return super.attach(address) as MockAggregator;
  }
  connect(signer: Signer): MockAggregatorFactory {
    return super.connect(signer) as MockAggregatorFactory;
  }
  static connect(
    address: string,
    signerOrProvider: Signer | Provider
  ): MockAggregator {
    return new Contract(address, _abi, signerOrProvider) as MockAggregator;
  }
}

const _abi = [
  {
    inputs: [
      {
        internalType: "int256",
        name: "_initialAnswer",
        type: "int256",
      },
    ],
    stateMutability: "nonpayable",
    type: "constructor",
  },
  {
    anonymous: false,
    inputs: [
      {
        indexed: true,
        internalType: "int256",
        name: "current",
        type: "int256",
      },
      {
        indexed: true,
        internalType: "uint256",
        name: "roundId",
        type: "uint256",
      },
      {
        indexed: false,
        internalType: "uint256",
        name: "timestamp",
        type: "uint256",
      },
    ],
    name: "AnswerUpdated",
    type: "event",
  },
  {
    inputs: [],
    name: "getTokenType",
    outputs: [
      {
        internalType: "uint256",
        name: "",
        type: "uint256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
  {
    inputs: [],
    name: "latestAnswer",
    outputs: [
      {
        internalType: "int256",
        name: "",
        type: "int256",
      },
    ],
    stateMutability: "view",
    type: "function",
  },
];

const _bytecode =
  "0x608060405234801561001057600080fd5b506040516101153803806101158339818101604052602081101561003357600080fd5b5051600081815560408051428152905183917f0559884fd3a460db3073b7fc896cc77986f16e378210ded43186175bf646fc5f919081900360200190a35060968061007f6000396000f3fe6080604052348015600f57600080fd5b506004361060325760003560e01c806350d25bcd146037578063fcab181914604f575b600080fd5b603d6055565b60408051918252519081900360200190f35b603d605b565b60005490565b60019056fea2646970667358221220161c8d2a80cb1ff15d7aaf99f656cf8a9b4a5efb416ccfafa0edc4aa98bc1c3964736f6c634300060c0033";
