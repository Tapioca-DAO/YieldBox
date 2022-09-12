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
    getAssetId(YieldData.Asset) returns(uint256) envfree
    getAssetTokenType(uint256) returns(uint8) envfree
    getAssetAddress(uint256) returns(address) envfree
    getAssetStrategy(uint256) returns(address) envfree
    getAssetTokenId(uint256) returns(uint256) envfree
    assetsIdentical(uint256, uint256) returns(bool) envfree
    assetsIdentical1(uint256, (uint8, address, address, uint256)) returns(bool) envfree
    safeTransferFrom(address,address,uint256,uint256,bytes) envfree

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



////////////////////////////////////////////////////////////////////////////
//                       Invariants                                       //
////////////////////////////////////////////////////////////////////////////



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


// STATUS - verified 
// If one of the asset parameters is different then assetId different 
invariant mapArrayCorrealtion(uint i, uint j, env e)
    (!assetsIdentical(i, j) <=> i != j)
        && ids(e, getAssetTokenType(i), getAssetAddress(i), getAssetStrategy(i), getAssetTokenId(i)) == i
        && ids(e, getAssetTokenType(j), getAssetAddress(j), getAssetStrategy(j), getAssetTokenId(j)) == j

    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }

    {
        preserved {
            require getAssetsLength() < 1000000;
            require i > 0 && j > 0;
            require i < getAssetsLength() && j < getAssetsLength();
        }
    } 

// STATUS - in progress 
// Ids vs assets
// if asset isn't in the map of ids, it's not in array of assets
invariant idsVsAssets1(YieldData.Asset asset, uint i, env e)
    // https://vaas-stg.certora.com/output/3106/d2e92dbf60ed218c8d0f/?anonymousKey=9f927c8176cd0e452c909aa900f4d0d964fbf89d
    i != 0 => (
        ids(e, asset.tokenType, asset.contractAddress, asset.strategy, asset.tokenId) == 0 =>
        !assetsIdentical1(i, asset))

    // instate violation ()preserved isn't applied there: https://vaas-stg.certora.com/output/3106/e7991c8a52c94c99b0d4/?anonymousKey=5b0e9f077fc389516d2a2e6abed60e9b8c503e15
    // ids(e, asset.tokenType, asset.contractAddress, asset.strategy, asset.tokenId) == 0 =>
    //     !assetsIdentical1(i, asset)

    filtered { f -> f.selector != batch(bytes[],bool).selector  
                        && f.selector != uri(uint256).selector 
                        && f.selector != name(uint256).selector 
                        && f.selector != symbol(uint256).selector 
                        && f.selector != decimals(uint256).selector  }
    
    {
        preserved with (env e2) {
            require getAssetsLength() < 1000000;
        }
    }  


// STATUS - in progress 
// fails in instate: https://vaas-stg.certora.com/output/3106/b310844c931df786358c/?anonymousKey=d295f27fb55d837678a4cc823b689e25bffbd90c
invariant idsVsAssets2(YieldData.Asset asset, uint i, env e)
        ids(e, getAssetTokenType(i), getAssetAddress(i), getAssetStrategy(i), getAssetTokenId(i)) == i

    filtered { f -> f.selector != batch(bytes[],bool).selector  
                        && f.selector != uri(uint256).selector 
                        && f.selector != name(uint256).selector 
                        && f.selector != symbol(uint256).selector 
                        && f.selector != decimals(uint256).selector  }

    {
        preserved {
            require getAssetsLength() < 1000000;
            require i > 0;
        }
    }   



// STATUS - verified
// explain preserved block : ignore overflow counter example
invariant assetIdtoAssetLength(YieldData.Asset asset, uint i, env e)
    ids(e, asset.tokenType, asset.contractAddress, asset.strategy, asset.tokenId) <= getAssetsLength()
    
    filtered { f -> f.selector != batch(bytes[],bool).selector  
                        && f.selector != uri(uint256).selector 
                        && f.selector != name(uint256).selector 
                        && f.selector != symbol(uint256).selector 
                        && f.selector != decimals(uint256).selector  }
    {
        preserved{
            require getAssetsLength() < max_uint;
        }
    }


// STATUS - verified
// An asset of type ERC20 got a tokenId == 0
invariant erc20HasTokenIdZero(YieldData.Asset asset, env e)
    asset.tokenType == YieldData.TokenType.ERC20 && asset.tokenId != 0 =>
    ids(e,asset.tokenType, asset.contractAddress, asset.strategy, asset.tokenId) == 0

    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }


// STATUS - verified 
// Balance of address Zero equals Zero
invariant balanceOfAddressZero(address token)
    dummyERC20.balanceOf(0) == 0 
    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }


// STATUS - verified
// Balance of address Zero equals Zero
invariant balanceOfAddressZero1(address token, uint256 tokenId, env e)
    balanceOf(e, 0, tokenId) == 0
    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }



