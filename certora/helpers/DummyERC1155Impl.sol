pragma solidity ^0.8.0;

import "./SafeMath.sol";

/*
    A very incomplete implementation of ERC1155 that only foscuses on transferFrom and ownership tracking.
    Lacks support for approvals, "safe checks" on recipients, and some other sensible checks.
    Meant to be used as a stab; Expand it in a different contract if needed.

    Note: 
        currently lacks total supply per tokenId
        lacks approval checks
        lacks the call to OnRecieved for the safeTransferFrom
*/
contract DummyERC1155Impl {
    using SafeMath for uint256;

    string public name;
    string public symbol;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    // Mapping from account to operator approvals
    // mapping(address => mapping(address => bool)) private _operatorApprovals;

    function balanceOf(address owner, uint256 tokenId) external view returns (uint256) {
        require(owner != address(0), "ERC1155: Zero Address is invalid");
        return _balances[tokenId][owner];
    }

    //Not so Safe transfers
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external {
        require(to != address(0));

        // No approval checks

        _transferFrom(from, to, id, amount);

        // DOES NOT VERIFY
    }

    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external {
        require(to != address(0));

        // No approval checks

        for (uint256 i; i < ids.length; i++) {
            _transferFrom(from, to, ids[i], amounts[i]);
        }

        // DOES NOT VERIFY
    }

    function _transferFrom(address from, address to, uint256 id, uint256 amount) internal {
        _balances[id][from] = _balances[id][from].sub(amount);
        _balances[id][to] = _balances[id][to].add(amount);
    }

    function _setApprovalForAll(address owner, address operator, bool approved) internal virtual {
        require(owner != operator, "ERC1155: setting approval status for self");
        _operatorApprovals[owner][operator] = approved;
    }
}

contract DummyMintableERC1155Impl is DummyERC1155Impl {
    address public minter;

    modifier onlyMinter() {
        require(msg.sender == minter, "Mint callable by minter only");
        _;
    }

    // constructor (address _minter) {
    //     minter = _minter;
    // }

    function _mint(address to, uint256 id, uint256 value) internal {
        require(to != address(0), "No 0 address");
        _balances[id][to] += value;
    }

    function mint(address to, uint256 id, uint256 value) external onlyMinter {
        _mint(to, id, value);
    }
}
