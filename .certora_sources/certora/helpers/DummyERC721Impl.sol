// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.8.0;

import "./SafeMath.sol";

/*
    A very incomplete implementation of ERC721 that only foscuses on transferFrom and ownership tracking.
    Lacks support for approvals, lacks some sensible checks.
    Meant to be used as a stab; Expand it in a different contract when needed.
*/
contract DummyERC721Impl {
    using SafeMath for uint256;

    string public name;
    string public symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    
    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "ERC721: Zero Address is invalid");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    function transferFrom(address from, address to, uint256 tokenId) public payable {
        require(_owners[tokenId] == from);
        require(to != address(0));
        
        //msg.snder or approved checks would be here

        _balances[from] = _balances[from].sub(1);
        _balances[to] = _balances[to].add(1);
        _owners[tokenId] = to;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual {
        transferFrom(from, to, tokenId);
    }
}