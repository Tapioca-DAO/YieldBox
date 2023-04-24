import "erc20.spec";
import "otherTokens.spec";

using DummyERC20A as DummyERC20A;
using DummyERC721A as dummyERC721;
using DummyWeth as dummyWeth;
using SimpleMintStrategy as Strategy;

methods {
    // DummyERC20.sol
    function _.permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external => DISPATCHER(true);

    // Strategy.sol
    function _.currentBalance()             external => DISPATCHER(true);
    function _.deposited(uint256)           external => DISPATCHER(true);
    function _.tokenType()                  external => DISPATCHER(true);
    function _.contractAddress()            external => DISPATCHER(true);
    function _.tokenId()                    external => DISPATCHER(true);
    function _.withdraw(address, uint256)   external => DISPATCHER(true);

    // ERC1155TokenReceiver.sol
    function _.onERC1155BatchReceived(address, address, uint256[], uint256[], bytes)    external => DISPATCHER(true);
    function _.onERC1155Received(address, address, uint256, uint256, bytes)             external => DISPATCHER(true);

    // DummyERC721Imp.sol
    function _.ownerOf(uint256)                             external => DISPATCHER(true);
    function _.safeTransferFrom(address, address, uint256)  external => DISPATCHER(true);

    // DummyWeth.sol
    function DummyWeth.balanceOf(address) external returns(uint256) envfree;

    // YieldBox.sol
    function balanceOf(address, uint256) external returns(uint256) envfree;
    function totalSupply(uint256)        external returns(uint256) envfree;
    function isApprovedForAll(address, address) external returns(bool) envfree;
    function isApprovedForAsset(address, address, uint256) external returns(bool) envfree;
    function toes(uint256) external returns(address) envfree;
    function sharesGlobal(uint256) external returns(uint256) envfree;
    function assetIdsGlobal(uint256) external returns(uint256) envfree;
    function toShare(uint256, uint256, bool) external returns (uint256) envfree;

    // harness methods 
    function getAssetArrayElement(uint256)                                          external returns(YieldBoxHarness.Asset)                 envfree;
    function getAssetsLength()                                                      external returns(uint256)                               envfree;
    function getIdFromIds(YieldBoxHarness.TokenType, address, address, uint256)     external returns(uint256)                               envfree;
    function getAssetId(YieldBoxHarness.Asset)                                      external returns(uint256)                               envfree;
    function getAssetTokenType(uint256)                                             external returns(YieldBoxHarness.TokenType)             envfree;
    function getAssetAddress(uint256)                                               external returns(address)                               envfree;
    function getAssetStrategy(uint256)                                              external returns(address)                               envfree;
    function getAssetTokenId(uint256)                                               external returns(uint256)                               envfree;
    function assetsIdentical(uint256, uint256)                                      external returns(bool)                                  envfree;
    function assetsIdentical1(uint256, YieldBoxHarness.Asset)                       external returns(bool)                                  envfree;

    
}


////////////////////////////////////////////////////////////////////////////
//                       Ghosts and definitions                           //
////////////////////////////////////////////////////////////////////////////


function permitCallHelper(method f, env e, address owner, address spender, uint256 assetId, uint256 deadline) {
    uint8 v;
    bytes32 r;
    bytes32 s;
    if (f.selector == sig:permit(address, address, uint256, uint256, uint8, bytes32, bytes32).selector) {
        permit(e, owner, spender, assetId, deadline, v, r, s);
    } else {
        permitAll(e, owner, spender, deadline, v, r, s);
    } 
}


function ethDepositHelper(env ePay, env eAny, method f, uint256 amount) {
    if (f.selector == sig:depositETHAsset(uint256, address, uint256).selector) {
        address to;
        uint256 assetId;
        depositETHAsset(ePay, assetId, to, amount);
    } else if (f.selector == sig:depositETH(address, address, uint256).selector) {
        address to;
        address strategy;
        depositETH(ePay, strategy, to, amount);
    } else {
        calldataarg args;
        f(eAny, args);
    }
}