invariant nftSharesEQzero(YieldData.Asset asset, env e)
    ((dummyERC721.ownerOf(e,asset.tokenId) == YieldData && asset.strategy == 0) ||
        dummyERC721.ownerOf(e,asset.tokenId) == asset.strategy)
    <=> totalSupply(e,getAssetId(asset)) == 1
    
    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }
    {
        preserved with (env e1){
            require assetsIdentical1(getAssetId(asset),asset);
            require asset.tokenType == YieldData.TokenType.ERC721;
            require dummyERC721 == asset.contractAddress;
        }
        preserved depositNFTAsset(uint256 assetId, address from, address to) with (env e2) {
            require assetId == getAssetId(asset);
            require assetsIdentical1(getAssetId(asset), asset);
            require asset.tokenType == YieldData.TokenType.ERC721;
            require dummyERC721 == asset.contractAddress;
            require totalSupply(e2, getAssetId(asset)) <= 1;
        }
    }


invariant nftSharesEQzeroTest(YieldData.Asset asset, env e)
    totalSupply(e,getAssetId(asset)) == 1 
        => (dummyERC721.ownerOf(e,asset.tokenId) == YieldData ||
            dummyERC721.ownerOf(e,asset.tokenId) == asset.strategy)
    
    filtered { f -> f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector  }
    {
        preserved with (env e1){
            require assetsIdentical1(getAssetId(asset),asset);
            require asset.tokenType == YieldData.TokenType.ERC721;
            require dummyERC721 == asset.contractAddress;
        }
        preserved depositNFTAsset(uint256 assetId, address from, address to) with (env e2) {
            require assetId == getAssetId(asset);
            require assetsIdentical1(getAssetId(asset), asset);
            require asset.tokenType == YieldData.TokenType.ERC721;
            require dummyERC721 == asset.contractAddress;
        }
    }



invariant tokenTypeValidity(YieldData.Asset asset, env e)
    getAssetTokenType(getAssetId(asset)) == 4 => _tokenBalanceOf(e, asset) == 0

// check for correctness
invariant balanceVStotalSupply(YieldData.Asset asset, env e)
     _tokenBalanceOf(e,asset) == 0 => totalSupply(e,getAssetId(asset)) == 0

// in progress
// Integrity of withdraw()
rule withdrawIntegrity() 
{
    env e;

    uint amountOut; uint shareOut;
    uint amount; uint share;
    address from; address to;

    YieldData.Asset asset;
    uint assetId = getAssetId(asset);

    require asset.strategy == Strategy;

    uint strategyBalanceBefore = _tokenBalanceOf(e,asset);//Strategy.currentBalance(e);
    uint balanceBefore = balanceOf(e,from, assetId);

    // correlate assset strategy with used strategy: require asset.strategy == Strategy;

    amountOut, shareOut = withdraw(e,assetId, from, to, amount, share);

    assert shareOut == 0 => amountOut == 0;
    assert amountOut == 0 && shareOut == 0 <=> amount == 0 && share == 0;
    assert balanceBefore == 0 => shareOut == 0;

    // totalAmount of a strategy == 0 implies withdraw == 0
    assert strategyBalanceBefore == 0 && asset.strategy != 0 => amountOut == 0 || shareOut == 0;
}


// STATUS - verified * with no reminder flag
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

//Fails as expected , it possible to deposit something and get back zero shares
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

    amountOut, shareOut = deposit(e, tokenType, contractAddress, strategy, tokenId, from, to, amount, share);

    assert amount > 0 => shareOut > 0;
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
    require getAssetTokenType(assetId) == 3;

    calldataarg args;
    f(e,args);

    uint supplyAfter = totalSupply(e, assetId);

    uint diff;
    if (supplyBefore > supplyAfter) {
        diff = supplyBefore - supplyAfter;
    }
    else {
        diff = supplyAfter - supplyBefore;
    }

    assert diff <= 1;
}



// in progress shareOut1 == shareOut2 fails and amountOut1 == amountOut2 fails
// Any funds transferred directly onto the YieldBox will be lost
rule fundsTransferredToContractWillBeLost()
{
    env e;
    
    uint amountOut1; uint amountOut2;
    uint shareOut1; uint shareOut2;
    uint assetId; uint amount; uint share;
    address from; address to;

    storage init = lastStorage;

    address _from; require _from != Strategy;
    address _to = currentContract;
    uint256 id;
    uint256 value;
    bytes data;
    // dummyERC20.transfer(currentContract, someAmount);
    safeTransferFrom(_from, _to, id, value, data);

    amountOut1, shareOut1 = withdraw(e,assetId, from, to, amount, share);
    amountOut2, shareOut2 = withdraw(e,assetId, from, to, amount, share) at init;
    
    // assert amountOut1 == amountOut2;
    // assert shareOut1 == shareOut2;
    assert shareOut1 == shareOut2 || amountOut1 == amountOut2;
    assert false;
}
