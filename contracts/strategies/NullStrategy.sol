// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;

import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155.sol";
import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringAddress.sol";
import "@boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol";
import "../enums/YieldBoxTokenType.sol";
import "../BoringMath.sol";
import "../interfaces/IWrappedNative.sol";
import "./BaseStrategy.sol";

// solhint-disable const-name-snakecase
// solhint-disable no-empty-blocks

abstract contract BaseNullStrategy is BaseStrategy {
    string public constant override name = "NULL";
    string public constant override description = "Simply holds the asset";

    function _deposited(uint256 amount) internal override {}
}

contract NullERC20Strategy is BaseNullStrategy, IMasterContract {
    using BoringERC20 for IERC20;

    TokenType public constant tokenType = TokenType.ERC20;
    uint256 public constant tokenId = 0;
    address public contractAddress;

    constructor(IYieldBox _yieldBox) BaseStrategy(_yieldBox) {}

    function init(bytes calldata data) external payable override {
        require(address(contractAddress) == address(0), "Already initialized");
        (contractAddress) = abi.decode(data, (address));
    }

    function _currentBalance() internal view override returns (uint256 amount) {
        return IERC20(contractAddress).safeBalanceOf(address(this));
    }

    function _withdraw(address to, uint256 amount) internal override {
        IERC20(contractAddress).safeTransfer(to, amount);
    }
}

contract NullNativeStrategy is BaseNullStrategy, IMasterContract {
    using BoringAddress for address;
    using BoringERC20 for IWrappedNative;

    TokenType public constant tokenType = TokenType.ERC20;
    uint256 public constant tokenId = 0;
    address public immutable contractAddress;

    constructor(IYieldBox _yieldBox) BaseStrategy(_yieldBox) {
        contractAddress = _yieldBox.wrappedNative();
    }

    function init(bytes calldata data) external payable override {}

    function _currentBalance() internal view override returns (uint256 amount) {
        return IWrappedNative(contractAddress).safeBalanceOf(address(this));
    }

    function _withdraw(address to, uint256 amount) internal override {
        IWrappedNative(contractAddress).withdraw(amount);
        to.sendNative(amount);
    }
}

// TODO: Check if it is a YieldBox token?
contract NullERC1155Strategy is BaseNullStrategy, IMasterContract {
    TokenType public constant tokenType = TokenType.ERC1155;
    uint256 public tokenId;
    address public contractAddress;

    constructor(IYieldBox _yieldBox) BaseStrategy(_yieldBox) {}

    function init(bytes calldata data) external payable override {
        require(address(contractAddress) == address(0), "Already initialized");
        (contractAddress, tokenId) = abi.decode(data, (address, uint256));
    }

    function _currentBalance() internal view override returns (uint256 amount) {
        return IERC1155(contractAddress).balanceOf(address(this), tokenId);
    }

    function _withdraw(address to, uint256 amount) internal override {
        IERC1155(contractAddress).safeTransferFrom(address(this), to, tokenId, amount, "");
    }
}
