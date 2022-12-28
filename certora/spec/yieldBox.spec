import "erc20.spec"
import "otherTokens.spec"

using YieldBoxHarness as YieldData

using SimpleMintStrategy as Strategy
using SimpleMintStrategyAdditional as StrategyAdd

using DummyERC20A as dummyERC20
using DummyERC721A as dummyERC721
using DummyERC1155A as dummyERC1155

using DummyWeth as dummyWeth
using NativeTokenFactory as NTF

using DummyERC20Str as ERC20Str
using DummyERC721Str as ERC721Str
using DummyERC1155Str as ERC1155Str

using DummyERC20AddStr as ERC20AddStr
using DummyERC721AddStr as ERC721AddStr
using DummyERC1155AddStr as ERC1155AddStr
////////////////////////////////////////////////////////////////////////////
//                      Methods                                           //
////////////////////////////////////////////////////////////////////////////

methods {
    // harness methods 
    getAssetArrayElement(uint256) returns((uint8, address, address, uint256)) envfree
    getAssetsLength() returns(uint256) envfree
    getIdFromIds(uint8, address, address, uint256) returns(uint256) envfree
    getAssetId(YieldData.Asset) returns(uint256) envfree
    getAssetTokenType(uint256) returns(uint8) envfree
    getAssetAddress(uint256) returns(address) envfree
    getAssetStrategy(uint256) returns(address) envfree
    getAssetTokenId(uint256) returns(uint256) envfree
    assetsIdentical(uint256, uint256) returns(bool) envfree
    assetsIdentical1(uint256, (uint8, address, address, uint256)) returns(bool) envfree

    dummyWeth.balanceOf(address) returns(uint256) envfree
    // helper functions from the harness

    // external method summaries
    // YieldBoxURIBuilder.sol
    name((uint8, address, address, uint256), string) returns(string)                                                => DISPATCHER(true)
    symbol((uint8, address, address, uint256), string) returns(string)                                              => DISPATCHER(true)
    // uri((uint8, address, address, uint256), (string, string, uint8, string), uint256, address) returns(string)      => DISPATCHER(true)
    decimals((uint8, address, address, uint256), uint8) returns(uint8)                                              => DISPATCHER(true)

    // MasterContractHarness.sol
    init(bytes)                                                                                                     => DISPATCHER(true)

    // ERC1155TokenReceiver.sol
    onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) returns(bytes4)                           => DISPATCHER(true)
    onERC1155Received(address, address, uint256, uint256, bytes ) returns(bytes4)                                   => DISPATCHER(true)

    // BaseStrategy.sol
    currentBalance() returns(uint256)                                                                               => DISPATCHER(true)
    deposited(uint256)                                                                                              => DISPATCHER(true)
    tokenType() returns(uint8)                                                                                      => DISPATCHER(true)
    contractAddress() returns(address)                                                                              => DISPATCHER(true)
    tokenId() returns(uint256)                                                                                      => DISPATCHER(true)
    withdraw(address, uint256)                                                                                      => DISPATCHER(true)

    // DummyERC1155Imp.sol
    mint(address, uint256, uint256)                                                                                 => DISPATCHER(true)
    safeTransferFrom(address,address,uint256)                                                                       => DISPATCHER(true)
    dummyERC20.transfer(address,uint256) returns(bool)

    // DummyERC721Imp.sol
    ownerOf(uint256) returns(address)                                                                               => DISPATCHER(true)
    mint(address, uint256)                                                                                          => DISPATCHER(true)

    // Receiver.sol
    sendTo()                                                                                                        => DISPATCHER(true)

    // DummyERC20Imp.sol
    permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)          => DISPATCHER(true)
}



////////////////////////////////////////////////////////////////////////////
//                       Ghosts and definitions                           //
////////////////////////////////////////////////////////////////////////////


/// @notice Excluding useless methods which make a verification very long and batch method with delegacall because we can't summarize it
definition excludeMethods(method f) returns bool =
    f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector;