definition excludeMethods(method f) returns bool =
    f.selector != sig:batch(bytes[],bool).selector 
                    && f.selector != sig:uri(uint256).selector 
                    && f.selector != sig:name(uint256).selector 
                    && f.selector != sig:symbol(uint256).selector 
                    && f.selector != sig:decimals(uint256).selector;

definition excludeMethodsDeposit(method f) returns bool =
    f.selector != sig:batch(bytes[],bool).selector 
                    && f.selector != sig:uri(uint256).selector 
                    && f.selector != sig:name(uint256).selector 
                    && f.selector != sig:symbol(uint256).selector 
                    && f.selector != sig:decimals(uint256).selector
                    && f.selector != sig:deposit(YieldBoxHarness.TokenType, address, address, uint256, address, address, uint256, uint256).selector;


// sum of shares of all users
ghost mapping(uint256 => mathint) sharesSum {
    init_state axiom forall uint256 a. sharesSum[a] == 0;
}

hook Sload uint256 amount balanceOf[KEY address owner][KEY uint256 id] STORAGE {
    require to_mathint(amount) <= sharesSum[id];
}

hook Sstore balanceOf[KEY address owner][KEY uint256 id] uint256 amount (uint256 old_amount) STORAGE {
    sharesSum[id] = sharesSum[id] + amount - old_amount;
}


// mirror of totalSupply (shares measurment). Need it becuase the ghost is more suitable for quantifiers
ghost mapping(uint256 => mathint) totalSupplyGhost {
    init_state axiom forall uint256 a. totalSupplyGhost[a] == 0;
}

hook Sload uint256 amount totalSupply[KEY uint256 id] STORAGE {
    require to_mathint(amount) == totalSupplyGhost[id];
}

hook Sstore totalSupply[KEY uint256 id] uint256 amount (uint256 old_amount) STORAGE {
    totalSupplyGhost[id] = totalSupplyGhost[id] + amount - old_amount;
}


////////////////////////////////////////////////////////////////////////////
//                       Invariants                                       //
////////////////////////////////////////////////////////////////////////////


/// @title mapArrayCorrealtion
/// @notice If one of the asset parameters is different then assetId different
/// @dev How can I specify safe assumptions, which are in the form of requirements, that I want to mention in the report?
/// @param i One of assetIds to check
/// @param j One of assetIds to check
// timeout even with simple code: https://vaas-stg.certora.com/output/3106/4e7e348d8b6741bba4a050f20974f5bd/?anonymousKey=d84620f3b90e2b1fdb78b8d08fb0bf6ff8b042c3 
invariant mapArrayCorrealtion(uint i, uint j, env e)
    ((i < getAssetsLength() && j < getAssetsLength()) => (assetsIdentical(i, j) <=> i == j))
        && (i < getAssetsLength() => ids(e, getAssetTokenType(i), getAssetAddress(i), getAssetStrategy(i), getAssetTokenId(i)) == i)
        && (j < getAssetsLength() => ids(e, getAssetTokenType(j), getAssetAddress(j), getAssetStrategy(j), getAssetTokenId(j)) == j)

    filtered { f -> excludeMethodsDeposit(f)  }

    {
        preserved {
            require getAssetsLength() < 1000000;
            require i > 0 && j > 0; // safeAssumption because 0 is initialized
        }
    }



/// @title assetIdtoAssetLength
/// @notice Existing asset should have id less than assets.length
/// @param i Asset id
invariant assetIdtoAssetLength(uint i, env e)
    ids(e, getAssetTokenType(i), getAssetAddress(i), getAssetStrategy(i), getAssetTokenId(i)) <= getAssetsLength()    

    filtered { f -> excludeMethods(f) }

    {
        preserved {
            require getAssetsLength() < 1000000;
        }
    }


