import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { FluentToken, FluentToken__factory, MockERC20__factory, MockERC20 } from "../typechain-types";

const ETH_1 = ethers.parseEther("1.0")
const ADDR_0 = ethers.ZeroAddress;

describe("FluentToken", function () {
    let validator: HardhatEthersSigner;
    let account: HardhatEthersSigner;
    let attacker: HardhatEthersSigner;

    let underlyingFactory: MockERC20__factory;
    let underlyingAddress: string;
    let underlying: MockERC20;

    let tokenFactory: FluentToken__factory;
    let tokenAddress: string;
    let tokenSymbol: string;
    let tokenName: string;
    let token: FluentToken;

    let accountAddress: string;
    let attackerAddress: string;

    beforeEach(async function () {
        [validator, account, attacker] = await ethers.getSigners();

        // validatorAddress = await validator.getAddress();
        accountAddress = await account.getAddress();
        attackerAddress = await attacker.getAddress();

        // Prepare underlying token
        underlyingFactory = await ethers.getContractFactory("MockERC20", validator);
        underlying = await underlyingFactory.deploy("USDT", "Tether USD").then(x => x.connect(account));
        underlyingAddress = await underlying.getAddress();

        await underlying.mint(account, ETH_1);

        tokenFactory = await ethers.getContractFactory("FluentToken", validator);
        tokenSymbol = `${await underlying.symbol()}.fx`;
        tokenName = `Fluent ${await underlying.symbol()}`;

        token = await upgrades.deployProxy(tokenFactory, [ADDR_0, underlyingAddress, tokenName, tokenSymbol], {
            kind: 'uups',
            redeployImplementation: 'always'
        }).then(x => x.connect(account)) as unknown as FluentToken;
        tokenAddress = await token.getAddress();
    });

    describe("Initialization", function () {
        it("# 1.1 Should set the correct underlying address", async function () {
            expect(await token.underlying()).to.eq(underlyingAddress)
        });

        it("# 1.2 Should set the correct name address", async function () {
            expect(await token.name()).to.eq(tokenName)
        });

        it("# 1.3 Should set the correct symbol address", async function () {
            expect(await token.symbol()).to.eq(tokenSymbol)
        });

        it("# 1.4 Should set the correct decimals from underlying", async function () {
            expect(await token.decimals()).to.eq(await underlying.decimals());
        });

        it("# 1.5 Should set initial totalSupply of zero", async function () {
            expect(await token.totalSupply()).to.eq(0);
        });
    });

    describe("Deposits", function () {
        beforeEach(async function () {
            await underlying.connect(account).approve(tokenAddress, ETH_1);
        });

        it("# 2.1 Should allow deposit and mint tokens", async function () {
            await token.connect(account).deposit(ETH_1);

            expect(await token.balanceOf(accountAddress)).to.equal(ETH_1);
            expect(await token.totalSupply()).to.equal(ETH_1);
        });

        it("# 2.2 Should revert on deposit with insufficient allowance", async function () {
            await underlying.connect(account).approve(tokenAddress, ETH_1 - 1n);

            await expect(token.connect(account).deposit(ETH_1)).to.be.revertedWithCustomError(token, 'ERC20InsufficientAllowance')
        });
    });

    describe("Withdrawals", function () {
        beforeEach(async function () {
            await underlying.connect(account).approve(tokenAddress, ETH_1);
            await token.connect(account).deposit(ETH_1);
        });

        it("# 3.1 Should allow withdrawal and burn tokens", async function () {
            await token.connect(account).withdraw(ETH_1);

            expect(await token.balanceOf(accountAddress)).to.equal(0);
            expect(await underlying.balanceOf(accountAddress)).to.equal(ETH_1);
        });

        it("# 3.2 Should revert on withdrawal exceeding balance", async function () {
            await expect(token.connect(account).withdraw(ETH_1 + 1n)).to.be.revertedWithCustomError(
                token,
                "ERC20InsufficientBalance"
            ).withArgs(accountAddress, ETH_1, ETH_1 + 1n);
        });
    });

    describe("Transfers", function () {
        beforeEach(async function () {
            await underlying.connect(account).approve(tokenAddress, ETH_1);
            await token.connect(account).deposit(ETH_1);
        });

        it("# 4.1 Should allow token transfers", async function () {
            await token.connect(account).transfer(attackerAddress, ETH_1);

            expect(await token.balanceOf(accountAddress)).to.equal(0);
            expect(await token.balanceOf(attackerAddress)).to.equal(ETH_1);
        });

        it("# 4.2 Should revert on transfer exceeding balance", async function () {
            await expect(
                token.connect(account).transfer(attackerAddress, ETH_1 + 1n)
            ).to.be.revertedWithCustomError(
                token,
                "ERC20InsufficientBalance"
            ).withArgs(accountAddress, ETH_1, ETH_1 + 1n);
        });
    });

    describe("Allowance and Approvals", function () {
        it("# 5.1 Should set and use allowance for transferFrom", async function () {
            await underlying.connect(account).approve(tokenAddress, ETH_1);
            await token.connect(account).deposit(ETH_1);

            await token.connect(account).approve(attackerAddress, ETH_1);

            await token.connect(attacker).transferFrom(accountAddress, attackerAddress, ETH_1);

            expect(await token.balanceOf(accountAddress)).to.equal(0);
            expect(await token.balanceOf(attackerAddress)).to.equal(ETH_1);
        });

        it("# 5.2 Should revert transferFrom with insufficient allowance", async function () {
            await underlying.connect(account).approve(tokenAddress, ETH_1);
            await token.connect(account).deposit(ETH_1);

            await token.connect(account).approve(attackerAddress, ETH_1 - 1n);

            await expect(
                token.connect(attacker).transferFrom(accountAddress, attackerAddress, ETH_1)
            ).to.be.revertedWithCustomError(
                token,
                "ERC20InsufficientAllowance"
            ).withArgs(attackerAddress, ETH_1 - 1n, ETH_1);
        });
    });

    describe("Transactions", function () {
        beforeEach(async () => {
            await underlying.mint(account, ETH_1 * 3n);
            await underlying.connect(account).approve(tokenAddress, ETH_1 * 3n);
            await token.connect(account).deposit(ETH_1 * 3n);
        })
        
        // it("# 6.1 Should revert transferFrom with insufficient allowance", async function () {
        //     // Process transaction
        //     await token.processTransaction(accountAddress, attackerAddress, ETH_1);
      
        //     // Check balances
        //     expect(await token.balanceOf(accountAddress)).to.equal(0);
        //     expect(await token.balanceOf(attackerAddress)).to.equal(ETH_1 * 3n);
        // });
    });

    describe("Upgradeability", function () {
        it("# 7.1 Should allow upgrades", async function () {
            const factory = await ethers.getContractFactory("FluentToken", validator);
            const newImplementation = await upgrades.upgradeProxy(tokenAddress, factory, {
                redeployImplementation: 'always'
            });

            const updated = await upgrades.erc1967.getImplementationAddress(await newImplementation.getAddress())
            expect(await upgrades.erc1967.getImplementationAddress(tokenAddress)).to.equal(updated);
        });
    });
})