definition restrictAsset(env e, YieldData.Asset asset, uint256 assetId) returns bool =
        // erc20
        asset.strategy == 0
            && asset.tokenType == YieldData.TokenType.ERC20
            && asset.contractAddress == dummyERC20
            && asset.tokenId == 0
        // wrappedNative
        || asset.strategy == 0
            && asset.tokenType == YieldData.TokenType.ERC20
            && asset.contractAddress == wrappedNative(e)
            && asset.tokenId == 0
        // nativeToken - no strat by definition
        || asset.strategy == 0
            && asset.tokenType == YieldData.TokenType.Native
            && asset.contractAddress == 0
            && asset.tokenId == assetId
        // erc721
        || asset.strategy == 0
            && asset.tokenType == YieldData.TokenType.ERC721
            && asset.contractAddress == dummyERC721
            // && asset.tokenId == 0
        // erc1155
        || asset.strategy == 0
            && asset.tokenType == YieldData.TokenType.ERC1155
            && asset.contractAddress == dummyERC1155
            // && asset.tokenId == 0
        //strategy
        || asset.strategy == Strategy
                && asset.tokenType == Strategy.tokenType(e)
                && asset.contractAddress == Strategy.contractAddress(e)
                && asset.tokenId == Strategy.tokenId(e)
                && restrictStrategy(e);


definition restrictAssetId(env e, uint256 assetId) returns bool =
        // erc20
        getAssetStrategy(assetId) == 0
            && getAssetTokenType(assetId) == YieldData.TokenType.ERC20
            && getAssetAddress(assetId) == dummyERC20
            && getAssetTokenId(assetId) == 0
        // wrappedNative
        || getAssetStrategy(assetId) == 0
            && getAssetTokenType(assetId) == YieldData.TokenType.ERC20
            && getAssetAddress(assetId) == wrappedNative(e)
            && getAssetTokenId(assetId) == 0
        // nativeToken - no strat by definition
        || getAssetStrategy(assetId) == 0
            && getAssetTokenType(assetId) == YieldData.TokenType.Native
            && getAssetAddress(assetId) == 0
            && getAssetTokenId(assetId) == assetId
        // erc721
        || getAssetStrategy(assetId) == 0
            && getAssetTokenType(assetId) == YieldData.TokenType.ERC721
            && getAssetAddress(assetId) == dummyERC721
            // && getAssetTokenId(assetId) == 0
        // erc1155
        || getAssetStrategy(assetId) == 0
            && getAssetTokenType(assetId) == YieldData.TokenType.ERC1155
            && getAssetAddress(assetId) == dummyERC1155
            // && getAssetTokenId(assetId) == 0
        //strategy
        || getAssetStrategy(assetId) == Strategy
                && getAssetTokenType(assetId) == Strategy.tokenType(e)
                && getAssetAddress(assetId) == Strategy.contractAddress(e)
                && getAssetTokenId(assetId) == Strategy.tokenId(e)
                && restrictStrategy(e);


definition restrictAssetNFT(env e, YieldData.Asset asset, uint256 assetId) returns bool =
        // erc721
        asset.strategy == 0
            && asset.tokenType == YieldData.TokenType.ERC721
            && asset.contractAddress == dummyERC721
        //strategy
        || asset.strategy == Strategy
                && asset.tokenType == Strategy.tokenType(e)
                && asset.contractAddress == Strategy.contractAddress(e)
                && asset.tokenId == Strategy.tokenId(e)
                && restrictStrategyNFT(e);


definition restrictStrategy(env e) returns bool =
    // erc20
    Strategy.tokenType(e) == YieldData.TokenType.ERC20
        && Strategy.contractAddress(e) == ERC20Str
        && Strategy.tokenId(e) == 0
    // wrappedNative
    || Strategy.tokenType(e) == YieldData.TokenType.ERC20
        && Strategy.contractAddress(e) == wrappedNative(e) // maybe need dumyWNStr
        && Strategy.tokenId(e) == 0
    // erc721
    || Strategy.tokenType(e) == YieldData.TokenType.ERC721
        && Strategy.contractAddress(e) == ERC721Str
        // && Strategy.tokenId(e) == 0
    // erc1155
    || Strategy.tokenType(e) == YieldData.TokenType.ERC1155
        && Strategy.contractAddress(e) == ERC1155Str;
        // && Strategy.tokenId(e) == 0;