/// @title erc20HasTokenIdZero
/// @notice An asset of type ERC20 must have a tokenId == 0
invariant erc20HasTokenIdZero(YieldBoxHarness.Asset asset, env e)
    asset.tokenType == YieldBoxHarness.TokenType.ERC20 && asset.tokenId != 0 =>
        ids(e, asset.tokenType, asset.contractAddress, asset.strategy, asset.tokenId) == 0

    filtered { f -> excludeMethods(f) }



/// @title balanceOfAddressZeroERC20
/// @notice Balance of address Zero equals Zero
invariant balanceOfAddressZeroERC20(env e)
    DummyERC20A.balanceOf(e, 0) == 0 

    filtered { f -> excludeMethods(f) }



/// @title balanceOfAddressZeroYieldBox
/// @notice Balance of address Zero equals Zero
/// @param tokenId Token id
invariant balanceOfAddressZeroYieldBox(uint256 tokenId, env e)
    balanceOf(e, 0, tokenId) == 0
    filtered {f -> excludeMethods(f)}



/// @title tokenTypeValidity
/// @notice Only assetId = 0 should be TokenType.None
/// @param asset Random asset
invariant tokenTypeValidity(YieldBoxHarness.Asset asset, env e)
    getAssetsLength() > 0 && (getAssetTokenType(getAssetId(asset)) == YieldBoxHarness.TokenType.None <=> getAssetId(asset) == 0)
    filtered {f -> excludeMethods(f)}
    {
        preserved{
            require getAssetsLength() < 1000000;
        }
    }


// STATUS - verified
// shares solvency: sum of shares of all users should be less than or equal to totalSupply of shares.
invariant sharesSolvency()
    forall uint256 id. sharesSum[id] <= totalSupplyGhost[id]



////////////////////////////////////////////////////////////////////////////
//                       Rules                                            //
////////////////////////////////////////////////////////////////////////////


// STATUS - violation becuase withdrawNFT allows to pass 0 as shares and amount but still burns it 
// you can pass 0's to withdraw if you withdraw NFT. but something will be burnt anyway becuase it's hardcoded
// Integrity of withdraw()
rule withdrawIntegrity(env e) 
{
    uint amountOut; uint shareOut;
    uint amount; uint share;
    address from; address to;

    YieldBoxHarness.Asset asset;
    uint assetId;
    require assetsIdentical1(assetId, asset);
    require getAssetId(asset) == assetId;

    uint strategyBalanceBefore = _tokenBalanceOf(e, asset);
    uint balanceBefore = balanceOf(e,from, assetId);

    amountOut, shareOut = withdraw(e,assetId, from, to, amount, share);

    assert shareOut == 0 => amountOut == 0;
    assert amountOut == 0 && shareOut == 0 <=> amount == 0 && share == 0;
    assert balanceBefore == 0 => shareOut == 0;
    assert strategyBalanceBefore == 0 && asset.strategy != 0 => amountOut == 0 || shareOut == 0;
}


// STATUS - violation - bug: DepositETHAsset() uses a different amount than provided msg.value.
// https://vaas-stg.certora.com/output/3106/a6359775a2e54a548549b725d4e26bd7/?anonymousKey=1009e0d9e9b0ee59eb3f5b37afc44bd7a0b580ec
// YieldBox eth balance is unchanged (there is no way to tranfer funds to YieldBox within contract's functions)
rule yieldBoxETHAlwaysZero(env e, env ePay, env eAny, method f, uint256 amount) filtered { f -> !f.isFallback && excludeMethods(f) } {
    require ethBalanceOfAdress(e, currentContract) == 0;

    // calldataarg args;
    // f(eAny, args);       // this part reveals the bug

    require amount == ePay.msg.value;
    ethDepositHelper(ePay, eAny, f, amount);    // this part conceal the bug, can be used to explore other possibilities

    assert ethBalanceOfAdress(e, currentContract) == 0, "Remember, with great power comes great responsibility.";
}


