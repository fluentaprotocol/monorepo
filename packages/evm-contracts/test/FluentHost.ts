import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { FluentProvider, FluentProvider__factory, FluentHost, FluentHost__factory, FluentToken } from "../typechain-types";
import { Interval, Signer } from "./types";
import { signers, abi, provider, unit } from "./utils";
import { RpcBlockOutput } from "hardhat/internal/hardhat-network/provider/output";
import { getToken, getUnderlying } from "./utils/token";
import { BucketStruct, EndpointStruct } from "../typechain-types/contracts/FluentProvider";
import { getBucket, getEndpoint } from "./utils/provider";

describe("FluentHost", function () {
    const GRACE = 60 * 60 * 48;

    let dao: Signer;
    let account: Signer;
    let service: Signer;
    let attacker: Signer;
    let processor: Signer;


    let minReward: bigint;
    let maxReward: bigint;

    let token: FluentToken;
    let tokenAddress: string;

    let host: FluentHost;
    let hostAddress: string;
    let hostFactory: FluentHost__factory;

    let providerAddress: string;
    let providerContract: FluentProvider;
    let providerFactory: FluentProvider__factory;

    beforeEach(async function () {
        [dao, service, account, processor, attacker] = await signers.getSigners();

        minReward = unit.value(1, 3)
        maxReward = unit.value(2, 3)

        // Provider
        providerFactory = await ethers.getContractFactory("FluentProvider", dao.signer);
        providerContract = await upgrades.deployProxy(providerFactory, [], {
            kind: 'uups',
            redeployImplementation: 'always'
        }).then(x => x.connect(service.signer)) as unknown as FluentProvider;
        providerAddress = await providerContract.getAddress();


        // Router
        hostFactory = await ethers.getContractFactory("FluentHost", dao.signer);
        host = await upgrades.deployProxy(hostFactory, [
            GRACE,
            minReward,
            maxReward,
            dao.address,
            providerAddress
        ], {
            kind: 'uups',
            redeployImplementation: 'always'
        }).then(x => x.connect(account.signer)) as unknown as FluentHost;
        hostAddress = await host.getAddress();

        // Token
        let [underlying] = await getUnderlying(dao).then((x) => ([x[0].connect(account.signer), x[1]]) as typeof x);
        [token, tokenAddress] = await getToken(underlying, dao, hostAddress).then((x) => ([x[0].connect(account.signer), x[1]]) as typeof x);

        let value = unit.value(1);

        await underlying.mint(account.address, value);
        await underlying.approve(tokenAddress, value);

        await token.depositFor(account.address, value)
    });

    describe("Initialization", function () {
        it("# 1.1 Should correctly set the provider address", async function () {
            expect(await host.getFunction('provider').staticCall()).to.eq(providerAddress)
        });

        it("# 1.2 Should correctly set the intial values", async function () {
            expect(await host.dao()).to.eq(dao.address)
            expect(await host.gracePeriod()).to.eq(GRACE)
            expect(await host.minReward()).to.eq(minReward)
            expect(await host.maxReward()).to.eq(maxReward)
        });
    })

    describe("Channels", function () {
        let providerId: string
        let channelId: string

        let bucketTag: string;
        let bucketData: BucketStruct;

        let endpointTag: string;
        let endpointData: EndpointStruct;

        let block: RpcBlockOutput;

        beforeEach(async function () {
            [bucketData, bucketTag] = getBucket(Interval.Monthly, "Fluenta");
            [endpointData, endpointTag] = getEndpoint(tokenAddress, bucketTag);

            providerId = ethers.keccak256(abi.encode(["address", "string"], [service.address, provider.validName]))
            channelId = ethers.keccak256(abi.encode(["bytes32", "address"], [providerId, account.address]))

            await providerContract.openProvider(provider.validName, [bucketData], [endpointData])
            await host.openChannel(providerId, endpointTag);

            block = await account.signer.provider.getBlock('latest') as any
        });

        describe("Open", function () {
            it("# 2.1.1 Should correctly set the channel details", async function () {
                const data = await host.getChannel(channelId);

                const current = new Date(parseInt(block.timestamp) * 1e3);
                const expired = new Date(current.setMonth(current.getMonth() + 1)).valueOf() / 1e3;

                expect(data.provider).to.eq(providerId)
                expect(data.account).to.eq(account.address)
                expect(data.expired).to.eq(expired);
                expect(data.endpoint).to.eq(endpointTag);
            });

            it("# 2.1.2 Should revert if channel is already exists", async function () {
                await expect(host.openChannel(providerId, endpointTag))
                    .to.be.revertedWithCustomError(host, "ChannelAlreadyExists").withArgs(channelId);
            });

            it("# 2.1.3 Should revert if provider does not exist", async function () {
                const randomId = ethers.randomBytes(32);

                await expect(host.openChannel(randomId, endpointTag))
                    .to.be.revertedWithCustomError(providerContract, 'ProviderDoesNotExist')
            });

            it("# 2.1.4 Should revert if bucket does not exist", async function () {
                const randomId = ethers.randomBytes(4);

                await host.closeChannel(channelId);
                await expect(host.openChannel(providerId, randomId))
                    .to.be.revertedWithCustomError(providerContract, 'EndpointDoesNotExist')
            });
        })

        describe("Close", function () {
            it("# 2.2.1 Should all account to close a channel", async function () {
                await expect(host.closeChannel(channelId)).to.not.be.reverted;
            });

            it("# 2.2.2 Should revert if attacker attempts to close a channel", async function () {
                await expect(host.connect(attacker.signer).closeChannel(channelId))
                    .to.be.revertedWithCustomError(host, 'ChannelUnauthorized').withArgs(attacker.address);
            });

            it("# 2.2.3 Should revert if channel not initialized", async function () {
                const randomId = ethers.randomBytes(32);
                await expect(host.closeChannel(randomId))
                    .to.be.revertedWithCustomError(host, "ChannelDoesNotExist").withArgs(randomId);
            });
        })

        describe("Migrate", function () {
            it("# 2.3.1 Should allow the account to migrate the bucket of a channel", async function () {
                await expect(host.openChannel(providerId, endpointTag))
                    .to.be.revertedWithCustomError(host, "ChannelAlreadyExists").withArgs(channelId);
            });

            it("# 2.3.2 Should correctly update the data and start from the current timestamp", async function () {
                await expect(host.openChannel(providerId, endpointTag))
                    .to.be.revertedWithCustomError(host, "ChannelAlreadyExists").withArgs(channelId);
            });
        })
        
        describe("Process", function () {
            it("# 2.4.1 Should allow the channel to be processed", async function () {
                const current = new Date(parseInt(block.timestamp) * 1e3);
                const expired = new Date(current.setMonth(current.getMonth() + 1)).valueOf() / 1e3;
                
                await ethers.provider.send("evm_setNextBlockTimestamp", [expired - (GRACE / 2)]);
                await ethers.provider.send("evm_mine", []);
                
                
                await expect(host.connect(processor.signer).processChannel(channelId))
                .to.not.be.reverted;
            });
            
            it("# 2.4.2 Should revert if the channel does not exists", async function () {
                const randomId = ethers.randomBytes(32);
                
                await expect(host.connect(processor.signer).processChannel(randomId))
                .to.be.revertedWithCustomError(host, "ChannelDoesNotExist").withArgs(randomId);
            });
            
            it("# 2.4.3 Should revert if the channel is locked", async function () {
                await expect(host.connect(processor.signer).processChannel(channelId))
                .to.be.revertedWithCustomError(host, "ChannelLocked").withArgs(channelId);
            });
        })
        
        describe("State", function () {
            it("# 2.3.1 Should correctly return expired chanel state", async function () {
            });
            
            it("# 2.3.1 Should correctly return unlocked channel state", async function () {
            });
        
            it("# 2.3.2 Should correctly update the data and start from the current timestamp", async function () {
            });
        })
    })
})