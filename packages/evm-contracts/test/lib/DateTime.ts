import { expect } from "chai";
import { ethers } from "hardhat";
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";
import { MockDateTime, MockDateTime__factory } from "../../typechain-types";

// base fee = gasprice


describe("DateTime", function () {
    let account: HardhatEthersSigner;
    let accountAddress: string;

    let factory: MockDateTime__factory;
    let contract: MockDateTime;

    beforeEach(async function () {
        [account] = await ethers.getSigners();
        accountAddress = await account.getAddress();

        factory = await ethers.getContractFactory("MockDateTime", account);
        contract = await factory.deploy().then(x => x.connect(account));
    });

    describe("Timestamp", function () {
        it("# 1.1 Should correctly calculate timestamp from date", async function () {
            const timestamp = await contract.datestamp(2023, 10, 10);
            expect(timestamp).to.eq(1696896000n)
        });

        it("# 1.2 Should correctly calculate timestamp from datetime", async function () {
            const timestamp = await contract.timestamp(2023, 10, 10, 12, 30, 45);
            expect(timestamp).to.be.eq(1696941045n);
        });
    });

    describe("DateTime", function () {
        it("# 2.1 Should correctly extract date from timestamp", async function () {
            const [year, month, day] = await contract.date(1697040000); // Example timestamp

            expect(year).to.equal(2023);
            expect(month).to.equal(10);
            expect(day).to.equal(11);
        });

        it("# 2.2 Should correctly extract datetime from timestamp", async function () {
            const [year, month, day, hour, minute, second] = await contract.datetime(1697040000); // Example timestamp

            expect(year).to.equal(2023);
            expect(month).to.equal(10);
            expect(day).to.equal(11);
            expect(hour).to.equal(16);
            expect(minute).to.equal(0);
            expect(second).to.equal(0);
        });
    });
})