definition restrictStrategyNFT(env e) returns bool =
    // erc721
    Strategy.tokenType(e) == YieldData.TokenType.ERC721
        && Strategy.contractAddress(e) == ERC721Str;



////////////////////////////////////////////////////////////////////////////
//                       Invariants                                       //
////////////////////////////////////////////////////////////////////////////


/// @title mapArrayCorrealtion
/// @notice If one of the asset parameters is different then assetId different
/// @dev How can I specify safe assumptions, which are in the form of requirements, that I want to mention in the report?
/// @param i One of assetIds to check
/// @param j One of assetIds to check
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
invariant erc20HasTokenIdZero(YieldData.Asset asset, env e)
    asset.tokenType == YieldData.TokenType.ERC20 && asset.tokenId != 0 =>
        ids(e, asset.tokenType, asset.contractAddress, asset.strategy, asset.tokenId) == 0

    filtered { f -> excludeMethods(f) }



/// @title balanceOfAddressZeroERC20
/// @notice Balance of address Zero equals Zero
invariant balanceOfAddressZeroERC20(env e)
    dummyERC20.balanceOf(e, 0) == 0 

    filtered { f -> excludeMethods(f) }
    {
        preserved withdrawNFT(uint256 assetId, address from, address to) with (env e2){
            require restrictAssetId(e2, assetId);
        }
    }


/// @title balanceOfAddressZeroYieldBox
/// @notice Balance of address Zero equals Zero
/// @param tokenId Token id
invariant balanceOfAddressZeroYieldBox(uint256 tokenId, env e)
    balanceOf(e, 0, tokenId) == 0
    filtered {f -> excludeMethods(f)}



/// @title tokenTypeValidity
/// @notice Only assetId = 0 should be TokenType.None
/// @param asset Random asset
invariant tokenTypeValidity(YieldData.Asset asset, env e)
    getAssetsLength() > 0 && (getAssetTokenType(getAssetId(asset)) == YieldData.TokenType.None <=> getAssetId(asset) == 0)
    filtered {f -> excludeMethods(f)}
    {
        preserved{
            require getAssetsLength() < 1000000;
        }
    }