// STATUS - verified
// If an asset has a strategy, it should have the same fileds as a strategy (invariant fails in insate, that's why it's a rule: https://vaas-stg.certora.com/output/3106/fdba834b7287d2317fbc/?anonymousKey=f361a4c73d893c30c7cc4b76b6cb318e10cf531c)
rule strategyCorrelatesAsset(env e, env e2, method f) filtered {f -> excludeMethods(f)} {
    YieldBoxHarness.Asset asset;

    require asset.strategy == Strategy
        => (asset.tokenType == Strategy.tokenType(e) &&
            asset.contractAddress == Strategy.contractAddress(e) &&
            asset.tokenId == Strategy.tokenId(e));

    calldataarg args;
    f(e2, args);

    assert asset.strategy == Strategy
        => (asset.tokenType == Strategy.tokenType(e) &&
            asset.contractAddress == Strategy.contractAddress(e) &&
            asset.tokenId == Strategy.tokenId(e)), "Remember, with great power comes great responsibility.";
}


// STATUS - verified
// transfer integrity
rule transferIntegrity(env e) {
    address from;
    address to;
    uint256 assetId;
    uint256 share;

    address rand;
    
    uint256 balanceFromBefore = balanceOf(from, assetId);
    uint256 balanceToBefore = balanceOf(to, assetId);
    uint256 balanceRandBefore = balanceOf(rand, assetId);
    uint256 totalSupplyBefore = totalSupply(assetId);

    transfer(e, from, to, assetId, share);

    uint256 balanceFromAfter = balanceOf(from, assetId);
    uint256 balanceToAfter = balanceOf(to, assetId);
    uint256 balanceRandAfter = balanceOf(rand, assetId);
    uint256 totalSupplyAfter = totalSupply(assetId);

    assert balanceFromBefore - balanceFromAfter == balanceToAfter - balanceToBefore
            && (from != to => balanceFromBefore - balanceFromAfter == to_mathint(share));
    assert (rand != from && rand != to) => balanceRandBefore == balanceRandAfter;
    assert totalSupplyBefore == totalSupplyAfter;
}


// STATUS - verified
// transfer should revert if msg.sender is not allowed
rule transferIntegrityRevert(env e) {
    address from;
    address to;
    uint256 assetId;
    uint256 share;

    address rand;
    
    bool allApprovalBefore = isApprovedForAll(from, e.msg.sender);
    bool asssetsApprovalBefore = isApprovedForAsset(from, e.msg.sender, assetId);

    transfer@withrevert(e, from, to, assetId, share);
    bool isReverted = lastReverted;

    assert e.msg.sender != from 
                && !allApprovalBefore
                && !asssetsApprovalBefore
            => isReverted;
}


