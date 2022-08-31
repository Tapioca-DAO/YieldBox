import "erc20.spec"
import "otherTokens.spec"

using AssetRegister as register

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


// invariant differentAssetdifferentAssetId(register.Asset[] a, uint i, uint j)
//     // assets[i] != assets[j] <=> i != j
//     a[i].tokenType != a[j].tokenType ||
//     a[i].contractAddress != a[j].contractAddress ||
//     a[i].strategy != a[j].strategy ||
//     a[i].tokenId != a[j].tokenId
//     <=>
//     i != j

invariant idsVsAssets(register.Asset asset, uint i)
    register.ids[asset.tokenType][asset.contractAddress][asset.strategy][asset.tokenId] == 0 =>
        assets[i] != asset &&
        register.ids[assets[i].tokenType][assets[i].contractAddress][assets[i].strategy][assets[i].tokenId] == i

// invariant erc20HasTokenIdZero(register.Asset asset)
//     asset.tokenType == TokenType.ERC20 && asset.tokenId != 0 =>
//     ids[asset.tokenType][asset.contractAddress][asset.strategy][asset.tokenId] == 0

// invariant tokenTypeValidity(register.Asset asset)
//     asset.tokenType > 4 => _tokenBalanceOf(asset) == 0
    

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

// rule moreDepositMoreShares(){
//     env e;
//     uint amountOut1; uint shareOut1; uint amount1;
//     uint amountOut2; uint shareOut2; uint amount2;
//     uint tokenId;
//     TokenType tokenType;
//     address contractAddress;
//     address from; address to;
//     IStrategy strategy;


//     storage init = lastStorage;
    
//     amountOut1, shareOut1 = deposit(tokenType, contractAddress, strategy, tokenId, from, to, amount1, 0);
//     amountOut1, shareOut1 = deposit(tokenType, contractAddress, strategy, tokenId, from, to, amount2, 0) at init;

//     assert  amount2 > amount1 => shareOut2 > shareOut1
// }
////////////////////////////////////////////////////////////////////////////
//                       Helper Functions                                 //
////////////////////////////////////////////////////////////////////////////

// TODO: Any additional helper functions

