import "erc20.spec"
import "otherTokens.spec"

using YieldBoxHarness as YieldBox

methods {
    // DummyERC20.sol
    permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) => DISPATCHER(true)

    // Strategy.sol
    currentBalance() returns(uint256) => DISPATCHER(true)
    deposited(uint256) => DISPATCHER(true)
    tokenType() returns(uint8) => DISPATCHER(true)
    contractAddress() returns(address) => DISPATCHER(true)
    tokenId() returns(uint256) => DISPATCHER(true)
    withdraw(address, uint256) => DISPATCHER(true)

    // ERC1155TokenReceiver.sol
    onERC1155BatchReceived(address, address, uint256[], uint256[], bytes) returns(bytes4) => DISPATCHER(true)
    onERC1155Received(address, address, uint256, uint256, bytes ) returns(bytes4) => DISPATCHER(true)

    // DummyERC721Imp.sol
    ownerOf(uint256) returns(address) => DISPATCHER(true)
    safeTransferFrom(address,address,uint256) => DISPATCHER(true)

    // YieldBox.sol
}

rule sanity(env e, method f) filtered { f -> excludeMethods(f) } {
    calldataarg args;
    f(e, args);
    assert false;
}

rule whoChangedBalanceOf(env eB, env eF, method f) filtered { f -> excludeMethods(f) } {
    YieldBox.Asset asset;
    calldataarg args;
    uint256 before = _tokenBalanceOf(eB, asset);
    f(eF, args);
    assert _tokenBalanceOf(eB, asset) == before, "balanceOf changed";
}



definition excludeMethods(method f) returns bool =
    f.selector != batch(bytes[],bool).selector 
                    && f.selector != uri(uint256).selector 
                    && f.selector != name(uint256).selector 
                    && f.selector != symbol(uint256).selector 
                    && f.selector != decimals(uint256).selector;