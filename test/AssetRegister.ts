import chai, { assert, expect } from "chai"
import { solidity } from "ethereum-waffle"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import {
    AssetRegister,
    AssetRegister__factory,
    BoringFactory__factory,
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

describe("AssetRegister", () => {
    let deployer: SignerWithAddress, alice: SignerWithAddress, bob: SignerWithAddress, carol: SignerWithAddress
    let Deployer: string, Alice: string, Bob: string, Carol: string
    const Zero = ethers.constants.AddressZero
    let register: AssetRegister
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
        register = await new AssetRegister__factory(deployer).deploy()
        await register.deployed()

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

        erc1155Strategy = await new ERC1155StrategyMock__factory(deployer).deploy(Zero, rarible.address, 628973)
        await erc1155Strategy.deployed()
    })

    it("Deploy ERC1155TokenReceiver", async function () {
        assert.equal((await register.deployTransaction.wait()).status, 1)
    })

    it("can register an asset", async function () {
        await expect(register.registerAsset(TokenType.ERC20, sushi.address, tokenStrategy.address, 0)).to.emit(register, "URI").withArgs("", 1)
        await expect(register.registerAsset(TokenType.ERC1155, rarible.address, erc1155Strategy.address, 628973))
            .to.emit(register, "URI")
            .withArgs("", 2)
        await expect(register.registerAsset(TokenType.ERC20, sushi.address, tokenStrategy.address, 0)).to.not.emit(register, "URI")
        await expect(register.registerAsset(TokenType.ERC1155, rarible.address, erc1155Strategy.address, 628973)).to.not.emit(register, "URI")

        expect(await register.ids(TokenType.ERC1155, rarible.address, erc1155Strategy.address, 628973)).equals(2)

        let asset = await register.assets(2)
        expect(asset.tokenType).equals(TokenType.ERC1155)
        expect(asset.contractAddress).equals(rarible.address)
        expect(asset.strategy).equals(erc1155Strategy.address)
        expect(asset.tokenId).equals(628973)

        asset = await register.assets(1)
        expect(asset.tokenType).equals(TokenType.ERC20)
        expect(asset.contractAddress).equals(sushi.address)
        expect(asset.strategy).equals(tokenStrategy.address)
        expect(asset.tokenId).equals(0)
    })

    it("cannot register a Native asset", async function () {
        await expect(register.registerAsset(TokenType.Native, Zero, Zero, 0)).to.be.revertedWith("AssetManager: cannot add Native")
    })

    it("cannot add an ERC20 token with a tokenId", async function () {
        await expect(register.registerAsset(TokenType.ERC20, sushi.address, tokenStrategy.address, 1)).to.be.revertedWith("No tokenId for ERC20")
    })

    it("cannot register an asset with a mismatching strategy", async function () {
        await expect(register.registerAsset(TokenType.ERC1155, rarible.address, tokenStrategy.address, 628973)).to.be.revertedWith(
            "Strategy mismatch"
        )
    })

    it("cannot use an EOA as contractAddress", async function () {
        await expect(register.registerAsset(TokenType.ERC20, Alice, tokenStrategy.address, 0)).to.be.revertedWith("YieldBox: Strategy mismatch")
        await expect(register.registerAsset(TokenType.ERC1155, Bob, erc1155Strategy.address, 0)).to.be.revertedWith(
            "YieldBox: Strategy mismatch"
        )
    })
})
