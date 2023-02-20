import chai, { assert, expect } from "chai"
import { solidity } from "ethereum-waffle"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import {
    WETH9Mock__factory,
    YieldBox,
    YieldBoxURIBuilder,
    YieldBoxURIBuilder__factory,
    YieldBox__factory,
    ERC20Mock__factory,
    ERC1155Mock,
    ERC1155Mock__factory,
    ERC1155StrategyMock,
    ERC1155StrategyMock__factory,
    ERC20Mock,
    ERC20StrategyMock,
    ERC20StrategyMock__factory,
} from "../typechain-types"
import { TokenType } from "../sdk"
chai.use(solidity)

describe("YieldBoxURIBuilder", () => {
    let deployer: SignerWithAddress, alice: SignerWithAddress, bob: SignerWithAddress, carol: SignerWithAddress
    let Deployer: string, Alice: string, Bob: string, Carol: string
    const Zero = ethers.constants.AddressZero
    let uriBuilder: YieldBoxURIBuilder
    let yieldBox: YieldBox

    let tokenStrategy: ERC20StrategyMock
    let sushi: ERC20Mock
    let rarible: ERC20Mock
    let erc1155: ERC1155Mock
    let erc1155Strategy: ERC1155StrategyMock
    beforeEach(async () => {
        ;({ deployer, alice, bob, carol } = await ethers.getNamedSigners())
        Deployer = deployer.address
        Alice = alice.address
        Bob = bob.address
        Carol = carol.address

        // ERC20 token
        sushi = await new ERC20Mock__factory(deployer).deploy(10000)
        await sushi.deployed()

        rarible = await new ERC20Mock__factory(deployer).deploy(10000)
        await rarible.deployed()

        tokenStrategy = await new ERC20StrategyMock__factory(deployer).deploy(Zero, sushi.address)
        await tokenStrategy.deployed()

        // ERC1155 token
        erc1155 = await new ERC1155Mock__factory(deployer).deploy()
        await erc1155.deployed()
        await erc1155.mint(Deployer, 42, 10000)

        erc1155Strategy = await new ERC1155StrategyMock__factory(deployer).deploy(Zero, rarible.address, 50)
        await erc1155Strategy.deployed()
        const weth = await new WETH9Mock__factory(deployer).deploy()
        await weth.deployed()

        uriBuilder = await new YieldBoxURIBuilder__factory(deployer).deploy()
        await uriBuilder.deployed()

        yieldBox = await new YieldBox__factory(deployer).deploy(weth.address, uriBuilder.address)
        await yieldBox.deployed()
    })

    it("Deploy YieldBoxURIBuilder", async function () {
        assert.equal((await uriBuilder.deployTransaction.wait()).status, 1)
    })

    it("Creates URI for Native tokens", async function () {
        await yieldBox.createToken("Boring Token", "BORING", 18, "")
        const asset = await yieldBox.assets(1)
        const nativeToken = await yieldBox.nativeTokens(1)

        const uri = await uriBuilder.uri(
            await yieldBox.assets(1),
            await yieldBox.nativeTokens(1),
            await yieldBox.totalSupply(1),
            await yieldBox.owner(1)
        )
        expect(uri.startsWith("data:application/json;base64,")).to.be.true
        const base64 = uri.substring(29)
        const json = Buffer.from(base64, "base64").toString("utf-8")
        const data = JSON.parse(json)
        expect(data.properties.tokenType).equals("Native")
        expect(data.name).equals("Boring Token")
        expect(data.symbol).equals("BORING")
        expect(data.decimals).equals(18)
        expect(data.properties.strategy).equals(Zero)
        expect(data.properties.totalSupply).equals(0)
        expect(data.properties.fixedSupply).equals(false)
    })

    it("Creates URI for Native token with fixed supply", async function () {
        await yieldBox.createToken("Boring Token", "BORING", 18, "")
        await yieldBox.mint(1, Alice, 1000)
        await yieldBox.transferOwnership(1, Zero, true, true)

        const uri = await uriBuilder.uri(
            await yieldBox.assets(1),
            await yieldBox.nativeTokens(1),
            await yieldBox.totalSupply(1),
            await yieldBox.owner(1)
        )
        expect(uri.startsWith("data:application/json;base64,")).to.be.true
        const base64 = uri.substring(29)
        const json = Buffer.from(base64, "base64").toString("utf-8")
        const data = JSON.parse(json)
        expect(data.properties.tokenType).equals("Native")
        expect(data.name).equals("Boring Token")
        expect(data.symbol).equals("BORING")
        expect(data.decimals).equals(18)
        expect(data.properties.strategy).equals(Zero)
        expect(data.properties.totalSupply).equals(1000)
        expect(data.properties.fixedSupply).equals(true)
    })

    it("Creates URI for ERC20 token", async function () {
        await yieldBox.registerAsset(TokenType.ERC20, sushi.address, tokenStrategy.address, 0)

        const uri = await uriBuilder.uri(
            await yieldBox.assets(1),
            await yieldBox.nativeTokens(1),
            await yieldBox.totalSupply(1),
            await yieldBox.owner(1)
        )
        expect(uri.startsWith("data:application/json;base64,")).to.be.true
        const base64 = uri.substring(29)
        const json = Buffer.from(base64, "base64").toString("utf-8")
        const data = JSON.parse(json)
        expect(data.properties.tokenType).equals("ERC20")
        expect(data.name).equals("???")
        expect(data.symbol).equals("???")
        expect(data.decimals).equals(18)
        expect(data.properties.strategy.toLowerCase()).equals(tokenStrategy.address.toLowerCase())
        expect(data.properties.tokenAddress.toLowerCase()).equals(sushi.address.toLowerCase())
    })

    it("Creates URI for ERC1155 token", async function () {
        await yieldBox.registerAsset(TokenType.ERC1155, rarible.address, erc1155Strategy.address, 50)

        const uri = await uriBuilder.uri(
            await yieldBox.assets(1),
            await yieldBox.nativeTokens(1),
            await yieldBox.totalSupply(1),
            await yieldBox.owner(1)
        )
        expect(uri.startsWith("data:application/json;base64,")).to.be.true
        const base64 = uri.substring(29)
        const json = Buffer.from(base64, "base64").toString("utf-8")
        const data = JSON.parse(json)
        expect(data.properties.tokenType).equals("ERC1155")
        expect(data.name.toLowerCase()).equals(`erc1155:${rarible.address.toLowerCase()}/50`)
        expect(data.symbol).equals("ERC1155")
        expect(data.properties.strategy.toLowerCase()).equals(erc1155Strategy.address.toLowerCase())
        expect(data.properties.tokenAddress.toLowerCase()).equals(rarible.address.toLowerCase())
        expect(data.properties.tokenId).equals(50)
    })
})