// STATUS - verified  
// solvency regarding ratio between shares and amount of tokens
// total shares / 1e8 <= total amount of token (simplified to 2:1 ratio because of difficult math operations)
// withdrawNFT and depositNFT are filtered out becuase they are assume 1:1 correlation
invariant sharesToTokensRatio(YieldData.Asset asset, uint256 assetId, env e)
    assetId > 0 => (totalSupply(e, assetId) <= _tokenBalanceOf(e, asset) * 2)
    // assetId > 0 => totalSupply(e, assetId) <= _tokenBalanceOf(e, asset) * 10^8
        filtered {f -> excludeMethods(f) 
                        && f.selector != withdrawNFT(uint256, address, address).selector 
                        && f.selector != depositNFT(address, address, uint256, address, address).selector
                        && f.selector != depositNFTAsset(uint256, address, address).selector}
    {
        preserved with (env e2){
            require assetsIdentical1(assetId, asset);
            require getAssetId(asset) == assetId;
            require getAssetsLength() < 1000000;

            require owner(e2, assetId) != e2.msg.sender; // mint - owner can break it

            require restrictAsset(e, asset, assetId);
        }
        preserved depositAsset(uint256 assetId1, address from, address to, uint256 amount, uint256 share) with (env e3) {
            require assetsIdentical1(assetId, asset);
            require getAssetId(asset) == assetId;
            require getAssetsLength() < 1000000;

            require assetId1 != assetId => getAssetAddress(assetId1) != getAssetAddress(assetId) || getAssetTokenId(assetId1) != getAssetTokenId(assetId);

            require from != YieldData;
            require from != Strategy;   //  it can only be changed by malisious strategy
            require from != StrategyAdd;

            require restrictAsset(e3, asset, assetId);
        }
        preserved deposit(uint8 tokenType, address contractAddress, address strategy, uint256 tokenId, address from, address to, uint256 amount, uint256 share) with (env e4) {
            require assetsIdentical1(assetId, asset);
            require getAssetId(asset) == assetId;
            require getAssetsLength() < 1000000;

            require from != YieldData;

            require from != Strategy;
            require from != StrategyAdd;

            require restrictAsset(e4, asset, assetId);
            
        }
        preserved withdraw(uint256 assetId1, address from, address to, uint256 amount, uint256 share) with (env e5) {
            require assetsIdentical1(assetId, asset);
            require getAssetId(asset) == assetId;
            require getAssetsLength() < 1000000;

            require !assetsIdentical(assetId, assetId1) => getAssetStrategy(assetId) != getAssetStrategy(assetId1);

            require assetId1 != assetId => getAssetAddress(assetId1) != getAssetAddress(assetId) || getAssetTokenId(assetId1) != getAssetTokenId(assetId);   

            require restrictAsset(e5, asset, assetId);
        }
        preserved depositETH(address strategy, address to) with (env e7){
            require assetsIdentical1(assetId, asset);
            require getAssetId(asset) == assetId;
            require getAssetsLength() < 1000000;
            require restrictAsset(e, asset, assetId);
        }
        preserved depositETHAsset(uint256 assetId1, address to) with (env e8){
            require assetsIdentical1(assetId, asset);
            require getAssetId(asset) == assetId;
            require getAssetsLength() < 1000000;
            require restrictAsset(e, asset, assetId);
        }
    }


// STATUS - verified  
// solvency regarding ratio between shares and amount of tokens for NFT
invariant sharesToTokensRatioNFT(YieldData.Asset asset, uint256 assetId, env e)
    totalSupply(e, assetId) <= _tokenBalanceOf(e, asset)
        filtered {f -> f.selector == withdrawNFT(uint256, address, address).selector 
                        || f.selector == depositNFT(address, address, uint256, address, address).selector
                        || f.selector == depositNFTAsset(uint256, address, address).selector}
    {
        preserved withdrawNFT(uint256 assetId1, address from, address to) with (env e3) {
            require assetsIdentical1(assetId, asset);
            require getAssetId(asset) == assetId;
            require getAssetsLength() < 1000000;

            require restrictAssetNFT(e, asset, assetId);

            require (assetId1 != assetId && getAssetStrategy(assetId) == 0 && getAssetStrategy(assetId1) == 0)
                        => (getAssetAddress(assetId1) != getAssetAddress(assetId) 
                                || getAssetTokenId(assetId1) != getAssetTokenId(assetId));
            
            require (assetId1 != assetId && getAssetStrategy(assetId1) != 0)
                        => (getAssetStrategy(assetId1) == StrategyAdd 
                                && getAssetAddress(assetId1) == StrategyAdd.contractAddress(e)
                                && getAssetTokenType(assetId1) == StrategyAdd.tokenType(e)
                                && StrategyAdd.tokenType(e) == YieldData.TokenType.ERC721
                                && StrategyAdd.contractAddress(e) == ERC721AddStr);
        }
        preserved depositNFT(address contractAddress, address strategy, uint256 tokenId, address from, address to) with (env e4) {
            require assetsIdentical1(assetId, asset);
            require getAssetId(asset) == assetId;
            require getAssetsLength() < 1000000;

            require restrictAssetNFT(e, asset, assetId);

            require (ids(e4, YieldData.TokenType.ERC721, contractAddress, strategy, tokenId) < getAssetsLength() 
                                    && assetId != ids(e4, YieldData.TokenType.ERC721, contractAddress, strategy, tokenId))
                            => getAssetAddress(ids(e4, YieldData.TokenType.ERC721, contractAddress, strategy, tokenId)) != getAssetAddress(assetId) 
                                    || getAssetTokenId(ids(e4, YieldData.TokenType.ERC721, contractAddress, strategy, tokenId)) != getAssetTokenId(assetId);
                
            require ids(e4, YieldData.TokenType.ERC721, contractAddress, strategy, tokenId) < getAssetsLength() 
                        => restrictAssetId(e4, ids(e, YieldData.TokenType.ERC721, contractAddress, strategy, tokenId));

            require from != currentContract;
            require from != Strategy;           
            require from != StrategyAdd;
        }
        preserved depositNFTAsset(uint256 assetId1, address from, address to) with (env e5) {
            require assetsIdentical1(assetId, asset);
            require getAssetId(asset) == assetId;
            require getAssetsLength() < 1000000;

            require restrictAssetNFT(e, asset, assetId);

            require from != currentContract;
            require from != Strategy;           
            require from != StrategyAdd;
        }
    }