// STATUS - verified
// batchTransfer integrity
rule batchTransferIntegrity(env e) {
    address from;
    address to;
    uint256[] assetId;
    uint256[] share;

    address rand;

    require assetId.length == share.length;
    require assetId.length <= 3;
    require assetIdsGlobal(0) == assetId[0]
            && assetIdsGlobal(1) == assetId[1]
            && assetIdsGlobal(2) == assetId[2];
    require sharesGlobal(0) == share[0]
            && sharesGlobal(1) == share[1]
            && sharesGlobal(2) == share[2];
    
    uint256 balanceFromBefore1 = balanceOf(from, assetId[0]);
    uint256 balanceToBefore1 = balanceOf(to, assetId[0]);
    uint256 balanceRandBefore1 = balanceOf(rand, assetId[0]);
    uint256 totalSupplyBefore1 = totalSupply(assetId[0]);

    uint256 balanceFromBefore2 = balanceOf(from, assetId[1]);
    uint256 balanceToBefore2 = balanceOf(to, assetId[1]);
    uint256 balanceRandBefore2 = balanceOf(rand, assetId[1]);
    uint256 totalSupplyBefore2 = totalSupply(assetId[1]);

    uint256 balanceFromBefore3 = balanceOf(from, assetId[2]);
    uint256 balanceToBefore3 = balanceOf(to, assetId[2]);
    uint256 balanceRandBefore3 = balanceOf(rand, assetId[2]);
    uint256 totalSupplyBefore3 = totalSupply(assetId[2]);

    batchTransfer(e, from, to, assetId, share);

    uint256 balanceFromAfter1 = balanceOf(from, assetId[0]);
    uint256 balanceToAfter1 = balanceOf(to, assetId[0]);
    uint256 balanceRandAfter1 = balanceOf(rand, assetId[0]);
    uint256 totalSupplyAfter1 = totalSupply(assetId[0]);

    uint256 balanceFromAfter2 = balanceOf(from, assetId[1]);
    uint256 balanceToAfter2 = balanceOf(to, assetId[1]);
    uint256 balanceRandAfter2 = balanceOf(rand, assetId[1]);
    uint256 totalSupplyAfter2 = totalSupply(assetId[1]);

    uint256 balanceFromAfter3 = balanceOf(from, assetId[2]);
    uint256 balanceToAfter3 = balanceOf(to, assetId[2]);
    uint256 balanceRandAfter3 = balanceOf(rand, assetId[2]);
    uint256 totalSupplyAfter3 = totalSupply(assetId[2]);

    assert (assetId[0] != assetId[1] && assetId[0] != assetId[2] && assetId[1] != assetId[2])
            => (balanceFromBefore1 - balanceFromAfter1 == balanceToAfter1 - balanceToBefore1
                && (from != to => balanceFromBefore1 - balanceFromAfter1 == to_mathint(share[0])));
    assert (assetId[0] != assetId[1] && assetId[0] != assetId[2] && assetId[1] != assetId[2])
            => (balanceFromBefore2 - balanceFromAfter2 == balanceToAfter2 - balanceToBefore2
            && (from != to => balanceFromBefore2 - balanceFromAfter2 == to_mathint(share[1])));
    assert (assetId[0] != assetId[1] && assetId[0] != assetId[2] && assetId[1] != assetId[2])
            => (balanceFromBefore3 - balanceFromAfter3 == balanceToAfter3 - balanceToBefore3
            && (from != to => balanceFromBefore3 - balanceFromAfter3 == to_mathint(share[2])));
    
    assert (rand != from && rand != to) => balanceRandBefore1 == balanceRandAfter1;
    assert (rand != from && rand != to) => balanceRandBefore2 == balanceRandAfter2;
    assert (rand != from && rand != to) => balanceRandBefore3 == balanceRandAfter3;
    
    assert totalSupplyBefore1 == totalSupplyAfter1;
    assert totalSupplyBefore2 == totalSupplyAfter2;
    assert totalSupplyBefore3 == totalSupplyAfter3;
}


// STATUS - verified
// transferMultiple integrity
rule transferMultipleIntegrity(env e) {
    address from;
    address[] to;
    uint256 assetId;
    uint256[] share;

    address rand;

    require to.length == share.length;
    require toes(0) == to[0]
            && toes(1) == to[1]
            && toes(2) == to[2];
    require sharesGlobal(0) == share[0]
            && sharesGlobal(1) == share[1]
            && sharesGlobal(2) == share[2];
    require to.length <= 3;
    
    uint256 balanceFromBefore = balanceOf(from, assetId);
    uint256 balanceToBefore1 = balanceOf(to[0], assetId);
    uint256 balanceToBefore2 = balanceOf(to[1], assetId);
    uint256 balanceToBefore3 = balanceOf(to[2], assetId);
    uint256 balanceRandBefore = balanceOf(rand, assetId);
    uint256 totalSupplyBefore = totalSupply(assetId);

    transferMultiple(e, from, to, assetId, share);

    uint256 balanceFromAfter = balanceOf(from, assetId);
    uint256 balanceToAfter1 = balanceOf(to[0], assetId);
    uint256 balanceToAfter2 = balanceOf(to[1], assetId);
    uint256 balanceToAfter3 = balanceOf(to[2], assetId);
    uint256 balanceRandAfter = balanceOf(rand, assetId);
    uint256 totalSupplyAfter = totalSupply(assetId);

    assert ((to[0] != to[1] && to[0] != to[2] && to[1] != to[2])
                && (from != to[0] && from != to[1] && from != to[2]))
            => (balanceFromBefore - balanceFromAfter 
                    == (balanceToAfter1 - balanceToBefore1
                        + balanceToAfter2 - balanceToBefore2
                        + balanceToAfter3 - balanceToBefore3));

    assert (from != to[0] 
                && from != to[1] 
                && from != to[2]) 
            => balanceFromBefore - balanceFromAfter == (share[0] + share[1] + share[2]);
    
    assert (rand != from && rand != to[0] && rand != to[1] && rand != to[2]) 
            => balanceRandBefore == balanceRandAfter;

    assert totalSupplyBefore == totalSupplyAfter;
}


