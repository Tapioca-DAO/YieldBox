import chai, { expect } from "chai"
import { solidity } from "ethereum-waffle"
import { ethers } from "hardhat"
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers"
import {
    ERC1155Mock,
    ERC1155Mock__factory,
    ERC1155StrategyMock,
    ERC1155StrategyMock__factory,
    ERC20Mock,
    ERC20Mock__factory,
    ERC20StrategyMock,
    ERC20StrategyMock__factory,
    ERC721Mock,
    ERC721Mock__factory,
    ERC721StrategyMock,
    ERC721StrategyMock__factory,
    MasterContractFullCycleMock__factory,
    MasterContractMock__factory,
    WETH9Mock,
    WETH9Mock__factory,
    YieldBox,
    YieldBoxPermit,
    YieldBoxURIBuilder,
    YieldBoxURIBuilder__factory,
    YieldBox__factory,
} from "../typechain-types"
import { TokenType } from "../sdk"
chai.use(solidity)

describe("YieldBox", function () {
    let deployer: SignerWithAddress, alice: SignerWithAddress, bob: SignerWithAddress, carol: SignerWithAddress
    let Deployer: string, Alice: string, Bob: string, Carol: string
    const Zero = ethers.constants.AddressZero
    let weth: WETH9Mock
    let yieldBox: YieldBox
    let uriBuilder: YieldBoxURIBuilder
    let token: ERC20Mock
    let erc721: ERC721Mock
    let erc1155: ERC1155Mock
    let tokenStrategy: ERC20StrategyMock
    let erc721Strategy: ERC721StrategyMock
    let erc1155Strategy: ERC1155StrategyMock
    let ethStrategy: ERC20StrategyMock

    beforeEach(async () => {
        ;({ deployer, alice, bob, carol } = await ethers.getNamedSigners())
        Deployer = deployer.address
        Alice = alice.address
        Bob = bob.address
        Carol = carol.address

        weth = await new WETH9Mock__factory(deployer).deploy()
        await weth.deployed()

        uriBuilder = await new YieldBoxURIBuilder__factory(deployer).deploy()
        await uriBuilder.deployed()

        yieldBox = await new YieldBox__factory(deployer).deploy(weth.address, uriBuilder.address)
        await yieldBox.deployed()

        // Native token
        await yieldBox.createToken("Boring Token", "BORING", 18, "")
        await yieldBox.mint(1, Deployer, 10000)

        // ERC20 token
        token = await new ERC20Mock__factory(deployer).deploy(10000)
        await token.deployed()
        token.approve(yieldBox.address, 10000)

        // ERC721 token
        erc721 = await new ERC721Mock__factory(deployer).deploy()
        await erc721.deployed()
        await erc721.mint(Deployer, 42)
        await erc721.mint(Alice, 777)
        await erc721.mint(Deployer, 420)
        erc721.setApprovalForAll(yieldBox.address, true)
        erc721.connect(alice).setApprovalForAll(yieldBox.address, true)

        // ERC1155 token
        erc1155 = await new ERC1155Mock__factory(deployer).deploy()
        await erc1155.deployed()
        await erc1155.mint(Deployer, 42, 10000)
        await erc1155.setApprovalForAll(yieldBox.address, true)

        // Strategies
        tokenStrategy = await new ERC20StrategyMock__factory(deployer).deploy(yieldBox.address, token.address)
        await tokenStrategy.deployed()

        erc721Strategy = await new ERC721StrategyMock__factory(deployer).deploy(yieldBox.address, erc721.address, 42)
        await erc721Strategy.deployed()

        erc1155Strategy = await new ERC1155StrategyMock__factory(deployer).deploy(yieldBox.address, erc1155.address, 42)
        await erc1155Strategy.deployed()

        ethStrategy = await new ERC20StrategyMock__factory(deployer).deploy(yieldBox.address, weth.address)
        await ethStrategy.deployed()
    })

    it("Deploy YieldBox", async function () {
        expect((await yieldBox.deployTransaction.wait()).status).equals(1)

        expect(await yieldBox.wrappedNative()).equals(weth.address)
        expect(await yieldBox.uriBuilder()).equals(uriBuilder.address)
    })

    describe("toShare and toAmount", () => {
        it("works", async function () {
            await yieldBox.deposit(TokenType.ERC20, token.address, tokenStrategy.address, 0, Deployer, Deployer, 1000, 0)
            expect(await yieldBox.toShare(2, 123, false)).equals(123_00000000)
            expect(await yieldBox.toAmount(2, 123_00000000, false)).equals(123)
            expect(await yieldBox.amountOf(Deployer, 2)).equals(1000)

            await yieldBox.deposit(TokenType.ERC1155, erc1155.address, erc1155Strategy.address, 42, Deployer, Deployer, 1000, 0)
            expect(await yieldBox.toShare(3, 123, false)).equals(123_00000000)
            expect(await yieldBox.toAmount(3, 123_00000000, false)).equals(123)
            expect(await yieldBox.amountOf(Deployer, 3)).equals(1000)

            await yieldBox.depositETH(ethStrategy.address, Deployer, 1000, { value: 1000 })
            expect(await yieldBox.toShare(4, 123, false)).equals(123_00000000)
            expect(await yieldBox.toAmount(4, 123_00000000, false)).equals(123)
            expect(await yieldBox.amountOf(Deployer, 4)).equals(1000)
        })
    })

    describe("deposit", () => {
        it("handles deposit of ERC20 token", async function () {
            // deposit by amount
            await expect(yieldBox.deposit(TokenType.ERC20, token.address, tokenStrategy.address, 0, Deployer, Alice, 1000, 0))
                .to.emit(yieldBox, "AssetRegistered")
                .to.emit(token, "Transfer")
                .to.emit(yieldBox, "TransferSingle")

            // deposit by share
            await expect(yieldBox.deposit(TokenType.ERC20, token.address, tokenStrategy.address, 0, Deployer, Alice, 0, 1000_00000000))
                .to.emit(token, "Transfer")
                .to.emit(yieldBox, "TransferSingle")
                .to.not.emit(yieldBox, "AssetRegistered")

            expect(await yieldBox.balanceOf(Alice, 2)).equals(2000_00000000)
        })

        it("handles deposit of ERC1155 token (External)", async function () {
            // deposit by amount
            await expect(yieldBox.deposit(TokenType.ERC1155, erc1155.address, erc1155Strategy.address, 42, Deployer, Alice, 1000, 0))
                .to.emit(yieldBox, "AssetRegistered")
                .withArgs(TokenType.ERC1155, erc1155.address, erc1155Strategy.address, 42, 2)
                .to.emit(erc1155, "TransferSingle")
                .to.emit(yieldBox, "TransferSingle")

            // deposit by share
            await expect(yieldBox.deposit(TokenType.ERC1155, erc1155.address, erc1155Strategy.address, 42, Deployer, Alice, 0, 1000_00000000))
                .to.emit(erc1155, "TransferSingle")
                .to.emit(yieldBox, "TransferSingle")
                .to.not.emit(yieldBox, "AssetRegistered")

            expect(await yieldBox.balanceOf(Alice, 2)).equals(2000_00000000)
        })

        it("reverts on trying to deposit of Native asset", async function () {
            // deposit by amount
            await expect(yieldBox.depositAsset(1, Deployer, Alice, 1000, 0)).to.be.reverted
            // deposit by share
            await expect(yieldBox.depositAsset(1, Deployer, Alice, 0, 1000_00000000)).to.be.reverted

            expect(await yieldBox.balanceOf(Alice, 1)).equals(0)
        })

        it("reverts on trying to deposit assets that aren't yours", async function () {
            // deposit by amount
            await expect(yieldBox.connect(alice).depositAsset(1, Deployer, Alice, 1000, 0)).to.be.reverted
            // deposit by share
            await expect(yieldBox.connect(alice).depositAsset(1, Deployer, Alice, 0, 1000_00000000)).to.be.reverted

            expect(await yieldBox.balanceOf(Alice, 1)).equals(0)
        })
    })

    describe("deposit with strategy", () => {
        it("handles deposit of ERC20 token", async function () {
            // deposit by amount
            await yieldBox.deposit(TokenType.ERC20, token.address, tokenStrategy.address, 0, Deployer, Alice, 1000, 0)
            // deposit by share
            await yieldBox.deposit(TokenType.ERC20, token.address, tokenStrategy.address, 0, Deployer, Alice, 0, 1000_00000000)

            expect(await yieldBox.balanceOf(Alice, 2)).equals(2000_00000000)
            expect(await yieldBox.toAmount(2, 2000_00000000, false)).equals(2000)

            expect(await token.balanceOf(yieldBox.address)).equals(0)
            expect(await token.balanceOf(tokenStrategy.address)).equals(2000)
        })

        it("handles deposit of ERC721 token", async function () {
            await yieldBox.registerAsset(TokenType.ERC721, erc721.address, erc721Strategy.address, 42)
            const id = await yieldBox.ids(TokenType.ERC721, erc721.address, erc721Strategy.address, 42)
            await yieldBox.depositNFTAsset(id, Deployer, Alice)

            expect(await yieldBox.balanceOf(Alice, 2)).equals(1)
            expect(await yieldBox.toAmount(2, 1, false)).equals(1)

            expect(await erc721.balanceOf(yieldBox.address)).equals(0)
            expect(await erc721.balanceOf(erc721Strategy.address)).equals(1)
        })

        it("handles deposit of ERC1155 token (Native)", async function () {
            const strategy = await new ERC1155StrategyMock__factory(deployer).deploy(yieldBox.address, yieldBox.address, 1)
            await strategy.deployed()
            // deposit by amount
            await yieldBox.deposit(TokenType.ERC1155, yieldBox.address, strategy.address, 1, Deployer, Alice, 1000, 0)
            // deposit by share
            await yieldBox.deposit(TokenType.ERC1155, yieldBox.address, strategy.address, 1, Deployer, Alice, 0, 1000_00000000)

            expect(await yieldBox.balanceOf(Alice, 2)).equals(2000_00000000)
        })
    })

    describe("depositETH", () => {
        it("handles deposit of ETH", async function () {
            // deposit by amount only
            await yieldBox.depositETH(ethStrategy.address, Alice, 1000, { value: 1000 })

            expect(await yieldBox.balanceOf(Alice, 2)).equals(1000_00000000)
        })

        it("reverts on deposit of not ETH", async function () {
            // deposit by amount only
            await expect(yieldBox.depositETHAsset(1, Alice, 1000)).to.be.reverted
        })
    })

    describe("depositETH with strategy", () => {
        it("handles deposit of ETH", async function () {
            // deposit by amount only
            await yieldBox.depositETH(ethStrategy.address, Alice, 1000, { value: 1000 })

            expect(await yieldBox.balanceOf(Alice, 2)).equals(1000_00000000)
            expect(await weth.balanceOf(yieldBox.address)).equals(0)
            expect(await weth.balanceOf(ethStrategy.address)).equals(1000)
        })
    })

    describe("transfer", () => {
        it("can transfer", async function () {
            await expect(yieldBox.connect(deployer).transfer(Deployer, Alice, 1, 1000))
                .to.emit(yieldBox, "TransferSingle")
                .withArgs(Deployer, Deployer, Alice, 1, 1000)

            expect(await yieldBox.balanceOf(Deployer, 1)).equals(9000)
            expect(await yieldBox.balanceOf(Alice, 1)).equals(1000)
        })
    })

    describe("safeTransfer", () => {
        it("can safeTransfer", async function () {
            await expect(yieldBox.connect(deployer).safeTransferFrom(Deployer, Alice, 1, 1000, "0x"))
                .to.emit(yieldBox, "TransferSingle")
                .withArgs(Deployer, Deployer, Alice, 1, 1000)

            expect(await yieldBox.balanceOf(Deployer, 1)).equals(9000)
            expect(await yieldBox.balanceOf(Alice, 1)).equals(1000)
        })
    })

    describe("batchTransfer", () => {
        it("can transfer", async function () {
            await yieldBox.createToken("Test", "TEST", 0, "")
            await yieldBox.createToken("Another", "ANY", 12, "")
            await yieldBox.mint(2, Deployer, 5000)
            await yieldBox.mint(3, Deployer, 3000)
            await expect(yieldBox.connect(deployer).batchTransfer(Deployer, Alice, [1, 3, 2], [1000, 1200, 500]))
                .to.emit(yieldBox, "TransferBatch")
                .withArgs(Deployer, Deployer, Alice, [1, 3, 2], [1000, 1200, 500])

            expect(await yieldBox.balanceOf(Deployer, 1)).equals(9000)
            expect(await yieldBox.balanceOf(Deployer, 2)).equals(4500)
            expect(await yieldBox.balanceOf(Deployer, 3)).equals(1800)
            expect(await yieldBox.balanceOf(Alice, 1)).equals(1000)
            expect(await yieldBox.balanceOf(Alice, 2)).equals(500)
            expect(await yieldBox.balanceOf(Alice, 3)).equals(1200)
        })
    })

    describe("safeBatchTransfer", () => {
        it("can transfer", async function () {
            await yieldBox.createToken("Test", "TEST", 0, "")
            await yieldBox.createToken("Another", "ANY", 12, "")
            await yieldBox.mint(2, Deployer, 5000)
            await yieldBox.mint(3, Deployer, 3000)
            await expect(yieldBox.connect(deployer).safeBatchTransferFrom(Deployer, Alice, [1, 3, 2], [1000, 1200, 500], "0x"))
                .to.emit(yieldBox, "TransferBatch")
                .withArgs(Deployer, Deployer, Alice, [1, 3, 2], [1000, 1200, 500])

            expect(await yieldBox.balanceOf(Deployer, 1)).equals(9000)
            expect(await yieldBox.balanceOf(Deployer, 2)).equals(4500)
            expect(await yieldBox.balanceOf(Deployer, 3)).equals(1800)
            expect(await yieldBox.balanceOf(Alice, 1)).equals(1000)
            expect(await yieldBox.balanceOf(Alice, 2)).equals(500)
            expect(await yieldBox.balanceOf(Alice, 3)).equals(1200)
        })
    })

    describe("transferMultiple", () => {
        it("can transfer", async function () {
            await expect(yieldBox.connect(deployer).transferMultiple(Deployer, [Alice, Bob, Carol], 1, [1000, 3000, 500]))
                .to.emit(yieldBox, "TransferSingle")
                .withArgs(Deployer, Deployer, Alice, 1, 1000)
                .to.emit(yieldBox, "TransferSingle")
                .withArgs(Deployer, Deployer, Bob, 1, 3000)
                .to.emit(yieldBox, "TransferSingle")
                .withArgs(Deployer, Deployer, Carol, 1, 500)

            expect(await yieldBox.balanceOf(Deployer, 1)).equals(5500)
            expect(await yieldBox.balanceOf(Alice, 1)).equals(1000)
            expect(await yieldBox.balanceOf(Bob, 1)).equals(3000)
            expect(await yieldBox.balanceOf(Carol, 1)).equals(500)
        })

        it("can's transfer to zero", async function () {
            await expect(yieldBox.connect(deployer).transferMultiple(Deployer, [Alice, Bob, Zero], 1, [1000, 3000, 500])).to.be.reverted
        })
    })

    describe("withdraw", () => {
        it("can withdraw ERC20", async function () {
            await yieldBox.deposit(TokenType.ERC20, token.address, tokenStrategy.address, 0, Deployer, Deployer, 1000, 0)
            await yieldBox.deposit(TokenType.ERC20, token.address, tokenStrategy.address, 0, Deployer, Deployer, 0, 1000_00000000)
            await yieldBox.withdraw(2, Deployer, Deployer, 1000, 0)
            await yieldBox.withdraw(2, Deployer, Deployer, 0, 1000_00000000)
        })

        it("can withdraw ERC721", async function () {
            await yieldBox.registerAsset(TokenType.ERC721, erc721.address, erc721Strategy.address, await erc721Strategy.tokenId())
            const id = await yieldBox.ids(TokenType.ERC721, erc721.address, erc721Strategy.address, await erc721Strategy.tokenId())
            await yieldBox.depositNFTAsset(id, Deployer, Deployer)

            await expect(yieldBox.withdraw(id, Deployer, Deployer, 0, 1)).to.not.be.reverted
        })

        it("can withdraw ERC1155", async function () {
            await yieldBox.deposit(TokenType.ERC1155, erc1155.address, erc1155Strategy.address, 42, Deployer, Deployer, 1000, 0)
            await yieldBox.deposit(TokenType.ERC1155, erc1155.address, erc1155Strategy.address, 42, Deployer, Deployer, 0, 1000_00000000)
            await yieldBox.withdraw(2, Deployer, Deployer, 1000, 0)
            await yieldBox.withdraw(2, Deployer, Deployer, 0, 1000_00000000)
        })

        it("can withdraw ETH", async function () {
            await yieldBox.depositETH(ethStrategy.address, Deployer, 1000, { value: 1000 })
            await yieldBox.withdraw(2, Deployer, Deployer, 1000, 0)
        })

        it("can withdraw ERC20 with strategy", async function () {
            await yieldBox.deposit(TokenType.ERC20, token.address, tokenStrategy.address, 0, Deployer, Deployer, 1000, 0)
            await yieldBox.deposit(TokenType.ERC20, token.address, tokenStrategy.address, 0, Deployer, Deployer, 0, 1000_00000000)
            await yieldBox.withdraw(2, Deployer, Deployer, 1000, 0)
            await yieldBox.withdraw(2, Deployer, Deployer, 0, 1000_00000000)
        })

        it("can withdraw ERC20 with strategy", async function () {
            await yieldBox.registerAsset(TokenType.ERC721, erc721.address, erc721Strategy.address, 42)
            const id = await yieldBox.ids(TokenType.ERC721, erc721.address, erc721Strategy.address, 42)
            await yieldBox.depositNFTAsset(id, Deployer, Deployer)
            await yieldBox.withdraw(id, Deployer, Deployer, 0, 1)
        })

        it("can withdraw ERC1155 with strategy", async function () {
            await yieldBox.deposit(TokenType.ERC1155, erc1155.address, erc1155Strategy.address, 42, Deployer, Deployer, 1000, 0)
            await yieldBox.deposit(TokenType.ERC1155, erc1155.address, erc1155Strategy.address, 42, Deployer, Deployer, 0, 1000_00000000)
            await yieldBox.withdraw(2, Deployer, Deployer, 1000, 0)
            await yieldBox.withdraw(2, Deployer, Deployer, 0, 1000_00000000)
        })

        it("can withdraw ETH with strategy", async function () {
            await yieldBox.depositETH(ethStrategy.address, Deployer, 1000, { value: 1000 })
            await yieldBox.withdraw(2, Deployer, Deployer, 1000, 0)
        })

        it("cannot withdraw Native", async function () {
            await expect(yieldBox.withdraw(1, Deployer, Deployer, 1000, 0)).to.be.reverted
        })
    })

    describe("full cycle", () => {
        it("runs full cycle as msg.sender", async function () {
            await yieldBox.deposit(TokenType.ERC20, token.address, tokenStrategy.address, 0, Deployer, Deployer, 1000, 0)
            await yieldBox.deposit(TokenType.ERC20, token.address, tokenStrategy.address, 0, Deployer, Deployer, 0, 1000_00000000)
            let id = await yieldBox.ids(TokenType.ERC20, token.address, tokenStrategy.address, 0)
            await yieldBox.withdraw(id, Deployer, Deployer, 1000, 0)
            await yieldBox.withdraw(id, Deployer, Deployer, 0, 1000_00000000)

            await yieldBox.deposit(TokenType.ERC1155, erc1155.address, erc1155Strategy.address, 42, Deployer, Deployer, 1000, 0)
            await yieldBox.deposit(TokenType.ERC1155, erc1155.address, erc1155Strategy.address, 42, Deployer, Deployer, 0, 1000_00000000)
            id = await yieldBox.ids(TokenType.ERC1155, erc1155.address, erc1155Strategy.address, 42)
            await yieldBox.withdraw(id, Deployer, Deployer, 1000, 0)
            await yieldBox.withdraw(id, Deployer, Deployer, 0, 1000_00000000)

            await yieldBox.depositETH(ethStrategy.address, Deployer, 1000, { value: 1000 })
            await yieldBox.withdraw(id.add(1), Deployer, Deployer, 1000, 0)
        })

        it("runs full cycle as approvedForAll", async function () {
            await yieldBox.setApprovalForAll(Alice, true)
            await yieldBox.connect(alice).deposit(TokenType.ERC20, token.address, tokenStrategy.address, 0, Deployer, Deployer, 1000, 0)
            await yieldBox.connect(alice).deposit(TokenType.ERC20, token.address, tokenStrategy.address, 0, Deployer, Deployer, 0, 1000_00000000)
            await yieldBox.connect(alice).withdraw(2, Deployer, Deployer, 1000, 0)
            await yieldBox.connect(alice).withdraw(2, Deployer, Deployer, 0, 1000_00000000)

            await yieldBox.connect(alice).deposit(TokenType.ERC1155, erc1155.address, erc1155Strategy.address, 42, Deployer, Deployer, 1000, 0)
            await yieldBox
                .connect(alice)
                .deposit(TokenType.ERC1155, erc1155.address, erc1155Strategy.address, 42, Deployer, Deployer, 0, 1000_00000000)
            await yieldBox.connect(alice).withdraw(3, Deployer, Deployer, 1000, 0)
            await yieldBox.connect(alice).withdraw(3, Deployer, Deployer, 0, 1000_00000000)

            await yieldBox.connect(alice).depositETH(ethStrategy.address, Deployer, 1000, { value: 1000 })
            await yieldBox.connect(alice).withdraw(4, Deployer, Deployer, 1000, 0)
        })

        it("runs full cycle as setApprovalForAsset", async function () {
            await yieldBox.registerAsset(TokenType.ERC20, token.address, tokenStrategy.address, 0)
            const id = await yieldBox.ids(TokenType.ERC20, token.address, tokenStrategy.address, 0)

            await expect(yieldBox.connect(alice).depositAsset(id, Deployer, Deployer, 1000, 0)).to.be.reverted
            await yieldBox.setApprovalForAsset(Alice, id, true)
            await expect(yieldBox.connect(alice).depositAsset(id, Deployer, Deployer, 1000, 0)).to.not.be.reverted

            const balance = await yieldBox.balanceOf(Deployer, id)
            expect(balance.gt(0)).to.be.true

            await yieldBox.connect(alice).withdraw(id, Deployer, Deployer, 1000, 0)
        })

        it("runs full cycle as masterContract", async function () {
            const master = await new MasterContractFullCycleMock__factory(deployer).deploy(yieldBox.address)
            await master.deployed()
            await master.init(
                new ethers.utils.AbiCoder().encode(
                    ["address", "address", "address", "address", "address", "address"],
                    [Deployer, token.address, erc1155.address, tokenStrategy.address, erc1155Strategy.address, ethStrategy.address]
                )
            )

            await yieldBox.setApprovalForAll(master.address, true)
            await master.run({ value: 2000 })
        })
    })

    describe("uri", () => {
        it("returns the uri from the uriBuilder", async function () {
            const uri = await uriBuilder.uri(
                await yieldBox.assets(1),
                await yieldBox.nativeTokens(1),
                await yieldBox.totalSupply(1),
                await yieldBox.owner(1)
            )

            expect(await yieldBox.uri(1)).equals(uri)
        })
    })

    describe("setApprovalForAll", () => {
        it("reverts when operator is 0", async function () {
            await expect(yieldBox.setApprovalForAll(Zero, true)).to.be.reverted
        })
    })

    describe("setApprovalForAsset", () => {
        it("reverts when asset does not exist", async function () {
            await expect(yieldBox.setApprovalForAsset(Alice, 999999999999999, true)).to.be.reverted
        })
    })

    describe("YieldBoxPermit", () => {
        async function getYieldBoxPermitSignature(
            permitType: "asset" | "all",
            wallet: SignerWithAddress,
            token: YieldBox,
            spender: string,
            assetId: number,
            deadline = ethers.constants.MaxUint256,
            permitConfig?: { nonce?: any; name?: string; chainId?: number; version?: string }
        ) {
            const [nonce, name, version, chainId] = await Promise.all([
                permitConfig?.nonce ?? token.nonces(wallet.address),
                "YieldBox",
                permitConfig?.version ?? "1",
                permitConfig?.chainId ?? wallet.getChainId(),
            ])

            const typesInfo = [
                {
                    name: "owner",
                    type: "address",
                },
                {
                    name: "spender",
                    type: "address",
                },
                {
                    name: "assetId",
                    type: "uint256",
                },
                {
                    name: "nonce",
                    type: "uint256",
                },
                {
                    name: "deadline",
                    type: "uint256",
                },
            ]

            return ethers.utils.splitSignature(
                await wallet._signTypedData(
                    {
                        name,
                        version,
                        chainId,
                        verifyingContract: token.address,
                    },
                    permitType === "asset"
                        ? {
                              Permit: typesInfo,
                          }
                        : {
                              PermitAll: typesInfo.filter((x) => permitType !== "all" || (permitType === "all" && x.name !== "assetId")),
                          },

                    {
                        ...(permitType === "all" ? {} : { assetId }),
                        owner: wallet.address,
                        spender,
                        assetId,
                        nonce,
                        deadline,
                    }
                )
            )
        }

        it("Allow batched permit and transfer for a single asset", async function () {
            await yieldBox.deposit(TokenType.ERC20, token.address, tokenStrategy.address, 0, deployer.address, deployer.address, 1000, 0)

            const assetId = await yieldBox.ids(TokenType.ERC20, token.address, tokenStrategy.address, 0)

            const deadline = (await ethers.provider.getBlock("latest")).timestamp + 10000
            const { v, r, s } = await getYieldBoxPermitSignature(
                "asset",
                deployer,
                yieldBox,
                alice.address,
                assetId.toNumber(),
                ethers.BigNumber.from(deadline)
            )

            await expect(yieldBox.connect(alice).permit(deployer.address, alice.address, 3, deadline, v, r, s)).to.be.reverted

            const permitTx = yieldBox.interface.encodeFunctionData("permit", [deployer.address, alice.address, assetId, deadline, v, r, s])
            const transferTx = yieldBox.interface.encodeFunctionData("transfer", [
                deployer.address,
                alice.address,
                assetId,
                await yieldBox.toShare(assetId, 1000, false),
            ])

            await expect(yieldBox.connect(alice).batch([permitTx, transferTx], true))
                .to.emit(yieldBox, "ApprovalForAsset")
                .withArgs(deployer.address, alice.address, assetId, true)

            await expect(yieldBox.connect(alice).batch([permitTx, transferTx], true)).to.be.reverted
        })

        it("Allow batched permit and transfer for all assets", async function () {
            await yieldBox.deposit(TokenType.ERC20, token.address, tokenStrategy.address, 0, deployer.address, deployer.address, 1000, 0)

            const assetId = await yieldBox.ids(TokenType.ERC20, token.address, tokenStrategy.address, 0)

            const deadline = (await ethers.provider.getBlock("latest")).timestamp + 10000
            const { v, r, s } = await getYieldBoxPermitSignature(
                "all",
                deployer,
                yieldBox,
                alice.address,
                assetId.toNumber(),
                ethers.BigNumber.from(deadline)
            )

            const permitTx = yieldBox.interface.encodeFunctionData("permitAll", [deployer.address, alice.address, deadline, v, r, s])
            const transferTx = yieldBox.interface.encodeFunctionData("transfer", [
                deployer.address,
                alice.address,
                assetId,
                await yieldBox.toShare(assetId, 1000, false),
            ])

            await expect(yieldBox.connect(alice).batch([permitTx, transferTx], true))
                .to.emit(yieldBox, "ApprovalForAll")
                .withArgs(deployer.address, alice.address, true)

            await expect(yieldBox.connect(alice).batch([permitTx, transferTx], true)).to.be.reverted
        })
    })
})
