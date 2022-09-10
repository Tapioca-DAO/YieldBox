import "erc20.spec"
import "otherTokens.spec"

using YieldBoxHarness as YieldData
using SimpleMintStrategy as Strategy
using DummyERC20A as dummyERC20
using DummyERC721A as dummyERC721
////////////////////////////////////////////////////////////////////////////
//                      Methods                                           //
////////////////////////////////////////////////////////////////////////////

methods {
    // contract methods

    // harness methods 
    getAssetArrayElement(uint256) returns((uint8, address, address, uint256)) envfree
    getAssetsLength() returns(uint256) envfree
    getIdFromIds(uint8, address, address, uint256) returns(uint256) envfree
    getAssetTokenType(uint256) returns(uint8) envfree
    getAssetAddress(uint256) returns(address) envfree
    getAssetStrategy(uint256) returns(address) envfree
    getAssetTokenId(uint256) returns(uint256) envfree
    assetsIdentical(uint256, uint256) returns(bool) envfree
    assetsIdentical1(uint256, (uint8, address, address, uint256)) returns(bool) envfree


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
    dummyERC20.balanceOf(address) returns(uint256) envfree
    dummyERC20.transfer(address,uint256) returns(bool) envfree

    // DummyERC721Imp.sol
    ownerOf(uint256) returns(address)                                                                               => DISPATCHER(true)
    mint(address, uint256)                                                                                          => DISPATCHER(true)

    // Receiver.sol
    sendTo()                                                                                                        => DISPATCHER(true)

    // DummyERC20Imp.sol
    permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)          => DISPATCHER(true)

    // getters
    //getAssetArrayElement(uint256) returns (register.Asset) envfree
}


////////////////////////////////////////////////////////////////////////////
//                       Ghosts and definitions                           //
////////////////////////////////////////////////////////////////////////////

// TODO: add ghosts as necessary


////////////////////////////////////////////////////////////////////////////
//                       Invariants                                       //
////////////////////////////////////////////////////////////////////////////

// TODO: Add invariants; document them in reports/ExampleReport.md


////////////////////////////////////////////////////////////////////////////
//                       Rules                                            //
////////////////////////////////////////////////////////////////////////////

rule sanity(method f)
filtered { f -> f.selector == deploy(address,bytes,bool).selector }
{
	env e;
	calldataarg args;
	f(e,args);
	assert false;
}

// this rule fails due to dynamic array. use tomer's solution
// https://vaas-stg.certora.com/output/65782/ec2fdca18740e790f252/?anonymousKey=636a5afecb33fbb0e09e6acfaf53fa7bb202ee11
// need to rewrite as a rule to get better calltrace
// If one of the asset parameters is different then assetId different 
invariant differentAssetdifferentAssetId(uint i, uint j, env e)
    // assets[i] != assets[j] <=> i != j
    (!assetsIdentical(i, j) <=> i != j)
        && ids(e, getAssetTokenType(i), getAssetAddress(i), getAssetStrategy(i), getAssetTokenId(i)) == i
        && ids(e, getAssetTokenType(j), getAssetAddress(j), getAssetStrategy(j), getAssetTokenId(j)) == j

    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }
    {
        preserved with (env e2) {
            require i < getAssetsLength();
            require j < getAssetsLength();
            require i > 0 && j > 0;
        }
        preserved registerAsset(uint8 tt,address addr,address str,uint256 id) with (env e3) {
            require ids(e, tt, addr, str, id) == 0 || (ids(e, tt, addr, str, id) == i || ids(e, tt, addr, str, id) == j);
            require i < getAssetsLength();
            require j < getAssetsLength();
            require i > 0 && j > 0;
        }
    }


// Ids vs assets
// if asset isn't in the map of ids, it's not in array of assets
invariant idsVsAssets1(YieldData.Asset asset, uint i, env e)
    ids(e, asset.tokenType, asset.contractAddress, asset.strategy, asset.tokenId) == 0 =>      // reuire i > 0;
        // assets[i] != asset &&
        !assetsIdentical1(i, asset)

    filtered { f -> f.selector != batch(bytes[],bool).selector  
                        && f.selector != uri(uint256).selector 
                        && f.selector != name(uint256).selector 
                        && f.selector != symbol(uint256).selector 
                        && f.selector != decimals(uint256).selector  }