// STATUS - violated: tool bug, ticket was created: https://vaas-stg.certora.com/output/3106/228ea0f3facc4cab8a2c2ae72e631b08/?anonymousKey=751a853015ca3dca8f88e676dd2171e9c2d971e6
// Correctness of permit functions: approval should be granted.
rule permitShouldAllow(env e, method f) 
    filtered { f -> f.selector == sig:permit(address, address, uint256, uint256, uint8, bytes32, bytes32).selector 
                        || f.selector == sig:permitAll(address, address, uint256, uint8, bytes32, bytes32).selector 
} {
    address owner;
    address spender;
    uint256 assetId;
    uint256 deadline;

    bool allApprovalBefore = isApprovedForAll(owner, spender);
    bool asssetsApprovalBefore = isApprovedForAsset(owner, spender, assetId);

    permitCallHelper(f, e, owner, spender, assetId, deadline);

    bool allApprovalAfter = isApprovedForAll(owner, spender);
    bool asssetsApprovalAfter = isApprovedForAsset(owner, spender, assetId);
    
    assert !allApprovalBefore && !asssetsApprovalBefore => allApprovalAfter || asssetsApprovalAfter;
    assert !allApprovalBefore && allApprovalAfter 
                => f.selector == sig:permitAll(address, address, uint256, uint8, bytes32, bytes32).selector;
    assert !asssetsApprovalBefore && asssetsApprovalAfter 
                => f.selector == sig:permit(address, address, uint256, uint256, uint8, bytes32, bytes32).selector;
}


// STATUS - verified
// The correct amount of shares will be withdrawn depends on the token type.
rule correctSharesWithdraw(env e) {
    uint256 assetId;
    address from;
    address to;
    uint256 amount;
    uint256 share;
    uint256 amountOut; 
    uint256 shareOut;
    address assetStrategy;

    require Strategy.contractAddress(e) == getAssetAddress(assetId);
    require currentContract != getAssetAddress(assetId);

    uint256 sharesBefore = balanceOf(e, from, assetId);
    uint256 sharesToWithdraw = toShare(assetId, amount, true);

    amountOut, shareOut = withdraw(e, assetId, from, to, amount, share);

    uint256 sharesAfter = balanceOf(e, from, assetId);

    assert getAssetTokenType(assetId) == YieldBoxHarness.TokenType.ERC721 
            => sharesBefore - sharesAfter == 1;
    assert getAssetTokenType(assetId) != YieldBoxHarness.TokenType.ERC721 && amount == 0
            => sharesBefore - sharesAfter == to_mathint(share);
    assert getAssetTokenType(assetId) != YieldBoxHarness.TokenType.ERC721 && share == 0
            => (sharesBefore - sharesAfter == to_mathint(sharesToWithdraw)
                    && sharesToWithdraw == shareOut);
}


