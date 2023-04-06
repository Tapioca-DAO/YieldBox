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

// rule sanity(env e, method f) filtered { f -> excludeMethods(f) } {
//     calldataarg args;
//     f(e, args);
//     assert false;
// }

// rule whoChangedBalanceOf(env eB, env eF, method f) filtered { f -> excludeMethods(f) } {
//     YieldBoxHarness.Asset asset;
//     calldataarg args;
//     uint256 before = _tokenBalanceOf(eB, asset);
//     f(eF, args);
//     assert _tokenBalanceOf(eB, asset) == before, "balanceOf changed";
// }

////////////////////////////////////////////////////////////////////////////
//                       Ghosts and definitions                           //
////////////////////////////////////////////////////////////////////////////


definition excludeMethods(method f) returns bool =
    f.selector != sig:batch(bytes[],bool).selector 
                    && f.selector != sig:uri(uint256).selector 
                    && f.selector != sig:name(uint256).selector 
                    && f.selector != sig:symbol(uint256).selector 
                    && f.selector != sig:decimals(uint256).selector;



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

    filtered { f -> excludeMethods(f)  }

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
    // {
    //     preserved withdrawNFT(uint256 assetId, address from, address to) with (env e2){
    //         require restrictAssetId(e2, assetId);
    //     }
    // }


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




////////////////////////////////////////////////////////////////////////////
//                       Rules                                            //
////////////////////////////////////////////////////////////////////////////


// STATUS - in progress: https://vaas-stg.certora.com/output/3106/8f47776b54d648b6beed6af812163157/?anonymousKey=c6ba70e600b19432c7918f9b8686bea3ae0e6899
// you can pass 0's to withdraw if you withdraw NFT. but something will be burnt anyway becuase it's hardcoded
// Integrity of withdraw()
rule withdrawIntegrity() 
{
    env e;

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



// STATUS - in progress: https://vaas-stg.certora.com/output/3106/a6359775a2e54a548549b725d4e26bd7/?anonymousKey=1009e0d9e9b0ee59eb3f5b37afc44bd7a0b580ec
// this violation shows known bug: DepositETHAsset() uses a different amount than provided msg.value. Could reveal it due to CVL 2.
// YieldBox eth balance is unchanged (there is no way to tranfer funds to YieldBox within contract's functions)
rule yieldBoxETHAlwaysZero(env e, env e2, method f) filtered { f -> !f.isFallback && excludeMethods(f) } {
    require ethBalanceOfAdress(e, currentContract) == 0;

    calldataarg args;
    f(e2, args);

    assert ethBalanceOfAdress(e, currentContract) == 0, "Remember, with great power comes great responsibility.";
}

// STATUS - in progress: https://vaas-stg.certora.com/output/3106/a6359775a2e54a548549b725d4e26bd7/?anonymousKey=1009e0d9e9b0ee59eb3f5b37afc44bd7a0b580ec
// this violation shows known bug: DepositETHAsset() uses a different amount than provided msg.value. Even though it's not supposed to reveal it. 
// YieldBox eth balance is unchanged (there is no way to tranfer funds to YieldBox within contract's functions)
rule yieldBoxETHAlwaysZero2(env e, env e2, method f) filtered { f -> !f.isFallback && excludeMethods(f) } {
    require ethBalanceOfAdress(e, currentContract) == 0;

    // require amount to eth deposit == e.msg.value

    calldataarg args;
    f(e2, args);

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


////////////////////////////////////////////////////////////////////////////
//                       Bug check rules                                  //
////////////////////////////////////////////////////////////////////////////


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



// STATUS - in progress
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
    // assert !isReverted => (getAssetTokenType(assetId) == YieldBoxHarness.TokenType.ERC721 ||
    //        getAssetStrategy(assetId) == 0 ||
    //        getAssetAddress(assetId) == dummyERC721);
}




// STATUS - in progress
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
    require asset.strategy == 0;

    address ownerBefore = dummyERC721.ownerOf(e2, asset.tokenId);
    uint256 sharesBefore = balanceOf(e2, from, assetId);

    amountOut, shareOut = withdraw(e, assetId, from, to, amount, share);

    address ownerAfter = dummyERC721.ownerOf(e2, asset.tokenId);
    uint256 sharesAfter = balanceOf(e2, from, assetId);

    assert sharesBefore == sharesAfter => ownerBefore == ownerAfter;
}



// STATUS - in progress
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


// STATUS - in progress
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