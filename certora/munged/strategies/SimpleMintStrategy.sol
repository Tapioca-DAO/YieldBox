// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
// pragma experimental ABIEncoderV2;

//TODO - replace this with our dummy?
// import "@boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol";
// import "@boringcrypto/boring-solidity/contracts/interfaces/IERC721.sol";
// import "@boringcrypto/boring-solidity/contracts/interfaces/IERC1155.sol";
// Maybe swap this to any other IERC20 - WE MUST, since those don't have mintable

import "../enums/YieldBoxTokenType.sol";
import "../interfaces/IStrategy.sol";
import {BaseStrategy} from "./BaseStrategy.sol";


// DUMMY INTERFAES - just what needed
interface IERC20 {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function transfer(address _to, uint256 _value) external returns (bool success);
    function mint(address _to, uint256 _value) external returns (bool success);
}

interface IERC721 {
    function ownerOf(uint256 _tokenId) external view returns (address);
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    // function mint
}

interface IERC1155 {
    function balanceOf(address _owner, uint256 _id) external view returns (uint256);
    function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _value, bytes calldata _data) external;
    function mint(address _to, uint256 _id, uint256 _amount) external returns (bool success);
}


contract SimpleMintStrategy is BaseStrategy{
    // A single token strategy that just mints more of the token for each deposit.
    // This strategy assumes the token is mintable and that it is the minter for it.
    // 
    // This could simulate accumilated yields etc. 
    // Note that this strategy should be used for a SINGLE token. It has no idea about other tokens than what it was constructed for.

    TokenType public immutable tokenType;
    uint256 public immutable tokenId;
    address public immutable tokenAddress;
    uint256 public mintAmount; //Should this be immutable too?? #TODO
    // uint256 public _balance;

    constructor(IYieldBox _yieldBox, address _tokenAddress, TokenType _tokenType, uint256 _tokenId, uint256 _mintAmount) BaseStrategy(_yieldBox) {
        tokenType = _tokenType;
        tokenAddress = _tokenAddress;
        tokenId = _tokenId; 
        mintAmount = _mintAmount;
    }

    function contractAddress() public view returns (address) {
        return tokenAddress;
    }

    function _currentBalance() internal view override returns (uint256 amount) {
        // ERC20 just gets address
        if (tokenType == TokenType.ERC20) {
            return IERC20(tokenAddress).balanceOf(address(this));
        }
        else if (tokenType == TokenType.ERC721) {
            return ((IERC721(tokenAddress).ownerOf(tokenId) == address(this)) ? 1 : 0);
        }
        // ERC1155 (and native?)
        else {
            return IERC1155(tokenAddress).balanceOf(address(this), tokenId);
        }
    }

    function _mint() internal {
        // MINT!!
        if (tokenType == TokenType.ERC20) {
            IERC20(tokenAddress).mint(address(this), mintAmount);
        }
        else if (tokenType == TokenType.ERC721) {
            // DO NOTHING...?
        }
        // ERC1155 (and native?)
        else {
            IERC1155(tokenAddress).mint(address(this), tokenId, mintAmount);
        }
    }

    function _deposited(uint256 amount) internal override {
        amount = 0; //silence a warning
        _mint();
    }

    function _withdraw(address to, uint256 amount) internal override {        
        //// TODO: maybe should mint here as well? (copy mint block?)
        // _mint();
        
        if (tokenType == TokenType.ERC20) {
            IERC20(tokenAddress).transfer(to, amount);
        }
        else if (tokenType == TokenType.ERC721) {
            IERC721(tokenAddress).transferFrom(address(this), to, tokenId);
        }
        // ERC1155 (and native?)
        else {
            IERC1155(tokenAddress).safeTransferFrom(address(this), to, tokenId, amount, "");
        }        
    }

    function description() external pure returns (string memory description_) {
        return "A simple mint-based strategy. MOCK CONTRACT";
    }

    function name() external pure returns (string memory name_) {
        return "SimpleMintStrategy";
    }
}
