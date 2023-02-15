pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "../munged/YieldBox.sol";
import "../munged/AssetRegister.sol";

contract YieldBoxHarness is YieldBox {
    using YieldBoxRebase for uint256;

    constructor(IWrappedNative wrappedNative_, YieldBoxURIBuilder uriBuilder_) YieldBox(wrappedNative_, uriBuilder_) {}

    // all these functions can revert
    function getAssetArrayElement(uint256 assetId) public view returns (Asset memory) {
        return assets[assetId];
    }

    function getAssetsLength() public view returns (uint256) {
        return assets.length;
    }

    function getAssetTokenType(uint256 assetId) public view returns (TokenType) {
        // return assets[assetId].tokenType;
        return assets.length <= assetId ? TokenType.None : assets[assetId].tokenType;
    }

    function getAssetAddress(uint256 assetId) public view returns (address) {
        // return assets[assetId].contractAddress;
        return assets.length <= assetId ? address(0) : assets[assetId].contractAddress;
    }

    function getAssetStrategy(uint256 assetId) public view returns (IStrategy) {
        // return assets[assetId].strategy;
        return assets.length <= assetId ? NO_STRATEGY : assets[assetId].strategy;
    }

    function getAssetTokenId(uint256 assetId) public view returns (uint256) {
        // return assets[assetId].tokenId;
        return assets.length <= assetId ? 0 : assets[assetId].tokenId;
    }

    function getIdFromIds(TokenType tokenType, address contractAddress, IStrategy strategy, uint256 tokenId) public view returns (uint256) {
        return ids[tokenType][contractAddress][strategy][tokenId];
    }

    function getAssetId(Asset memory asset) public view returns (uint256) {
        return ids[asset.tokenType][asset.contractAddress][asset.strategy][asset.tokenId];
    }

    function assetsIdentical(uint256 i, uint256 j) public view returns (bool) {
        if (i >= assets.length || j >= assets.length) {
            return false;
        } else {
            return
                assets[i].tokenType == assets[j].tokenType &&
                assets[i].contractAddress == assets[j].contractAddress &&
                assets[i].strategy == assets[j].strategy &&
                assets[i].tokenId == assets[j].tokenId;
        }
    }

    function assetsIdentical1(uint256 i, Asset memory asset) public view returns (bool) {
        if (i >= assets.length) {
            return false;
        } else {
            return
                assets[i].tokenType == asset.tokenType &&
                assets[i].contractAddress == asset.contractAddress &&
                assets[i].strategy == asset.strategy &&
                assets[i].tokenId == asset.tokenId;
        }
    }

    function ethBalanceOfAdress(address addr) public returns (uint256) {
        return address(addr).balance;
    }

    function toShares(uint256 amount, uint256 totalShares_, uint256 totalAmount, bool roundUp) public returns (uint256) {
        return amount._toShares(totalShares_, totalAmount, roundUp);
    }

    function toAmount(uint256 share, uint256 totalShares_, uint256 totalAmount, bool roundUp) public returns (uint256) {
        return share._toAmount(totalShares_, totalAmount, roundUp);
    }

    function getAssetBalance(Asset memory asset) public returns (uint256) {
        return asset.strategy.currentBalance();
    }

    function getAssetTotalSupply(Asset memory asset) public returns (uint256) {
        uint256 id = getAssetId(asset);
        (uint256 totalShare, ) = assetTotals(id);
        return totalShare;
    }

    function getAssetTotalBalance(Asset memory asset) public returns (uint256) {
        uint256 id = getAssetId(asset);
        (, uint256 totalAmount) = assetTotals(id);
        return totalAmount;
    }
}
