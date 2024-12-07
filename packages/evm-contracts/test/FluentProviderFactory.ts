import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {
  FluentHost,
  FluentProvider,
  FluentProvider__factory,
  FluentProviderFactory,
} from "../typechain-types";
import {
  deployHost,
  deployHostProxy,
  deployProviderFactory,
  deployProviderImplementation,
} from "./utils/deploy";

describe("FluentProviderFactory", function () {
  //     const BYTES_RAND = ethers.hexlify(ethers.randomBytes(32));
  // const HOST_ADDRESS = ethers.hexlify(ethers.randomBytes(20)).toLowerCase();
  const TOKEN_ADDRESS = ethers.hexlify(ethers.randomBytes(20)).toLowerCase();

  let dao: HardhatEthersSigner;
  let account: HardhatEthersSigner;
  let attacker: HardhatEthersSigner;

  let host: FluentHost;
  let hostAddress: string;

  let implementation: FluentProvider;
  let implementationAddress: string;

  let factory: FluentProviderFactory;
  let factoryAddress: string;


  let validatorAddress: string;
  let accountAddress: string;
  let attackerAddress: string;

  beforeEach(async function () {
    [dao, account, attacker] = await ethers.getSigners();

    validatorAddress = await dao.getAddress();
    accountAddress = await account.getAddress();
    attackerAddress = await attacker.getAddress();

    [
      host,
      hostAddress
    ] = await deployHostProxy(dao);

    [
      implementation,
      implementationAddress
    ] = await deployProviderImplementation(dao);

    [
      factory,
      factoryAddress
    ] = await deployProviderFactory(dao, implementationAddress, hostAddress);

    await host.initialize(factoryAddress);

    // factory = await ethers.getContractFactory("FluentProvider", da);
    // collector = (await upgrades
    //   .deployProxy(factory, [accountAddress, HOST_ADDRESS], {
    //     kind: "uups",
    //     redeployImplementation: "always",
    //   })
    //   .then((x) => x.connect(account))) as unknown as FluentProvider;
  });

  describe("Initialization", function () {
    it("# 1.1 Should set the correct host address", async function () {
      expect(await factory.host()).to.eq(hostAddress);
    });

    it("# 1.2 Should correctly set the implementation address", async function () {
      expect(await factory.implementation()).to.eq(implementationAddress);
    });

    it("# 1.3 Should correctly register with host contract", async function () {
      expect(await host.providerFactory()).to.eq(factoryAddress);
    });
  });
  
  describe("Providers", function () {
  let provider: FluentProvider;
  let providerAddress: string;

    this.beforeEach(async function() {
        await factory.connect(account).openProvider();

        providerAddress = await factory.providerAt(0n);
    })

    it("# 2.1 Should allow account to open a provider", async function () {
      expect(await factory.providerCount()).to.eq(1n);
    });

    it("# 2.2 Should allow account to close a provider", async function () {
      expect(await factory.providerCount()).to.eq(1n);
    });

    // it("# 2.2 Should set the correct implementation address", async function () {
    //   expect(await factory.implementation()).to.eq(implementationAddress);
    // });
  });

//   it("should emit the correct proxy address in the event", async function () {
//     const initData = ethers.utils.randomBytes(32); // Example init data

//     // Call the deployProxy function
//     const tx = await contract.deployProxy(initData);
//     const receipt = await tx.wait();

//     // Find the emitted event
//     const event = receipt.events.find((e) => e.event === "ProxyDeployed");

//     // Get the proxy address from the event
//     const emittedProxyAddress = event.args.proxyAddress;

//     // Check if the proxy address in the event is valid
//     const proxyCode = await ethers.provider.getCode(emittedProxyAddress);
//     expect(proxyCode).to.not.equal("0x"); // Ensure the proxy address contains contract code

//     // Optionally, you can also deploy a proxy manually and compare addresses
//     const expectedProxy = await ProxyContract.deploy();
//     expect(emittedProxyAddress).to.equal(expectedProxy.address);
// });
});
