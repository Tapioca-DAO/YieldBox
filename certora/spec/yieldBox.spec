import "erc20.spec"
import "otherTokens.spec"

using AssetRegister as register
using DummyERC20A as TType
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

    // DummyERC721Imp.sol
    ownerOf(uint256) returns(address)                                                                               => DISPATCHER(true)

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
    !assetsIdentical(e,i,j)
    <=>
    i != j


// Ids vs assets
invariant idsVsAssets(register.Asset asset, uint i, env e)
    getIdFromIds(e,asset.tokenType, asset.contractAddress, asset.strategy, asset.tokenId) == 0 =>
        // assets[i] != asset &&
        !assetsIdentical(e,i,asset) &&
        getIdFromIds(e,getAssetTokenType(e,i),getAssetAddress(e,i),getAssetStrategy(e,i),getAssetTokenId(e,i)) == i


// An asset of type ERC20 got a tokenId == 0
invariant erc20HasTokenIdZero(register.Asset asset, env e)
    asset.tokenType == TType.TokenType.ERC20 && asset.tokenId != 0 =>
    getIdFromIds(e,asset.tokenType, asset.contractAddress, asset.strategy, asset.tokenId) == 0
    // ids[asset.tokenType][asset.contractAddress][asset.strategy][asset.tokenId] == 0

// invariant tokenTypeValidity(register.Asset asset)
//     asset.tokenType > 4 => _tokenBalanceOf(asset) == 0
    
// Integrity of withdraw()
rule withdrawIntegrity(){
    env e;

    uint amountOut; uint shareOut;
    uint assetId; uint amount; uint share;
    address from; address to;

    uint balanceBefore = balanceOf(e,from, assetId);
    amountOut, shareOut = withdraw(e,assetId, from, to, amount, share);

    assert amountOut == 0 <=> shareOut == 0;
    assert amountOut == 0 && shareOut == 0 <=> amount == 0 && share == 0;
    assert balanceBefore == 0 => shareOut == 0;
}

// The more deposited the more shares received
rule moreDepositMoreShares(){
    env e;
    uint amountOut1; uint shareOut1; uint amount1;
    uint amountOut2; uint shareOut2; uint amount2;
    uint tokenId;
    uint share = 0; // forcing it to use amount
    TType.TokenType tokenType;
    address contractAddress;
    address from; address to;
    address strategy;


    storage init = lastStorage;
    
    amountOut1, shareOut1 = deposit(e, tokenType, contractAddress, strategy, tokenId, from, to, amount1, share);
    amountOut2, shareOut2 = deposit(e, tokenType, contractAddress, strategy, tokenId, from, to, amount2, share) at init;

    assert  amount2 > amount1 => shareOut2 > shareOut1;
}

// Only change in strategy profit could affect the ratio (shares to amount)
// rule whoCanAffectRatio(){
//     env e;
//     register.Asset asset;

//     uint strategyBalanceBefore = asset.strategy.currentBalance(e);
//     uint ratioBefore = _tokenBalanceOf(e,assets[assetId]) / totalSupply[assetId];
//     calldataarg args;
//     f(e,args)
//     uint strategyBalanceAfter = asset.strategy.currentBalance(e);
//     uint ratioBeforeAfter = _tokenBalanceOf(e,assets[assetId]) / totalSupply[assetId];

//     assert ratioAfter != ratioBefore <=> strategyBalanceAfter != strategyBalanceBefore;
// }


// if a balanceOf an NFT tokenType asset has changed by more than 1 it must have been transferMultiple() called
// rule integrityOfNFTTransfer(){
//     env e;
//     uint supplyBefore = totalSupply[assetId];
//     calldataarg args;
//     f(e,args);
//     uint supplyAfter = totalSupply[assetId];

//     uint diff;
//     if (supplyBefore > supplyAfter) {diff = supplyBefore - supplyAfter}
//     else {diff = supplyAfter - supplyBefore}

//     assert diff > 1 => f.selector == transferMultiple(address,address[],uint256,uint256[]).selector;
// }


////////////////////////////////////////////////////////////////////////////
//                       Helper Functions                                 //
////////////////////////////////////////////////////////////////////////////

// TODO: Any additional helper functions

