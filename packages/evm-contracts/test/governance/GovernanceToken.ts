import { ethers } from "hardhat";
import { expect } from "chai";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import {
  GovernanceToken,
  GovernanceToken__factory,
} from "../../typechain-types";

// TODO: get a list of required tests
// TODO: create missing tests
// TODO: fix existing tests, if needed

describe("GovernanceToken", function () {
  let owner: HardhatEthersSigner;
  let account: HardhatEthersSigner;
  let attacker: HardhatEthersSigner;

  let tokenFactory: GovernanceToken__factory;
  let tokenAddress: string;
  let tokenSymbol: string;
  let tokenName: string;
  let governanceToken: GovernanceToken;

  let accountAddress: string;
  let attackerAddress: string;

  beforeEach(async function () {
    [owner, account, attacker] = await ethers.getSigners();

    // Retrieve signer addresses
    accountAddress = await account.getAddress();
    attackerAddress = await attacker.getAddress();

    // Deploy GovernanceToken contract
    tokenFactory = (await ethers.getContractFactory(
      "GovernanceToken"
    )) as GovernanceToken__factory;
    governanceToken = await tokenFactory.deploy();

    // Retrieve deployed contract details
    tokenAddress = await governanceToken.getAddress();
    tokenSymbol = await governanceToken.symbol();
    tokenName = await governanceToken.name();

    console.log("GovernanceToken deployed at:", tokenAddress);
    console.log("Token Symbol:", tokenSymbol);
    console.log("Token Name:", tokenName);
  });

  it("should deploy the contract and mint initial supply to the owner", async function () {
    const ownerBalance = await governanceToken.balanceOf(owner.address);
    const totalSupply = await governanceToken.totalSupply();
    expect(totalSupply).to.equal(ownerBalance);
  });

  it("should allow the owner to mint new tokens", async function () {
    const mintAmount = ethers.parseUnits("100", 18);
    await governanceToken.mint(account.address, mintAmount);
    const accountBalance = await governanceToken.balanceOf(account.address);
    expect(accountBalance).to.equal(mintAmount);
  });

  it("should allow the owner to burn tokens", async function () {
    const burnAmount = ethers.parseUnits("100", 18);
    await governanceToken.burn(owner.address, burnAmount);
    const ownerBalance = await governanceToken.balanceOf(owner.address);
    const expectedBalance = ethers.parseUnits("999900", 18);
    expect(ownerBalance).to.equal(expectedBalance);
  });

  it("should allow a user to delegate voting power", async function () {
    const mintAmount = ethers.parseUnits("100", 18);
    await governanceToken.mint(account.address, mintAmount);

    // Delegate voting power
    await governanceToken.connect(account).delegate(attacker.address);

    // Verify delegation
    const delegate = await governanceToken.delegates(account.address);
    const delegatedVotes = await governanceToken.delegatedVotes(
      attacker.address
    );
    expect(delegate).to.equal(attacker.address);
    expect(delegatedVotes).to.equal(mintAmount);
  });

  it("should allow proposal creation", async function () {
    const proposalDescription = "Test Proposal";
    const createProposalSignature = "createProposal(string)";
    await governanceToken[createProposalSignature](proposalDescription);
    const proposal = await governanceToken.proposals(0);

    expect(proposal.description).to.equal(proposalDescription);
    expect(proposal.votesFor).to.equal(0);
    expect(proposal.votesAgainst).to.equal(0);
  });

  it("should allow voting on a proposal", async function () {
    const mintAmount = ethers.parseUnits("100", 18);
    await governanceToken.mint(account.address, mintAmount);

    // Create a proposal and vote on it
    const createProposalSignature = "createProposal(string)";
    await governanceToken
      .connect(account)
      [createProposalSignature]("Test Proposal (For)");
    await governanceToken.connect(account).vote(0, true);

    const proposal = await governanceToken.proposals(0);
    expect(proposal.votesFor).to.equal(mintAmount);
    expect(proposal.votesAgainst).to.equal(0);
  });

  it("should NOT allow executing a proposal right after the timelock", async function () {
    const createProposalSignature = "createProposal(string)";
    await governanceToken[createProposalSignature]("Test Proposal");

    // Increase time to simulate timelock duration
    await ethers.provider.send("evm_increaseTime", [24 * 60 * 60]); // 1 day
    await ethers.provider.send("evm_mine", []);

    await expect(governanceToken.executeProposal(0)).to.be.revertedWith(
      "Proposal can not be executed yet"
    );

    const proposal = await governanceToken.proposals(0);
    expect(proposal.executed).to.be.false;
  });

  it("should allow executing a proposal after the timelock and timelock for execution", async function () {
    const createProposalSignature = "createProposal(string)";
    await governanceToken[createProposalSignature]("Test Proposal");

    // Increase time to simulate timelock duration
    const mintAmount = ethers.parseUnits("100", 18);
    await governanceToken.mint(account.address, mintAmount);
    await governanceToken.connect(account).vote(0, true);

    await ethers.provider.send("evm_increaseTime", [24 * 60 * 60]); // 1 day

    // wait for the timelock for execution
    await ethers.provider.send("evm_increaseTime", [24 * 60 * 60]); // 1 day
    await ethers.provider.send("evm_mine", []);

    await governanceToken.executeProposal(0);

    const proposal = await governanceToken.proposals(0);
    expect(proposal.executed).to.be.true;
  });

  it("should allow votes for and against and execute proposal if votesFor > votesAgainst", async function () {
    // Deploy a mock contract
    const MockContract = await ethers.getContractFactory("MockContract");
    const mock = await MockContract.deploy();

    // Encode function call
    const encodedData = mock.interface.encodeFunctionData("setValue", [42]);

    // Create a proposal
    const createProposalSignature = "createProposal(string,address,bytes)";
    const mintAmount1 = ethers.parseUnits("101", 18);
    const mintAmount2 = ethers.parseUnits("100", 18);
    await governanceToken.mint(account.address, mintAmount1);
    await governanceToken.mint(attacker.address, mintAmount2);
    await governanceToken
      .connect(account)
      [createProposalSignature](
        "Set value in mock contract",
        await mock.getAddress(),
        encodedData
      );

    // Vote "for" and "against"
    await governanceToken.connect(account).vote(0, true); // Account votes "for"
    await governanceToken.connect(attacker).vote(0, false); // Attacker votes "against"

    // Fast forward time to simulate the timelock
    await ethers.provider.send("evm_increaseTime", [24 * 60 * 60]);

    // Execute the proposal (extra timelock)
    await ethers.provider.send("evm_increaseTime", [24 * 60 * 60]);
    await ethers.provider.send("evm_mine", []);
    await governanceToken.connect(account).executeProposal(0);

    // Verify the mock contract's state
    const value = await mock.value();
    expect(value).to.equal(42); // Proposal passed and executed
  });
});