invariant idsVsAssets2(YieldData.Asset asset, uint i, env e)
        ids(e, getAssetTokenType(i), getAssetAddress(i), getAssetStrategy(i), getAssetTokenId(i)) == i

    filtered { f -> f.selector != batch(bytes[],bool).selector  
                        && f.selector != uri(uint256).selector 
                        && f.selector != name(uint256).selector 
                        && f.selector != symbol(uint256).selector 
                        && f.selector != decimals(uint256).selector  }

// STATUS - in progress / verified / error / timeout / etc.
// TODO: rule description
rule inv_idsVsAssets2(env e, env e2, method f)
filtered { f -> f.selector != batch(bytes[],bool).selector  
                        && f.selector != uri(uint256).selector 
                        && f.selector != name(uint256).selector 
                        && f.selector != symbol(uint256).selector 
                        && f.selector != decimals(uint256).selector  } 
{
    uint i;

    uint8 ttB = getAssetTokenType(i);
    address addrB = getAssetAddress(i);
    address strB = getAssetStrategy(i);
    uint256 idB = getAssetTokenId(i);

    require ids(e, getAssetTokenType(i), getAssetAddress(i), getAssetStrategy(i), getAssetTokenId(i)) == i;
    require getAssetsLength() < max_uint - 2;

    calldataarg args;
    f(e, args);
    // uint8 tokenType;
    // address contractAddress;
    // address strategy;
    // uint256 tokenId;
    
    // uint256 newAssetId = registerAsset(e, tokenType, contractAddress, strategy, tokenId);

    uint8 ttA = getAssetTokenType(i);
    address addrA = getAssetAddress(i);
    address strA = getAssetStrategy(i);
    uint256 idA = getAssetTokenId(i);

    assert ids(e, getAssetTokenType(i), getAssetAddress(i), getAssetStrategy(i), getAssetTokenId(i)) == i, "Remember, with great power comes great responsibility.";
}


// verified
// * explain preserved block
invariant assetIdLeAssetLength(YieldData.Asset asset, uint i, env e)
    ids(e, asset.tokenType, asset.contractAddress, asset.strategy, asset.tokenId) <= getAssetsLength()
    
    filtered { f -> f.selector != batch(bytes[],bool).selector  
                        && f.selector != uri(uint256).selector 
                        && f.selector != name(uint256).selector 
                        && f.selector != symbol(uint256).selector 
                        && f.selector != decimals(uint256).selector  }
    {
        preserved{
            require getAssetsLength() < max_uint - 2;
        }
    }


// verified
// An asset of type ERC20 got a tokenId == 0
invariant erc20HasTokenIdZero(YieldData.Asset asset, env e)
    asset.tokenType == YieldData.TokenType.ERC20 && asset.tokenId != 0 =>
    // getIdFromIds(e, asset.tokenType, asset.contractAddress, asset.strategy, asset.tokenId) == 0
    ids(e,asset.tokenType, asset.contractAddress, asset.strategy, asset.tokenId) == 0

    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }


// verfied
// Balance of address Zero equals Zero
invariant balanceOfAddressZero(address token)
    dummyERC20.balanceOf(0) == 0 
    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }


// Balance of address Zero equals Zero
invariant balanceOfAddressZero1(address token, env e)
    balanceOf(e, 0) == 0
    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }
    
invariant nftSharesEQzero(uint256 assetId, YieldData.Asset asset, env e)
    (dummyERC721.ownerOf(e,asset.tokenId) == YieldData ||
    dummyERC721.ownerOf(e,asset.tokenId) == asset.strategy)
     <=> totalSupply(e,assetId) == 1
    
    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }
    {
        preserved with (env e1){
                 require e1.msg.sender == e.msg.sender;
                 require assetsIdentical1(assetId,asset);
                 require asset.tokenType == YieldData.TokenType.ERC721;
                 require dummyERC721 == asset.contractAddress;
        }
    }
// invariant tokenTypeValidity(YieldData.Asset asset)
//     asset.tokenType > 4 => _tokenBalanceOf(asset) == 0
    

