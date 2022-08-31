pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "../munged/YieldBox.sol";
import "../munged/AssetRegister.sol";

contract YieldBoxHarness is YieldBox {
    constructor(IWrappedNative wrappedNative_, YieldBoxURIBuilder uriBuilder_) YieldBox(wrappedNative_, uriBuilder_) {}

    function getAssetArrayElement(uint256 assetId) public view returns(Asset memory) {
        return assets[assetId];
    }

    function getAssetTokenType(uint256 assetId) public view returns(TokenType) {
        return assets[assetId].tokenType;
    }

    function getAssetAddress(uint256 assetId) public view returns(address) {
        return assets[assetId].contractAddress;
    }

    function getAssetStrategy(uint256 assetId) public view returns(IStrategy) {
        return assets[assetId].strategy;
    }

    function getAssetTokenId(uint256 assetId) public view returns(uint256) {
        return assets[assetId].tokenId;
    }

    function getIdFromIds(TokenType tokenType, address contractAddress, IStrategy strategy, uint256 tokenId) public view returns(uint256) {
        return ids[tokenType][contractAddress][strategy][tokenId];
    }
}
