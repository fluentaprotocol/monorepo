import { ethers, upgrades } from "hardhat";
import { FluentToken, IERC20, MockERC20 } from "../../typechain-types";
import { Signer } from "../types";

export async function getUnderlying(signer?: Signer): Promise<[MockERC20, string]> {
    let factory = await ethers.getContractFactory("MockERC20", signer?.signer);
    let contract = await factory.deploy("USDT", "Tether USD").then(x => x.connect(signer?.signer ?? null));
    let address = await contract.getAddress();

    return [contract, address]
}
// Promise<[FluentToken, string]>
export async function getToken(underlying: MockERC20, signer?: Signer, host: string = ethers.ZeroAddress): Promise<[FluentToken, string]> {
    let underlyingSymbol = await underlying.symbol()
    
    let symbol = `${underlyingSymbol}.fx`;
    let name = `Fluent ${underlyingSymbol}`;
    let underlyingAddress = await underlying.getAddress();
    
    let factory = await ethers.getContractFactory("FluentToken", signer?.signer);
    let token = await  upgrades.deployProxy(factory, [host, underlyingAddress, name, symbol], {
        kind: 'uups',
        redeployImplementation: 'always'
    }).then(x => x.connect(signer?.signer ?? null)) as unknown as FluentToken;
    let address = await token.getAddress();

    return [token, address]
}