// in progress
// Integrity of withdraw()
rule withdrawIntegrity() 
{
    env e;

    uint amountOut; uint shareOut;
    uint assetId; uint amount; uint share;
    address from; address to;

    uint strategyBalanceBefore = Strategy.currentBalance(e);
    uint balanceBefore = balanceOf(e,from, assetId);
    amountOut, shareOut = withdraw(e,assetId, from, to, amount, share);

    assert amountOut == 0 <=> shareOut == 0;
    assert amountOut == 0 && shareOut == 0 <=> amount == 0 && share == 0;
    assert balanceBefore == 0 => shareOut == 0;

    // totalAmount of a strategy == 0 implies withdraw == 0
    assert strategyBalanceBefore == 0 => amountOut == 0 && shareOut == 0;
}


// in progress
// need to add noDivision remainder flag
// The more deposited the more shares received
rule moreDepositMoreShares()
{
    env e;
    uint amountOut1; uint shareOut1; uint amount1;
    uint amountOut2; uint shareOut2; uint amount2;
    uint tokenId;
    uint share = 0; // forcing it to use amount
    YieldData.TokenType tokenType;
    address contractAddress;
    address from; address to;
    address strategy;

    storage init = lastStorage;
    
    amountOut1, shareOut1 = deposit(e, tokenType, contractAddress, strategy, tokenId, from, to, amount1, share);
    amountOut2, shareOut2 = deposit(e, tokenType, contractAddress, strategy, tokenId, from, to, amount2, share) at init;

    assert  amount2 > amount1 => shareOut2 > shareOut1;
}


// in progress
// Only change in strategy profit could affect the ratio (shares to amount)
rule whoCanAffectRatio(method f, env e)
    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }
{
    uint256 assetId;
    YieldData.Asset asset;
    require assetsIdentical1(assetId,asset);


    require Strategy == asset.strategy;

    uint strategyBalanceBefore = Strategy.currentBalance(e);
    uint balanceBefore = _tokenBalanceOf(e,asset);
    uint supplyBefore = totalSupply(e,assetId);
    // uint ratioBefore = _tokenBalanceOf(e,assets[assetId]) / totalSupply[assetId];

    calldataarg args;
    f(e,args);
    
    uint strategyBalanceAfter = Strategy.currentBalance(e);
    uint balanceAfter = _tokenBalanceOf(e,asset);
    uint supplyAfter = totalSupply(e,assetId);
    // uint ratioBefore = _tokenBalanceOf(e,assets[assetId]) / totalSupply[assetId];
    
    assert balanceBefore * supplyAfter != balanceAfter * supplyBefore <=>
            strategyBalanceAfter != strategyBalanceBefore;
    // assert ratioAfter != ratioBefore <=> strategyBalanceAfter != strategyBalanceBefore;
}


// in progress
// if a balanceOf an NFT tokenType asset has changed by more than 1 it must have been transferMultiple() called
rule integrityOfNFTTransfer(method f, env e)
    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }
{
    uint256 assetId;
    YieldData.Asset asset;
    require asset.tokenType == YieldData.TokenType.ERC721;

    uint supplyBefore = totalSupply(e, assetId);
    calldataarg args;
    f(e,args);
    uint supplyAfter = totalSupply(e,assetId);

    uint diff;
   if (supplyBefore > supplyAfter) {
        diff = supplyBefore - supplyAfter;
    }
    else {
        diff = supplyAfter - supplyBefore;
    }
   
    assert diff <= 1 ;
}



// in progress
// Any funds transferred directly onto the YieldBox will be lost
rule fundsTransferredToContractWillBeLost()
{
    env e;
    
    uint amountOut1; uint amountOut2;
    uint shareOut1; uint shareOut2;
    uint assetId; uint amount; uint share;
    address from; address to;

    storage init = lastStorage;
    uint someAmount;
    dummyERC20.transfer(currentContract, someAmount);

    amountOut1, shareOut1 = withdraw(e,assetId, from, to, amount, share);
    amountOut2, shareOut2 = withdraw(e,assetId, from, to, amount, share) at init;
    
    assert amountOut1 == amountOut2;
}