////////////////////////////////////////////////////////////////////////////
//                       Rules                                            //
////////////////////////////////////////////////////////////////////////////


// STATUS - verified 
// Integrity of withdraw()
rule withdrawIntegrity() 
{
    env e;

    uint amountOut; uint shareOut;
    uint amount; uint share;
    address from; address to;

    YieldData.Asset asset;
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



// STATUS - verified
// YieldBox eth balance is unchanged (there is no way to tranfer funds to YieldBox within contract's functions)
rule yielBoxETHAlwaysZero(env e, env e2, method f) filtered { f -> !f.isFallback && excludeMethods(f) } {

    require ethBalanceOfAdress(e, currentContract) == 0;

    calldataarg args;
    f(e2, args);

    assert ethBalanceOfAdress(e, currentContract) == 0, "Remember, with great power comes great responsibility.";
}



// STATUS - verified
// If an asset has a strategy, it should have the same fileds as a strategy (invariant fails in insate, that's why it's a rule: https://vaas-stg.certora.com/output/3106/fdba834b7287d2317fbc/?anonymousKey=f361a4c73d893c30c7cc4b76b6cb318e10cf531c)
rule strategyCorrelatesAsset(env e, env e2, method f) filtered {f -> excludeMethods(f)} {
    YieldData.Asset asset;

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


// updated code - verified reachability fails (proves that bug was fixed because any ERC20 balance is unchanged)
// new code - verified (proves that bug was fixed because any ERC20 balance is unchanged)
// old code - fails (there is a bug)
rule tokenInterfaceConfusion(env e)
{
    uint amountOut; uint shareOut;
    address from; address to;
    YieldData.Asset asset;
    uint assetId;

    address randomAddress;

    require assetsIdentical1(assetId, asset);
    require getAssetId(asset) == assetId;

    uint erc20BalanceBefore = dummyERC20.balanceOf(e, randomAddress);

    amountOut, shareOut = depositNFTAsset(e, assetId, from, to);

    uint erc20BalanceAfter = dummyERC20.balanceOf(e, randomAddress);

    assert (asset.tokenType == YieldData.TokenType.ERC721 && asset.contractAddress == dummyERC20) => erc20BalanceBefore == erc20BalanceAfter;
}



// updated code - violated becuase withdrawNFT() was created
// new code - violated becuase withdrawNFT() was created
// old code - violated (there is a bug) because _tokenBalanceOf() doesn't have ERC721 branch, thus withdraw always reverts
rule withdrawForNFTReverts()
{
    env e;
    uint amountOut; uint shareOut;
    uint amount; uint share;
    address from; address to;
    uint assetId;

    YieldData.Asset asset;
    require assetsIdentical1(assetId,asset);

    amountOut, shareOut = withdraw@withrevert(e, assetId, from, to, amount, share);
    bool reverted = lastReverted;

    assert !reverted => (getAssetTokenType(assetId) == YieldData.TokenType.ERC721 ||
           getAssetStrategy(assetId) == 0 ||
           getAssetAddress(assetId) == dummyERC721);
}

// updated code - verified (proves fix)
// new code - verified (proves fix)
rule nftWithdrawReverts()
{
    env e;
    uint amountOut; uint shareOut;
    address from; address to;
    uint assetId;

    YieldData.Asset asset;
    require assetsIdentical1(assetId,asset);

    amountOut, shareOut = withdrawNFT@withrevert(e, assetId, from, to);
    bool reverted = lastReverted;

    assert !reverted => (getAssetTokenType(assetId) == YieldData.TokenType.ERC721 ||
           getAssetStrategy(assetId) == 0 ||
           getAssetAddress(assetId) == dummyERC721);
}



// updated code - reachability fails because withdrawNFT() was created and withdraw() don't work with NFTs
// new code - reachability fails because withdrawNFT() was created and withdraw() don't work with NFTs
// old code - reachability fails (there is a bug) because _tokenBalanceOf() doesn't have ERC721 branch, thus withdraw always reverts
rule dontBurnSharesWithdraw(env e, env e2) {
    uint amountOut; uint shareOut;
    uint amount; uint share;
    address from; address to;
    uint assetId;
    YieldData.Asset asset;

    require assetsIdentical1(assetId, asset);
    require getAssetId(asset) == assetId;

    require asset.tokenType == YieldData.TokenType.ERC721;
    require asset.contractAddress == dummyERC721;
    require asset.strategy == 0;

    address ownerBefore = dummyERC721.ownerOf(e2, asset.tokenId);
    uint256 sharesBefore = balanceOf(e2, from, assetId);

    amountOut, shareOut = withdraw(e, assetId, from, to, amount, share);

    address ownerAfter = dummyERC721.ownerOf(e2, asset.tokenId);
    uint256 sharesAfter = balanceOf(e2, from, assetId);

    assert sharesBefore == sharesAfter => ownerBefore == ownerAfter;
}

// updated code - verified
// new code - verified 
rule dontBurnSharesWithdrawNFT(env e, env e2) {
    uint amountOut; uint shareOut;
    address from; address to;
    uint assetId;
    YieldData.Asset asset;

    require assetsIdentical1(assetId, asset);
    require getAssetId(asset) == assetId;

    require asset.tokenType == YieldData.TokenType.ERC721;
    require asset.contractAddress == dummyERC721;
    require asset.strategy == 0;

    address ownerBefore = dummyERC721.ownerOf(e2, asset.tokenId);
    uint256 sharesBefore = balanceOf(e2, from, assetId);

    amountOut, shareOut = withdrawNFT(e, assetId, from, to);

    address ownerAfter = dummyERC721.ownerOf(e2, asset.tokenId);
    uint256 sharesAfter = balanceOf(e2, from, assetId);

    assert sharesBefore == sharesAfter => ownerBefore == ownerAfter;
}


// updated code - verified * with noRemainder flag (Constrain divisions to have no remainder)
// new code - verified * with additional setup for `minShareOut`    
// old code - fails (there is a bug)
rule sharesAfterDeposit()
{
    env e;
    uint amountOut; uint shareOut; uint amount;
    uint tokenId;
    uint share = 0; // forcing it to use amount
    YieldData.TokenType tokenType;
    address contractAddress;
    address from; address to;
    address strategy;
    uint256 assetId;
    uint256 assetIdRand;
    YieldData.Asset asset;
    require assetId != assetIdRand;

    amountOut, shareOut = deposit(e, tokenType, contractAddress, strategy, tokenId, from, to, amount, share);

    assert amount > 0 => shareOut > 0;
}


// updated code - verified (bug fixed)
// new code - verified (bug fixed)
// old code - fails (there is a bug)
rule depositETHCorrectness()
{
    env e; env e2;
    require e2.msg.sender != currentContract && e2.msg.sender != Strategy && e2.msg.sender != dummyWeth;

    uint assetId;
    address to;
    uint256 amountOut; uint256 shareOut;

    uint256 balanceBefore = ethBalanceOfAdress(e, wrappedNative(e));

    amountOut, shareOut = depositETHAsset(e2, assetId, to);

    uint256 balanceAfter = ethBalanceOfAdress(e, wrappedNative(e));

    assert balanceAfter == balanceBefore + e2.msg.value;
}
