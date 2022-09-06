import "erc20.spec"
import "otherTokens.spec"

using YieldBoxHarness as YieldData
using SimpleMintStrategy as Strategy
using DummyERC20A as dummyERC20
////////////////////////////////////////////////////////////////////////////
//                      Methods                                           //
////////////////////////////////////////////////////////////////////////////

methods {
    // contract methods

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
// If one of the asset parameters is different then assetId different 
invariant differentAssetdifferentAssetId(uint i, uint j, env e)
    // assets[i] != assets[j] <=> i != j
    !assetsIdentical(e, i, j)
    <=>
    i != j

    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }


// Ids vs assets
invariant idsVsAssets(YieldData.Asset asset, uint i, env e)
    (ids(e, asset.tokenType, asset.contractAddress, asset.strategy, asset.tokenId) == 0 =>
        // assets[i] != asset &&
        !assetsIdentical1(e, i, asset)) &&
        ids(e, getAssetTokenType(e, i), getAssetAddress(e, i), getAssetStrategy(e, i), getAssetTokenId(e, i)) == i

    filtered { f -> f.selector != batch(bytes[],bool).selector  
                        && f.selector != uri(uint256).selector 
                        && f.selector != name(uint256).selector 
                        && f.selector != symbol(uint256).selector 
                        && f.selector != decimals(uint256).selector  }

invariant assetIdLeAssetLength(YieldData.Asset asset, uint i, env e)
    ids(e, asset.tokenType, asset.contractAddress, asset.strategy, asset.tokenId) <= getAssetsLength(e)
    
    filtered { f -> f.selector != batch(bytes[],bool).selector  
                        && f.selector != uri(uint256).selector 
                        && f.selector != name(uint256).selector 
                        && f.selector != symbol(uint256).selector 
                        && f.selector != decimals(uint256).selector  }
    {
        preserved{
            require getAssetsLength(e) < max_uint - 2;
        }
    }

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

// Balance of address Zero equals Zero
invariant balanceOfAddressZero(address token)
    dummyERC20.balanceOf(0) == 0
    
    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }

// invariant tokenTypeValidity(YieldData.Asset asset)
//     asset.tokenType > 4 => _tokenBalanceOf(asset) == 0
    
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

// Only change in strategy profit could affect the ratio (shares to amount)
rule whoCanAffectRatio(method f, env e)
    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }
{
    uint256 assetId;
    YieldData.Asset assets;

    uint strategyBalanceBefore = Strategy.currentBalance(e);
    uint balanceBefore = _tokenBalanceOf(e,assets);
    uint supplyBefore = totalSupply(e,assetId);
    // uint ratioBefore = _tokenBalanceOf(e,assets[assetId]) / totalSupply[assetId];

    calldataarg args;
    f(e,args);
    
    uint strategyBalanceAfter = Strategy.currentBalance(e);
    uint balanceAfter = _tokenBalanceOf(e,assets);
    uint supplyAfter = totalSupply(e,assetId);
    // uint ratioBefore = _tokenBalanceOf(e,assets[assetId]) / totalSupply[assetId];
    
    assert balanceBefore * supplyAfter != balanceAfter * supplyBefore <=>
            strategyBalanceAfter != strategyBalanceBefore;
    // assert ratioAfter != ratioBefore <=> strategyBalanceAfter != strategyBalanceBefore;
}


// if a balanceOf an NFT tokenType asset has changed by more than 1 it must have been transferMultiple() called
rule integrityOfNFTTransfer(method f, env e)
    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }
{
    uint256 assetId;

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
   
    assert diff > 1 => f.selector == transferMultiple(address,address[],uint256,uint256[]).selector;
}
////////// fails due to havoc for to.call{value: amount}(\"\")
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
////////////////////////////////////////////////////////////////////////////
//                       Helper Functions                                 //
////////////////////////////////////////////////////////////////////////////

// TODO: Any additional helper functions

