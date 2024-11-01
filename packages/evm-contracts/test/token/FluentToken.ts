import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { FluentToken, FluentToken__factory, MockERC20__factory, MockERC20 } from "../../typechain-types";

const ETH_1 = ethers.parseEther("1.0")

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

        token = await upgrades.deployProxy(tokenFactory, [underlyingAddress, tokenName, tokenSymbol], {
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

    describe("Deposits and withdrawals", function () {
        beforeEach(async function () {
            await underlying.connect(account).approve(token.getAddress(), ETH_1);
        });

        it("# 2.1 Should allow account to deposit and mint", async function () {
            await token.deposit(ETH_1);

            expect(await token.balanceOf(accountAddress)).to.eq(ETH_1);
            expect(await token.totalSupply()).to.eq(ETH_1);
        });

        it("# 2.2 Should allow account to burn and withdraw balance", async function () {
            await token.deposit(ETH_1);
            await token.withdraw(ETH_1);

            expect(await token.balanceOf(accountAddress)).to.eq(0);
            expect(await underlying.balanceOf(accountAddress)).to.eq(ETH_1);
        });

        it("# 2.3 Should revert if withdraw amount exceeds account balance", async function () {
            const balance = ETH_1;
            const amount = ETH_1 + 1n;

            await token.deposit(balance);

            await expect(token.withdraw(amount)).to.be.revertedWithCustomError(token, "ERC20InsufficientBalance").withArgs(accountAddress, balance, amount);
        });
    });

    describe("Flows", function () {
        let flow: string;
        beforeEach(async function () {
            await underlying.connect(account).approve(token.getAddress(), ETH_1);
            await token.initiateFlow(attackerAddress, ETH_1);

            flow = (await token.mapAccountFlows())[0]
        });

        it("# 3.1 Should allow account initiate flow", async function () {
            expect((await token.mapAccountFlows()).length).to.eq(1);
        });
        
        it("# 3.1 Should allow account initiate flow", async function () {
            console.log(flow)

            expect((await token.mapAccountFlows()).length).to.eq(1);
        });
    });
})