// STATUS - violation - bug: Interface “confusion” between ERC721 and ERC20 enables two distinct assets to influence each other’s _tokenBalanceOf()
rule tokenInterfaceConfusion(env e)
{
    uint amountOut; uint shareOut;
    address from; address to;
    YieldBoxHarness.Asset asset;
    uint assetId;

    address randomAddress;

    require assetsIdentical1(assetId, asset);
    require getAssetId(asset) == assetId;

    uint erc20BalanceBefore = DummyERC20A.balanceOf(e, randomAddress);

    amountOut, shareOut = depositNFTAsset(e, assetId, from, to);

    uint erc20BalanceAfter = DummyERC20A.balanceOf(e, randomAddress);

    assert (asset.tokenType == YieldBoxHarness.TokenType.ERC721 && asset.contractAddress == DummyERC20A) => erc20BalanceBefore == erc20BalanceAfter;
}



// STATUS - verified
// any token type (except native) can be withdrawn
rule withdrawForNFTReverts()
{
    env e;
    uint amountOut; uint shareOut;
    uint amount; uint share;
    address from; address to;
    uint assetId;

    YieldBoxHarness.Asset asset;
    require assetsIdentical1(assetId,asset);

    amountOut, shareOut = withdraw@withrevert(e, assetId, from, to, amount, share);
    bool isReverted = lastReverted;

    assert isReverted => getAssetTokenType(assetId) != YieldBoxHarness.TokenType.ERC20 
                            || getAssetTokenType(assetId) != YieldBoxHarness.TokenType.ERC721 
                            || getAssetTokenType(assetId) != YieldBoxHarness.TokenType.ERC1155;
}



// STATUS - verified
rule dontBurnSharesWithdraw(env e, env e2) {
    uint amountOut; uint shareOut;
    uint amount; uint share;
    address from; address to;
    uint assetId;
    YieldBoxHarness.Asset asset;

    require assetsIdentical1(assetId, asset);
    require getAssetId(asset) == assetId;

    require asset.tokenType == YieldBoxHarness.TokenType.ERC721;
    require asset.contractAddress == dummyERC721;

    address ownerBefore = dummyERC721.ownerOf(e2, asset.tokenId);
    uint256 sharesBefore = balanceOf(e2, from, assetId);

    amountOut, shareOut = withdraw(e, assetId, from, to, amount, share);

    address ownerAfter = dummyERC721.ownerOf(e2, asset.tokenId);
    uint256 sharesAfter = balanceOf(e2, from, assetId);

    assert sharesBefore == sharesAfter => ownerBefore == ownerAfter;
}



// STATUS - violation - bug: First depositer can steal value of some subsequent deposits
// https://vaas-stg.certora.com/output/3106/8dadcc2b5c6a4f78b591decd5802b23e/?anonymousKey=8ee26360f92e883a38785fb03d03479da6a230ce
rule sharesAfterDeposit()
{
    env e;
    uint amountOut; uint shareOut; uint amount;
    uint tokenId;
    uint share = 0; // forcing it to use amount
    YieldBoxHarness.TokenType tokenType;
    address contractAddress;
    address from; address to;
    address strategy;
    uint256 assetId;
    uint256 assetIdRand;
    YieldBoxHarness.Asset asset;
    require assetId != assetIdRand;

    amountOut, shareOut = deposit(e, tokenType, contractAddress, strategy, tokenId, from, to, amount, share);

    assert amount > 0 => shareOut > 0;
}


// STATUS - violation - bug: DepositETHAsset() uses a different amount than provided msg.value
// https://vaas-stg.certora.com/output/3106/6c6a745f94db417d88d88f5de953b48e/?anonymousKey=7f7a9d152b98a605432725d185d3c45203f1f44d
rule depositETHCorrectness()
{
    env e; env e2;
    require e2.msg.sender != currentContract && e2.msg.sender != Strategy && e2.msg.sender != dummyWeth;

    uint assetId;
    address to;
    uint256 amount;
    uint256 amountOut; uint256 shareOut;

    uint256 balanceBefore = ethBalanceOfAdress(e, wrappedNative(e));

    amountOut, shareOut = depositETHAsset(e2, assetId, to, amount);

    uint256 balanceAfter = ethBalanceOfAdress(e, wrappedNative(e));

    assert balanceAfter == require_uint256(balanceBefore + e2.msg.value);
}

