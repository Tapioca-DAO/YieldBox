// Sources flattened with hardhat v2.9.1 https://hardhat.org

// File contracts/enums/YieldBoxTokenType.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title TokenType
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The YieldBox can hold different types of tokens:
/// Native: These are ERC1155 tokens native to YieldBox. Protocols using YieldBox should use these is possible when simple token creation is needed.
/// ERC20: ERC20 tokens (including rebasing tokens) can be added to the YieldBox.
/// ERC1155: ERC1155 tokens are also supported. This can also be used to add YieldBox Native tokens to strategies since they are ERC1155 tokens.
enum TokenType {
    Native,
    ERC20,
    ERC721,
    ERC1155,
    None
}


// File contracts/interfaces/IYieldBox.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

interface IYieldBox {
    function wrappedNative() external view returns (address wrappedNative);

    function assets(uint256 assetId)
        external
        view
        returns (
            TokenType tokenType,
            address contractAddress,
            address strategy,
            uint256 tokenId
        );

    function nativeTokens(uint256 assetId)
        external
        view
        returns (
            string memory name,
            string memory symbol,
            uint8 decimals
        );

    function owner(uint256 assetId) external view returns (address owner);

    function totalSupply(uint256 assetId) external view returns (uint256 totalSupply);

    function depositAsset(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function withdraw(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) external returns (uint256 amountOut, uint256 shareOut);

    function transfer(
        address from,
        address to,
        uint256 assetId,
        uint256 share
    ) external;

    function batchTransfer(
        address from,
        address to,
        uint256[] calldata assetIds_,
        uint256[] calldata shares_
    ) external;

    function transferMultiple(
        address from,
        address[] calldata tos,
        uint256 assetId,
        uint256[] calldata shares
    ) external;

    function toShare(
        uint256 assetId,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share);

    function toAmount(
        uint256 assetId,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount);
}


// File contracts/interfaces/IStrategy.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;


interface IStrategy {
    /// Each strategy only works with a single asset. This should help make implementations simpler and more readable.
    /// To safe gas a proxy pattern (YieldBox factory) could be used to deploy the same strategy for multiple tokens.

    /// It is recommended that strategies keep a small amount of funds uninvested (like 5%) to handle small withdrawals
    /// and deposits without triggering costly investing/divesting logic.

    /// #########################
    /// ### Basic Information ###
    /// #########################

    /// Returns the address of the yieldBox that this strategy is for
    function yieldBox() external view returns (IYieldBox yieldBox_);

    /// Returns a name for this strategy
    function name() external view returns (string memory name_);

    /// Returns a description for this strategy
    function description() external view returns (string memory description_);

    /// #######################
    /// ### Supported Token ###
    /// #######################

    /// Returns the standard that this strategy works with
    function tokenType() external view returns (TokenType tokenType_);

    /// Returns the contract address that this strategy works with
    function contractAddress() external view returns (address contractAddress_);

    /// Returns the tokenId that this strategy works with (for EIP1155)
    /// This is always 0 for EIP20 tokens
    function tokenId() external view returns (uint256 tokenId_);

    /// ###########################
    /// ### Balance Information ###
    /// ###########################

    /// Returns the total value the strategy holds (principle + gain) expressed in asset token amount.
    /// This should be cheap in gas to retrieve. Can return a bit less than the actual, but MUST NOT return more.
    /// The gas cost of this function will be paid on any deposit or withdrawal onto and out of the YieldBox
    /// that uses this strategy. Also, anytime a protocol converts between shares and amount, this gets called.
    function currentBalance() external view returns (uint256 amount);

    /// Returns the maximum amount that can be withdrawn
    function withdrawable() external view returns (uint256 amount);

    /// Returns the maximum amount that can be withdrawn for a low gas fee
    /// When more than this amount is withdrawn it will trigger divesting from the actual strategy
    /// which will incur higher gas costs
    function cheapWithdrawable() external view returns (uint256 amount);

    /// ##########################
    /// ### YieldBox Functions ###
    /// ##########################

    /// Is called by YieldBox to signal funds have been added, the strategy may choose to act on this
    /// When a large enough deposit is made, this should trigger the strategy to invest into the actual
    /// strategy. This function should normally NOT be used to invest on each call as that would be costly
    /// for small deposits.
    /// If the strategy handles native tokens (ETH) it will receive it directly (not wrapped). It will be
    /// up to the strategy to wrap it if needed.
    /// Only accept this call from the YieldBox
    function deposited(uint256 amount) external;

    /// Is called by the YieldBox to ask the strategy to withdraw to the user
    /// When a strategy keeps a little reserve for cheap withdrawals and the requested withdrawal goes over this amount,
    /// the strategy should divest enough from the strategy to complete the withdrawal and rebalance the reserve.
    /// If the strategy handles native tokens (ETH) it should send this, not a wrapped version.
    /// With some strategies it might be hard to withdraw exactly the correct amount.
    /// Only accept this call from the YieldBox
    function withdraw(address to, uint256 amount) external;
}

IStrategy constant NO_STRATEGY = IStrategy(address(0));


// File @boringcrypto/boring-solidity/contracts/libraries/BoringAddress.sol@v2.0.2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

library BoringAddress {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendNative(address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        (bool success, ) = to.call{value: amount}("");
        require(success, "BoringAddress: transfer failed");
    }
}


// File @boringcrypto/boring-solidity/contracts/interfaces/IERC165.sol@v2.0.2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}


// File @boringcrypto/boring-solidity/contracts/interfaces/IERC1155.sol@v2.0.2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC1155 is IERC165 {
    event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _value);
    event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _values);
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
    event URI(string _value, uint256 indexed _id);

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external;

    function safeBatchTransferFrom(
        address _from,
        address _to,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external;

    function balanceOf(address _owner, uint256 _id) external view returns (uint256);

    function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

    function setApprovalForAll(address _operator, bool _approved) external;

    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}


// File @boringcrypto/boring-solidity/contracts/interfaces/IERC1155TokenReceiver.sol@v2.0.2

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC1155TokenReceiver {
    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external returns (bytes4);
}


// File contracts/ERC1155.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;



// Written by OreNoMochi (https://github.com/OreNoMochii), BoringCrypto

contract ERC1155 is IERC1155 {
    using BoringAddress for address;

    // mappings
    mapping(address => mapping(address => bool)) public override isApprovedForAll; // map of operator approval
    mapping(address => mapping(uint256 => uint256)) public override balanceOf; // map of tokens owned by
    mapping(uint256 => uint256) public totalSupply; // totalSupply per token

    function supportsInterface(bytes4 interfaceID) public pure override returns (bool) {
        return
            interfaceID == this.supportsInterface.selector || // EIP-165
            interfaceID == 0xd9b67a26 || // ERC-1155
            interfaceID == 0x0e89341c; // EIP-1155 Metadata
    }

    function balanceOfBatch(address[] calldata owners, uint256[] calldata ids) external view override returns (uint256[] memory balances) {
        uint256 len = owners.length;
        require(len == ids.length, "ERC1155: Length mismatch");

        balances = new uint256[](len);

        for (uint256 i = 0; i < len; i++) {
            balances[i] = balanceOf[owners[i]][ids[i]];
        }
    }

    function _mint(
        address to,
        uint256 id,
        uint256 value
    ) internal {
        require(to != address(0), "No 0 address");

        balanceOf[to][id] += value;
        totalSupply[id] += value;

        emit TransferSingle(msg.sender, address(0), to, id, value);
    }

    function _burn(
        address from,
        uint256 id,
        uint256 value
    ) internal {
        require(from != address(0), "No 0 address");

        balanceOf[from][id] -= value;
        totalSupply[id] -= value;

        emit TransferSingle(msg.sender, from, address(0), id, value);
    }

    function _transferSingle(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) internal {
        require(to != address(0), "No 0 address");

        balanceOf[from][id] -= value;
        balanceOf[to][id] += value;

        emit TransferSingle(msg.sender, from, to, id, value);
    }

    function _transferBatch(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values
    ) internal {
        require(to != address(0), "No 0 address");

        for (uint256 i = 0; i < ids.length; i++) {
            uint256 id = ids[i];
            uint256 value = values[i];
            balanceOf[from][id] -= value;
            balanceOf[to][id] += value;
        }

        emit TransferBatch(msg.sender, from, to, ids, values);
    }

    function _requireTransferAllowed(address from) internal view virtual {
        require(from == msg.sender || isApprovedForAll[from][msg.sender] == true, "Transfer not allowed");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external override {
        _requireTransferAllowed(from);

        _transferSingle(from, to, id, value);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155Received(msg.sender, from, id, value, data) ==
                    bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)")),
                "Wrong return value"
            );
        }
    }

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external override {
        require(ids.length == values.length, "ERC1155: Length mismatch");
        _requireTransferAllowed(from);

        _transferBatch(from, to, ids, values);

        if (to.isContract()) {
            require(
                IERC1155TokenReceiver(to).onERC1155BatchReceived(msg.sender, from, ids, values, data) ==
                    bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)")),
                "Wrong return value"
            );
        }
    }

    function setApprovalForAll(address operator, bool approved) external virtual override {
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function uri(
        uint256 /*assetId*/
    ) external view virtual returns (string memory) {
        return "";
    }
}


// File contracts/AssetRegister.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;



// An asset is a token + a strategy
struct Asset {
    TokenType tokenType;
    address contractAddress;
    IStrategy strategy;
    uint256 tokenId;
}

contract AssetRegister is ERC1155 {
    using BoringAddress for address;

    event AssetRegistered(
        TokenType indexed tokenType,
        address indexed contractAddress,
        IStrategy strategy,
        uint256 indexed tokenId,
        uint256 assetId
    );

    // ids start at 1 so that id 0 means it's not yet registered
    mapping(TokenType => mapping(address => mapping(IStrategy => mapping(uint256 => uint256)))) public ids;
    Asset[] public assets;

    constructor() {
        assets.push(Asset(TokenType.None, address(0), NO_STRATEGY, 0));
    }

    function assetCount() public view returns (uint256) {
        return assets.length;
    }

    function _registerAsset(
        TokenType tokenType,
        address contractAddress,
        IStrategy strategy,
        uint256 tokenId
    ) internal returns (uint256 assetId) {
        // Checks
        assetId = ids[tokenType][contractAddress][strategy][tokenId];

        // If assetId is 0, this is a new asset that needs to be registered
        if (assetId == 0) {
            // Only do these checks if a new asset needs to be created
            require(tokenId == 0 || tokenType != TokenType.ERC20, "YieldBox: No tokenId for ERC20");
            require(
                strategy == NO_STRATEGY ||
                    (tokenType == strategy.tokenType() && contractAddress == strategy.contractAddress() && tokenId == strategy.tokenId()),
                "YieldBox: Strategy mismatch"
            );
            // If a new token gets added, the isContract checks that this is a deployed contract. Needed for security.
            // Prevents getting shares for a future token whose address is known in advance. For instance a token that will be deployed with CREATE2 in the future or while the contract creation is
            // in the mempool
            require((tokenType == TokenType.Native && contractAddress == address(0)) || contractAddress.isContract(), "YieldBox: Not a token");

            // Effects
            assetId = assets.length;
            assets.push(Asset(tokenType, contractAddress, strategy, tokenId));
            ids[tokenType][contractAddress][strategy][tokenId] = assetId;

            // The actual URI isn't emitted here as per EIP1155, because that would make this call super expensive.
            emit URI("", assetId);
            emit AssetRegistered(tokenType, contractAddress, strategy, tokenId, assetId);
        }
    }

    function registerAsset(
        TokenType tokenType,
        address contractAddress,
        IStrategy strategy,
        uint256 tokenId
    ) public returns (uint256 assetId) {
        // Native assets can only be added internally by the NativeTokenFactory
        require(
            tokenType == TokenType.ERC20 || tokenType == TokenType.ERC721 || tokenType == TokenType.ERC1155,
            "AssetManager: cannot add Native"
        );
        assetId = _registerAsset(tokenType, contractAddress, strategy, tokenId);
    }
}


// File contracts/ERC1155TokenReceiver.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ERC1155TokenReceiver is IERC1155TokenReceiver {
    // ERC1155 receivers that simple accept the transfer
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xf23a6e61; //bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return 0xbc197c81; //bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))
    }
}


// File @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}


// File contracts/ERC721Receiver.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract ERC721Receiver is IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4){
        return 0x150b7a02; //bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))
    }
}


// File @boringcrypto/boring-solidity/contracts/interfaces/IERC20.sol@v2.0.2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


// File contracts/interfaces/IWrappedNative.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IWrappedNative is IERC20 {
    function deposit() external payable;

    function withdraw(uint256) external;
}


// File contracts/mocks/ERC1155Mock.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract ERC1155Mock is ERC1155 {
    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public {
        _mint(to, id, amount);
    }

    function burn(
        address from,
        uint256 id,
        uint256 amount
    ) public {
        _burn(from, id, amount);
    }

    function transferSingle(
        address from,
        address to,
        uint256 id,
        uint256 value
    ) public {
        _transferSingle(from, to, id, value);
    }

    function transferBatch(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata values
    ) public {
        _transferBatch(from, to, ids, values);
    }
}


// File contracts/mocks/ERC1155ReceiverMock.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract ERC1155ReceiverMock is IERC1155TokenReceiver {
    address public sender;
    address public operator;
    address public from;
    uint256 public id;
    uint256[] public ids;
    uint256 public value;
    uint256[] public values;
    bytes public data;

    uint256 public fromBalance;

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external override returns (bytes4) {
        sender = msg.sender;
        operator = _operator;
        from = _from;
        id = _id;
        value = _value;
        data = _data;
        fromBalance = ERC1155(sender).balanceOf(from, id);

        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function onERC1155BatchReceived(
        address _operator,
        address _from,
        uint256[] calldata _ids,
        uint256[] calldata _values,
        bytes calldata _data
    ) external override returns (bytes4) {
        sender = msg.sender;
        operator = _operator;
        from = _from;
        ids = _ids;
        values = _values;
        data = _data;
        if (ids.length > 0) {
            fromBalance = ERC1155(sender).balanceOf(from, ids[0]);
        }

        return bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"));
    }

    function returnToken() external {
        ERC1155(sender).safeTransferFrom(address(this), from, id, value, "");
    }

    function returnTokens() external {
        ERC1155(sender).safeBatchTransferFrom(address(this), from, ids, values, "");
    }
}

contract ERC1155BrokenReceiverMock is IERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("wrong"));
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        return bytes4(keccak256("wrong"));
    }
}

contract ERC1155RevertingReceiverMock is IERC1155TokenReceiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("Oops");
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external pure override returns (bytes4) {
        revert("Oops");
    }
}


// File contracts/mocks/ERC1155StrategyMock.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;




// solhint-disable const-name-snakecase
// solhint-disable no-empty-blocks

contract ERC1155StrategyMock is IStrategy, ERC1155TokenReceiver {
    string public constant override name = "ERC1155StrategyMock";
    string public constant override description = "Mock Strategy for testing";

    TokenType public constant override tokenType = TokenType.ERC1155;
    address public immutable override contractAddress;
    uint256 public immutable override tokenId;

    IYieldBox public immutable yieldBox;

    constructor(
        IYieldBox yieldBox_,
        address token,
        uint256 tokenId_
    ) {
        yieldBox = yieldBox_;
        contractAddress = token;
        tokenId = tokenId_;
    }

    /// Returns the total value the strategy holds (principle + gain) expressed in asset token amount.
    /// This should be cheap in gas to retrieve. Can return a bit less than the actual, but shouldn't return more.
    /// The gas cost of this function will be paid on any deposit or withdrawal onto and out of the YieldBox
    /// that uses this strategy. Also, anytime a protocol converts between shares and amount, this gets called.
    function currentBalance() public view override returns (uint256 amount) {
        return IERC1155(contractAddress).balanceOf(address(this), tokenId);
    }

    /// Returns the maximum amount that can be withdrawn
    function withdrawable() external view override returns (uint256 amount) {
        return IERC1155(contractAddress).balanceOf(address(this), tokenId);
    }

    /// Returns the maximum amount that can be withdrawn for a low gas fee
    /// When more than this amount is withdrawn it will trigger divesting from the actual strategy
    /// which will incur higher gas costs
    function cheapWithdrawable() external view override returns (uint256 amount) {
        return IERC1155(contractAddress).balanceOf(address(this), tokenId);
    }

    /// Is called by YieldBox to signal funds have been added, the strategy may choose to act on this
    /// When a large enough deposit is made, this should trigger the strategy to invest into the actual
    /// strategy. This function should normally NOT be used to invest on each call as that would be costly
    /// for small deposits.
    /// Only accept this call from the YieldBox
    function deposited(uint256 amount) external override {}

    /// Is called by the YieldBox to ask the strategy to withdraw to the user
    /// When a strategy keeps a little reserve for cheap withdrawals and the requested withdrawal goes over this amount,
    /// the strategy should divest enough from the strategy to complete the withdrawal and rebalance the reserve.
    /// Only accept this call from the YieldBox
    function withdraw(address to, uint256 amount) external override {
        IERC1155(contractAddress).safeTransferFrom(address(this), to, tokenId, amount, "");
    }
}


// File @boringcrypto/boring-solidity/contracts/Domain.sol@v2.0.2

// SPDX-License-Identifier: MIT
// Based on code and smartness by Ross Campbell and Keno
// Uses immutable to store the domain separator to reduce gas usage
// If the chain id changes due to a fork, the forked chain will calculate on the fly.
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

contract Domain {
    bytes32 private constant DOMAIN_SEPARATOR_SIGNATURE_HASH = keccak256("EIP712Domain(uint256 chainId,address verifyingContract)");
    // See https://eips.ethereum.org/EIPS/eip-191
    string private constant EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA = "\x19\x01";

    // solhint-disable var-name-mixedcase
    bytes32 private immutable _DOMAIN_SEPARATOR;
    uint256 private immutable DOMAIN_SEPARATOR_CHAIN_ID;

    /// @dev Calculate the DOMAIN_SEPARATOR
    function _calculateDomainSeparator(uint256 chainId) private view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_SIGNATURE_HASH, chainId, address(this)));
    }

    constructor() {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        _DOMAIN_SEPARATOR = _calculateDomainSeparator(DOMAIN_SEPARATOR_CHAIN_ID = chainId);
    }

    /// @dev Return the DOMAIN_SEPARATOR
    // It's named internal to allow making it public from the contract that uses it by creating a simple view function
    // with the desired public name, such as DOMAIN_SEPARATOR or domainSeparator.
    // solhint-disable-next-line func-name-mixedcase
    function _domainSeparator() internal view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return chainId == DOMAIN_SEPARATOR_CHAIN_ID ? _DOMAIN_SEPARATOR : _calculateDomainSeparator(chainId);
    }

    function _getDigest(bytes32 dataHash) internal view returns (bytes32 digest) {
        digest = keccak256(abi.encodePacked(EIP191_PREFIX_FOR_EIP712_STRUCTURED_DATA, _domainSeparator(), dataHash));
    }
}


// File @boringcrypto/boring-solidity/contracts/ERC20.sol@v2.0.2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

// Data part taken out for building of contracts that receive delegate calls
contract ERC20Data {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;
}

abstract contract ERC20 is IERC20, Domain {
    /// @notice owner > balance mapping.
    mapping(address => uint256) public override balanceOf;
    /// @notice owner > spender > allowance mapping.
    mapping(address => mapping(address => uint256)) public override allowance;
    /// @notice owner > nonce mapping. Used in `permit`.
    mapping(address => uint256) public nonces;

    /// @notice Transfers `amount` tokens from `msg.sender` to `to`.
    /// @param to The address to move the tokens.
    /// @param amount of the tokens to move.
    /// @return (bool) Returns True if succeeded.
    function transfer(address to, uint256 amount) public returns (bool) {
        // If `amount` is 0, or `msg.sender` is `to` nothing happens
        if (amount != 0 || msg.sender == to) {
            uint256 srcBalance = balanceOf[msg.sender];
            require(srcBalance >= amount, "ERC20: balance too low");
            if (msg.sender != to) {
                require(to != address(0), "ERC20: no zero address"); // Moved down so low balance calls safe some gas

                balanceOf[msg.sender] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    /// @notice Transfers `amount` tokens from `from` to `to`. Caller needs approval for `from`.
    /// @param from Address to draw tokens from.
    /// @param to The address to move the tokens.
    /// @param amount The token amount to move.
    /// @return (bool) Returns True if succeeded.
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        // If `amount` is 0, or `from` is `to` nothing happens
        if (amount != 0) {
            uint256 srcBalance = balanceOf[from];
            require(srcBalance >= amount, "ERC20: balance too low");

            if (from != to) {
                uint256 spenderAllowance = allowance[from][msg.sender];
                // If allowance is infinite, don't decrease it to save on gas (breaks with EIP-20).
                if (spenderAllowance != type(uint256).max) {
                    require(spenderAllowance >= amount, "ERC20: allowance too low");
                    allowance[from][msg.sender] = spenderAllowance - amount; // Underflow is checked
                }
                require(to != address(0), "ERC20: no zero address"); // Moved down so other failed calls safe some gas

                balanceOf[from] = srcBalance - amount; // Underflow is checked
                balanceOf[to] += amount;
            }
        }
        emit Transfer(from, to, amount);
        return true;
    }

    /// @notice Approves `amount` from sender to be spend by `spender`.
    /// @param spender Address of the party that can draw from msg.sender's account.
    /// @param amount The maximum collective amount that `spender` can draw.
    /// @return (bool) Returns True if approved.
    function approve(address spender, uint256 amount) public override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32) {
        return _domainSeparator();
    }

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 private constant PERMIT_SIGNATURE_HASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

    /// @notice Approves `value` from `owner_` to be spend by `spender`.
    /// @param owner_ Address of the owner.
    /// @param spender The address of the spender that gets approved to draw from `owner_`.
    /// @param value The maximum collective amount that `spender` can draw.
    /// @param deadline This permit must be redeemed before this deadline (UTC timestamp in seconds).
    function permit(
        address owner_,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        require(owner_ != address(0), "ERC20: Owner cannot be 0");
        require(block.timestamp < deadline, "ERC20: Expired");
        require(
            ecrecover(_getDigest(keccak256(abi.encode(PERMIT_SIGNATURE_HASH, owner_, spender, value, nonces[owner_]++, deadline))), v, r, s) ==
                owner_,
            "ERC20: Invalid Signature"
        );
        allowance[owner_][spender] = value;
        emit Approval(owner_, spender, value);
    }
}

contract ERC20WithSupply is IERC20, ERC20 {
    uint256 public override totalSupply;

    function _mint(address user, uint256 amount) internal {
        uint256 newTotalSupply = totalSupply + amount;
        require(newTotalSupply >= totalSupply, "Mint overflow");
        totalSupply = newTotalSupply;
        balanceOf[user] += amount;
        emit Transfer(address(0), user, amount);
    }

    function _burn(address user, uint256 amount) internal {
        require(balanceOf[user] >= amount, "Burn too much");
        totalSupply -= amount;
        balanceOf[user] -= amount;
        emit Transfer(user, address(0), amount);
    }
}


// File contracts/mocks/ERC20Mock.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract ERC20Mock is ERC20 {
    uint256 public override totalSupply;

    constructor(uint256 _initialAmount) {
        // Give the creator all initial tokens
        balanceOf[msg.sender] = _initialAmount;
        // Update total supply
        totalSupply = _initialAmount;
    }

    function mint(uint256 amount) public {
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
    }
}


// File @boringcrypto/boring-solidity/contracts/libraries/BoringERC20.sol@v2.0.2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable avoid-low-level-calls

library BoringERC20 {
    bytes4 private constant SIG_SYMBOL = 0x95d89b41; // symbol()
    bytes4 private constant SIG_NAME = 0x06fdde03; // name()
    bytes4 private constant SIG_DECIMALS = 0x313ce567; // decimals()
    bytes4 private constant SIG_BALANCE_OF = 0x70a08231; // balanceOf(address)
    bytes4 private constant SIG_TOTALSUPPLY = 0x18160ddd; // balanceOf(address)
    bytes4 private constant SIG_TRANSFER = 0xa9059cbb; // transfer(address,uint256)
    bytes4 private constant SIG_TRANSFER_FROM = 0x23b872dd; // transferFrom(address,address,uint256)

    function returnDataToString(bytes memory data) internal pure returns (string memory) {
        if (data.length >= 64) {
            return abi.decode(data, (string));
        } else if (data.length == 32) {
            uint8 i = 0;
            while (i < 32 && data[i] != 0) {
                i++;
            }
            bytes memory bytesArray = new bytes(i);
            for (i = 0; i < 32 && data[i] != 0; i++) {
                bytesArray[i] = data[i];
            }
            return string(bytesArray);
        } else {
            return "???";
        }
    }

    /// @notice Provides a safe ERC20.symbol version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token symbol.
    function safeSymbol(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_SYMBOL));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.name version which returns '???' as fallback string.
    /// @param token The address of the ERC-20 token contract.
    /// @return (string) Token name.
    function safeName(IERC20 token) internal view returns (string memory) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_NAME));
        return success ? returnDataToString(data) : "???";
    }

    /// @notice Provides a safe ERC20.decimals version which returns '18' as fallback value.
    /// @param token The address of the ERC-20 token contract.
    /// @return (uint8) Token decimals.
    function safeDecimals(IERC20 token) internal view returns (uint8) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_DECIMALS));
        return success && data.length == 32 ? abi.decode(data, (uint8)) : 18;
    }

    /// @notice Provides a gas-optimized balance check to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @param to The address of the user to check.
    /// @return amount The token amount.
    function safeBalanceOf(IERC20 token, address to) internal view returns (uint256 amount) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_BALANCE_OF, to));
        require(success && data.length >= 32, "BoringERC20: BalanceOf failed");
        amount = abi.decode(data, (uint256));
    }

    /// @notice Provides a gas-optimized totalSupply to avoid a redundant extcodesize check in addition to the returndatasize check.
    /// @param token The address of the ERC-20 token.
    /// @return totalSupply The token totalSupply.
    function safeTotalSupply(IERC20 token) internal view returns (uint256 totalSupply) {
        (bool success, bytes memory data) = address(token).staticcall(abi.encodeWithSelector(SIG_TOTALSUPPLY));
        require(success && data.length >= 32, "BoringERC20: totalSupply failed");
        totalSupply = abi.decode(data, (uint256));
    }

    /// @notice Provides a safe ERC20.transfer version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: Transfer failed");
    }

    /// @notice Provides a safe ERC20.transferFrom version for different ERC-20 implementations.
    /// Reverts on a failed transfer.
    /// @param token The address of the ERC-20 token.
    /// @param from Transfer tokens from.
    /// @param to Transfer tokens to.
    /// @param amount The token amount.
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(SIG_TRANSFER_FROM, from, to, amount));
        require(success && (data.length == 0 || abi.decode(data, (bool))), "BoringERC20: TransferFrom failed");
    }
}


// File contracts/mocks/ERC20StrategyMock.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;





// solhint-disable const-name-snakecase
// solhint-disable no-empty-blocks

contract ERC20StrategyMock is IStrategy {
    using BoringERC20 for IERC20;

    string public constant override name = "ERC20StrategyMock";
    string public constant override description = "Mock Strategy for testing";

    TokenType public constant override tokenType = TokenType.ERC20;
    address public immutable override contractAddress;
    uint256 public constant override tokenId = 0;

    IYieldBox public immutable override yieldBox;

    constructor(IYieldBox yieldBox_, address token) {
        yieldBox = yieldBox_;
        contractAddress = token;
    }

    /// Returns the total value the strategy holds (principle + gain) expressed in asset token amount.
    /// This should be cheap in gas to retrieve. Can return a bit less than the actual, but shouldn't return more.
    /// The gas cost of this function will be paid on any deposit or withdrawal onto and out of the YieldBox
    /// that uses this strategy. Also, anytime a protocol converts between shares and amount, this gets called.
    function currentBalance() public view override returns (uint256 amount) {
        return IERC20(contractAddress).balanceOf(address(this));
    }

    /// Returns the maximum amount that can be withdrawn
    function withdrawable() external view override returns (uint256 amount) {
        return IERC20(contractAddress).balanceOf(address(this));
    }

    /// Returns the maximum amount that can be withdrawn for a low gas fee
    /// When more than this amount is withdrawn it will trigger divesting from the actual strategy
    /// which will incur higher gas costs
    function cheapWithdrawable() external view override returns (uint256 amount) {
        return IERC20(contractAddress).balanceOf(address(this));
    }

    /// Is called by YieldBox to signal funds have been added, the strategy may choose to act on this
    /// When a large enough deposit is made, this should trigger the strategy to invest into the actual
    /// strategy. This function should normally NOT be used to invest on each call as that would be costly
    /// for small deposits.
    /// Only accept this call from the YieldBox
    function deposited(uint256 amount) external override {}

    /// Is called by the YieldBox to ask the strategy to withdraw to the user
    /// When a strategy keeps a little reserve for cheap withdrawals and the requested withdrawal goes over this amount,
    /// the strategy should divest enough from the strategy to complete the withdrawal and rebalance the reserve.
    /// Only accept this call from the YieldBox
    function withdraw(address to, uint256 amount) external override {
        if (contractAddress == yieldBox.wrappedNative()) {} else {
            IERC20(contractAddress).safeTransfer(to, amount);
        }
    }
}


// File @openzeppelin/contracts/utils/introspection/IERC165.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// File @openzeppelin/contracts/token/ERC721/IERC721.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}


// File @openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


// File @openzeppelin/contracts/utils/Address.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}


// File @openzeppelin/contracts/utils/Context.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


// File @openzeppelin/contracts/utils/Strings.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}


// File @openzeppelin/contracts/utils/introspection/ERC165.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}


// File @openzeppelin/contracts/token/ERC721/ERC721.sol@v4.5.0

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;







/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}


// File contracts/mocks/ERC721Mock.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract ERC721Mock is ERC721 {
     constructor() ERC721("ERC721Mock", "ERCM") {}
    
    function mint(
        address to,
        uint256 id
    ) public {
        _mint(to, id);
    }
}


// File contracts/mocks/ERC721StrategyMock.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;





// solhint-disable const-name-snakecase
// solhint-disable no-empty-blocks

contract ERC721StrategyMock is IStrategy, ERC721Receiver {
    string public constant override name = "ERC721StrategyMock";
    string public constant override description = "Mock Strategy for testing";

    TokenType public constant override tokenType = TokenType.ERC721;
    address public immutable override contractAddress;
    uint256 public immutable override tokenId;

    IYieldBox public immutable override yieldBox;

    constructor(IYieldBox yieldBox_, address token, uint256 tokenId_) {
        yieldBox = yieldBox_;
        contractAddress = token;
        tokenId = tokenId_;
    }

    /// Returns the total value the strategy holds (principle + gain) expressed in asset token amount.
    /// This should be cheap in gas to retrieve. Can return a bit less than the actual, but shouldn't return more.
    /// The gas cost of this function will be paid on any deposit or withdrawal onto and out of the YieldBox
    /// that uses this strategy. Also, anytime a protocol converts between shares and amount, this gets called.
    function currentBalance() public view override returns (uint256 amount) {
        return IERC721(contractAddress).balanceOf(address(this));
    }

    /// Returns the maximum amount that can be withdrawn
    function withdrawable() external view override returns (uint256 amount) {
        return IERC721(contractAddress).balanceOf(address(this));
    }

    /// Returns the maximum amount that can be withdrawn for a low gas fee
    /// When more than this amount is withdrawn it will trigger divesting from the actual strategy
    /// which will incur higher gas costs
    function cheapWithdrawable() external view override returns (uint256 amount) {
        return IERC721(contractAddress).balanceOf(address(this));
    }

    /// Is called by YieldBox to signal funds have been added, the strategy may choose to act on this
    /// When a large enough deposit is made, this should trigger the strategy to invest into the actual
    /// strategy. This function should normally NOT be used to invest on each call as that would be costly
    /// for small deposits.
    /// Only accept this call from the YieldBox
    function deposited(uint256 amount) external override {}

    /// Is called by the YieldBox to ask the strategy to withdraw to the user
    /// When a strategy keeps a little reserve for cheap withdrawals and the requested withdrawal goes over this amount,
    /// the strategy should divest enough from the strategy to complete the withdrawal and rebalance the reserve.
    /// Only accept this call from the YieldBox
    function withdraw(address to, uint256 amount) external override {
        IERC721(contractAddress).safeTransferFrom(address(this), to, tokenId);

    }
}


// File @boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol@v2.0.2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable;
}


// File @boringcrypto/boring-solidity/contracts/interfaces/IERC721.sol@v2.0.2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title ERC-721 Non-Fungible Token Standard
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x80ac58cd.
interface IERC721 /* is ERC165 */ {
    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    /// @notice Count all NFTs assigned to an owner
    /// @dev NFTs assigned to the zero address are considered invalid, and this
    ///  function throws for queries about the zero address.
    /// @param _owner An address for whom to query the balance
    /// @return The number of NFTs owned by `_owner`, possibly zero
    function balanceOf(address _owner) external view returns (uint256);

    /// @notice Find the owner of an NFT
    /// @dev NFTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an NFT
    /// @return The address of the owner of the NFT
    function ownerOf(uint256 _tokenId) external view returns (address);

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT. When transfer is complete, this function
    ///  checks if `_to` is a smart contract (code size > 0). If so, it calls
    ///  `onERC721Received` on `_to` and throws if the return value is not
    ///  `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    /// @param data Additional data with no specified format, sent in call to `_to`
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata data) external payable;

    /// @notice Transfers the ownership of an NFT from one address to another address
    /// @dev This works identically to the other function with an extra data parameter,
    ///  except this function just sets data to "".
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Transfer ownership of an NFT -- THE CALLER IS RESPONSIBLE
    ///  TO CONFIRM THAT `_to` IS CAPABLE OF RECEIVING NFTS OR ELSE
    ///  THEY MAY BE PERMANENTLY LOST
    /// @dev Throws unless `msg.sender` is the current owner, an authorized
    ///  operator, or the approved address for this NFT. Throws if `_from` is
    ///  not the current owner. Throws if `_to` is the zero address. Throws if
    ///  `_tokenId` is not a valid NFT.
    /// @param _from The current owner of the NFT
    /// @param _to The new owner
    /// @param _tokenId The NFT to transfer
    function transferFrom(address _from, address _to, uint256 _tokenId) external payable;

    /// @notice Change or reaffirm the approved address for an NFT
    /// @dev The zero address indicates there is no approved address.
    ///  Throws unless `msg.sender` is the current NFT owner, or an authorized
    ///  operator of the current owner.
    /// @param _approved The new approved NFT controller
    /// @param _tokenId The NFT to approve
    function approve(address _approved, uint256 _tokenId) external payable;

    /// @notice Enable or disable approval for a third party ("operator") to manage
    ///  all of `msg.sender`'s assets
    /// @dev Emits the ApprovalForAll event. The contract MUST allow
    ///  multiple operators per owner.
    /// @param _operator Address to add to the set of authorized operators
    /// @param _approved True if the operator is approved, false to revoke approval
    function setApprovalForAll(address _operator, bool _approved) external;

    /// @notice Get the approved address for a single NFT
    /// @dev Throws if `_tokenId` is not a valid NFT.
    /// @param _tokenId The NFT to find the approved address for
    /// @return The approved address for this NFT, or the zero address if there is none
    function getApproved(uint256 _tokenId) external view returns (address);

    /// @notice Query if an address is an authorized operator for another address
    /// @param _owner The address that owns the NFTs
    /// @param _operator The address that acts on behalf of the owner
    /// @return True if `_operator` is an approved operator for `_owner`, false otherwise
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

/// @title ERC-721 Non-Fungible Token Standard, optional metadata extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x5b5e139f.
interface IERC721Metadata /* is ERC721 */ {
    /// @notice A descriptive name for a collection of NFTs in this contract
    function name() external view returns (string memory _name);

    /// @notice An abbreviated name for NFTs in this contract
    function symbol() external view returns (string memory _symbol);

    /// @notice A distinct Uniform Resource Identifier (URI) for a given asset.
    /// @dev Throws if `_tokenId` is not a valid NFT. URIs are defined in RFC
    ///  3986. The URI may point to a JSON file that conforms to the "ERC721
    ///  Metadata JSON Schema".
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

/// @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
/// @dev See https://eips.ethereum.org/EIPS/eip-721
///  Note: the ERC-165 identifier for this interface is 0x780e9d63.
interface IERC721Enumerable /* is ERC721 */ {
    /// @notice Count NFTs tracked by this contract
    /// @return A count of valid NFTs tracked by this contract, where each one of
    ///  them has an assigned and queryable owner not equal to the zero address
    function totalSupply() external view returns (uint256);

    /// @notice Enumerate valid NFTs
    /// @dev Throws if `_index` >= `totalSupply()`.
    /// @param _index A counter less than `totalSupply()`
    /// @return The token identifier for the `_index`th NFT,
    ///  (sort order not specified)
    function tokenByIndex(uint256 _index) external view returns (uint256);

    /// @notice Enumerate NFTs assigned to an owner
    /// @dev Throws if `_index` >= `balanceOf(_owner)` or if
    ///  `_owner` is the zero address, representing invalid NFTs.
    /// @param _owner An address where we are interested in NFTs owned by them
    /// @param _index A counter less than `balanceOf(_owner)`
    /// @return The token identifier for the `_index`th NFT assigned to `_owner`,
    ///   (sort order not specified)
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}


// File @boringcrypto/boring-solidity/contracts/libraries/Base64.sol@v2.0.2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly
// solhint-disable no-empty-blocks

/// @title Base64
/// @author Brecht Devos - <brecht@loopring.org>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {

            } lt(dataPtr, endPtr) {

            } {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
                case 1 {
                    mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
                }
                case 2 {
                    mstore(sub(resultPtr, 1), shl(248, 0x3d))
                }
        }

        return result;
    }
}


// File @boringcrypto/boring-solidity/contracts/BoringBatchable.sol@v2.0.2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly

// WARNING!!!
// Combining BoringBatchable with msg.value can cause double spending issues
// https://www.paradigm.xyz/2021/08/two-rights-might-make-a-wrong/

contract BaseBoringBatchable {
    /// @dev Helper function to extract a useful revert message from a failed call.
    /// If the returned data is malformed or not correctly abi encoded then this call can fail itself.
    function _getRevertMsg(bytes memory _returnData) internal pure returns (string memory) {
        // If the _res length is less than 68, then the transaction failed silently (without a revert message)
        if (_returnData.length < 68) return "Transaction reverted silently";

        assembly {
            // Slice the sighash.
            _returnData := add(_returnData, 0x04)
        }
        return abi.decode(_returnData, (string)); // All that remains is the revert string
    }

    /// @notice Allows batched call to self (this contract).
    /// @param calls An array of inputs for each call.
    /// @param revertOnFail If True then reverts after a failed call and stops doing further calls.
    // F1: External is ok here because this is the batch function, adding it to a batch makes no sense
    // F2: Calls in the batch may be payable, delegatecall operates in the same context, so each call in the batch has access to msg.value
    // C3: The length of the loop is fully under user control, so can't be exploited
    // C7: Delegatecall is only used on the same contract, so it's safe
    function batch(bytes[] calldata calls, bool revertOnFail) external payable {
        for (uint256 i = 0; i < calls.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(calls[i]);
            if (!success && revertOnFail) {
                revert(_getRevertMsg(result));
            }
        }
    }
}

contract BoringBatchable is BaseBoringBatchable {
    /// @notice Call wrapper that performs `ERC20.permit` on `token`.
    /// Lookup `IERC20.permit`.
    // F6: Parameters can be used front-run the permit and the user's permit will fail (due to nonce or other revert)
    //     if part of a batch this could be used to grief once as the second call would not need the permit
    function permitToken(
        IERC20 token,
        address from,
        address to,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        token.permit(from, to, amount, deadline, v, r, s);
    }
}


// File contracts/BoringMath.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library BoringMath {
    function to128(uint256 a) internal pure returns (uint128 c) {
        require(a <= type(uint128).max, "BoringMath: uint128 Overflow");
        c = uint128(a);
    }

    function to64(uint256 a) internal pure returns (uint64 c) {
        require(a <= type(uint64).max, "BoringMath: uint64 Overflow");
        c = uint64(a);
    }

    function to32(uint256 a) internal pure returns (uint32 c) {
        require(a <= type(uint32).max, "BoringMath: uint32 Overflow");
        c = uint32(a);
    }

    function muldiv(
        uint256 value,
        uint256 mul,
        uint256 div,
        bool roundUp
    ) internal pure returns (uint256 result) {
        result = (value * mul) / div;
        if (roundUp && (result * div) / mul < value) {
            result++;
        }
    }
}


// File @boringcrypto/boring-solidity/contracts/BoringFactory.sol@v2.0.2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

contract BoringFactory {
    event LogDeploy(address indexed masterContract, bytes data, address indexed cloneAddress);

    /// @notice Mapping from clone contracts to their masterContract.
    mapping(address => address) public masterContractOf;

    /// @notice Mapping from masterContract to an array of all clones
    /// On mainnet events can be used to get this list, but events aren't always easy to retrieve and
    /// barely work on sidechains. While this adds gas, it makes enumerating all clones much easier.
    mapping(address => address[]) public clonesOf;

    /// @notice Returns the count of clones that exists for a specific masterContract
    /// @param masterContract The address of the master contract.
    /// @return cloneCount total number of clones for the masterContract.
    function clonesOfCount(address masterContract) public view returns (uint256 cloneCount) {
        cloneCount = clonesOf[masterContract].length;
    }

    /// @notice Deploys a given master Contract as a clone.
    /// Any ETH transferred with this call is forwarded to the new clone.
    /// Emits `LogDeploy`.
    /// @param masterContract The address of the contract to clone.
    /// @param data Additional abi encoded calldata that is passed to the new clone via `IMasterContract.init`.
    /// @param useCreate2 Creates the clone by using the CREATE2 opcode, in this case `data` will be used as salt.
    /// @return cloneAddress Address of the created clone contract.
    function deploy(
        address masterContract,
        bytes calldata data,
        bool useCreate2
    ) public payable returns (address cloneAddress) {
        require(masterContract != address(0), "BoringFactory: No masterContract");
        bytes20 targetBytes = bytes20(masterContract); // Takes the first 20 bytes of the masterContract's address

        if (useCreate2) {
            // each masterContract has different code already. So clones are distinguished by their data only.
            bytes32 salt = keccak256(data);

            // Creates clone, more info here: https://blog.openzeppelin.com/deep-dive-into-the-minimal-proxy-contract/
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create2(0, clone, 0x37, salt)
            }
        } else {
            assembly {
                let clone := mload(0x40)
                mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
                mstore(add(clone, 0x14), targetBytes)
                mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
                cloneAddress := create(0, clone, 0x37)
            }
        }
        masterContractOf[cloneAddress] = masterContract;
        clonesOf[masterContract].push(cloneAddress);

        IMasterContract(cloneAddress).init{value: msg.value}(data);

        emit LogDeploy(masterContract, data, cloneAddress);
    }
}


// File contracts/NativeTokenFactory.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;



struct NativeToken {
    string name;
    string symbol;
    uint8 decimals;
    string uri;
}

/// @title NativeTokenFactory
/// @author BoringCrypto (@Boring_Crypto)
/// @notice The NativeTokenFactory is a token factory to create ERC1155 tokens. This is used by YieldBox to create
/// native tokens in YieldBox. These have many benefits:
/// - low and predictable gas usage
/// - simplified approval
/// - no hidden features, all these tokens behave the same
/// TODO: MintBatch? BurnBatch?
contract NativeTokenFactory is AssetRegister, BoringFactory {
    using BoringMath for uint256;

    mapping(uint256 => NativeToken) public nativeTokens;
    mapping(uint256 => address) public owner;
    mapping(uint256 => address) public pendingOwner;

    event TokenCreated(address indexed creator, string name, string symbol, uint8 decimals, uint256 tokenId);
    event OwnershipTransferred(uint256 indexed tokenId, address indexed previousOwner, address indexed newOwner);

    // ***************** //
    // *** MODIFIERS *** //
    // ***************** //

    /// Modifier to check if the msg.sender is allowed to use funds belonging to the 'from' address.
    /// If 'from' is msg.sender, it's allowed.
    /// If 'msg.sender' is an address (an operator) that is approved by 'from', it's allowed.
    /// If 'msg.sender' is a clone of a masterContract that is approved by 'from', it's allowed.
    modifier allowed(address from) {
        if (from != msg.sender && !isApprovedForAll[from][msg.sender]) {
            address masterContract = masterContractOf[msg.sender];
            require(masterContract != address(0) && isApprovedForAll[from][masterContract], "YieldBox: Not approved");
        }
        _;
    }

    /// @notice Only allows the `owner` to execute the function.
    /// @param tokenId The `tokenId` that the sender has to be owner of.
    modifier onlyOwner(uint256 tokenId) {
        require(msg.sender == owner[tokenId], "NTF: caller is not the owner");
        _;
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param tokenId The `tokenId` of the token that ownership whose ownership will be transferred/renounced.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        uint256 tokenId,
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner(tokenId) {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "NTF: zero address");

            // Effects
            emit OwnershipTransferred(tokenId, owner[tokenId], newOwner);
            owner[tokenId] = newOwner;
            pendingOwner[tokenId] = address(0);
        } else {
            // Effects
            pendingOwner[tokenId] = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    /// @param tokenId The `tokenId` of the token that ownership is claimed for.
    function claimOwnership(uint256 tokenId) public {
        address _pendingOwner = pendingOwner[tokenId];

        // Checks
        require(msg.sender == _pendingOwner, "NTF: caller != pending owner");

        // Effects
        emit OwnershipTransferred(tokenId, owner[tokenId], _pendingOwner);
        owner[tokenId] = _pendingOwner;
        pendingOwner[tokenId] = address(0);
    }

    /// @notice Create a new native token. This will be an ERC1155 token. If later it's needed as an ERC20 token it can
    /// be wrapped into an ERC20 token. Native support for ERC1155 tokens is growing though.
    /// @param name The name of the token.
    /// @param symbol The symbol of the token.
    /// @param decimals The number of decimals of the token (this is just for display purposes). Should be set to 18 in normal cases.
    function createToken(
        string calldata name,
        string calldata symbol,
        uint8 decimals,
        string calldata uri
    ) public returns (uint32 tokenId) {
        // To keep each Token unique in the AssetRegister, we use the assetId as the tokenId. So for native assets, the tokenId is always equal to the assetId.
        tokenId = assets.length.to32();
        _registerAsset(TokenType.Native, address(0), NO_STRATEGY, tokenId);
        // Initial supply is 0, use owner can mint. For a fixed supply the owner can mint and revoke ownership.
        // The msg.sender is the initial owner, can be changed after.
        nativeTokens[tokenId] = NativeToken(name, symbol, decimals, uri);
        owner[tokenId] = msg.sender;

        emit TokenCreated(msg.sender, name, symbol, decimals, tokenId);
        emit TransferSingle(msg.sender, address(0), address(0), tokenId, 0);
        emit OwnershipTransferred(tokenId, address(0), msg.sender);
    }

    /// @notice The `owner` can mint tokens. If a fixed supply is needed, the `owner` should mint the totalSupply and renounce ownership.
    /// @param tokenId The token to be minted.
    /// @param to The account to transfer the minted tokens to.
    /// @param amount The amount of tokens to mint.
    function mint(
        uint256 tokenId,
        address to,
        uint256 amount
    ) public onlyOwner(tokenId) {
        _mint(to, tokenId, amount);
    }

    /// @notice Burns tokens. Only the holder of tokens can burn them.
    /// @param tokenId The token to be burned.
    /// @param amount The amount of tokens to burn.
    function burn(
        uint256 tokenId,
        address from,
        uint256 amount
    ) public allowed(from) {
        require(assets[tokenId].tokenType == TokenType.Native, "NTF: Not native");
        _burn(msg.sender, tokenId, amount);
    }
}


// File contracts/YieldBoxRebase.sol

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;










library YieldBoxRebase {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function _toShares(
        uint256 amount,
        uint256 totalShares_,
        uint256 totalAmount,
        bool roundUp
    ) internal pure returns (uint256 share) {
        // To prevent reseting the ratio due to withdrawal of all shares, we start with
        // 1 amount/1e8 shares already burned. This also starts with a 1 : 1e8 ratio which
        // functions like 8 decimal fixed point math. This prevents ratio attacks or inaccuracy
        // due to 'gifting' or rebasing tokens. (Up to a certain degree)
        totalAmount++;
        totalShares_ += 1e8;

        // Calculte the shares using te current amount to share ratio
        share = (amount * totalShares_) / totalAmount;

        // Default is to round down (Solidity), round up if required
        if (roundUp && (share * totalAmount) / totalShares_ < amount) {
            share++;
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function _toAmount(
        uint256 share,
        uint256 totalShares_,
        uint256 totalAmount,
        bool roundUp
    ) internal pure returns (uint256 amount) {
        // To prevent reseting the ratio due to withdrawal of all shares, we start with
        // 1 amount/1e8 shares already burned. This also starts with a 1 : 1e8 ratio which
        // functions like 8 decimal fixed point math. This prevents ratio attacks or inaccuracy
        // due to 'gifting' or rebasing tokens. (Up to a certain degree)
        totalAmount++;
        totalShares_ += 1e8;

        // Calculte the amount using te current amount to share ratio
        amount = (share * totalAmount) / totalShares_;

        // Default is to round down (Solidity), round up if required
        if (roundUp && (amount * totalShares_) / totalAmount < share) {
            amount++;
        }
    }
}


// File contracts/YieldBoxURIBuilder.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;





// solhint-disable quotes

contract YieldBoxURIBuilder {
    using BoringERC20 for IERC20;
    using Strings for uint256;
    using Base64 for bytes;

    struct AssetDetails {
        string tokenType;
        string name;
        string symbol;
        uint256 decimals;
    }

    function name(Asset calldata asset, string calldata nativeName) external view returns (string memory) {
        if (asset.strategy == NO_STRATEGY) {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return token.safeName();
            } else if (asset.tokenType == TokenType.ERC1155) {
                return
                    string(abi.encodePacked("ERC1155:", uint256(uint160(asset.contractAddress)).toHexString(20), "/", asset.tokenId.toString()));
            } else {
                return nativeName;
            }
        } else {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return string(abi.encodePacked(token.safeName(), " (", asset.strategy.name(), ")"));
            } else if (asset.tokenType == TokenType.ERC1155) {
                return
                    string(
                        abi.encodePacked(
                            string(
                                abi.encodePacked(
                                    "ERC1155:",
                                    uint256(uint160(asset.contractAddress)).toHexString(20),
                                    "/",
                                    asset.tokenId.toString()
                                )
                            ),
                            " (",
                            asset.strategy.name(),
                            ")"
                        )
                    );
            } else {
                return string(abi.encodePacked(nativeName, " (", asset.strategy.name(), ")"));
            }
        }
    }

    function symbol(Asset calldata asset, string calldata nativeSymbol) external view returns (string memory) {
        if (asset.strategy == NO_STRATEGY) {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return token.safeSymbol();
            } else if (asset.tokenType == TokenType.ERC1155) {
                return "ERC1155";
            } else {
                return nativeSymbol;
            }
        } else {
            if (asset.tokenType == TokenType.ERC20) {
                IERC20 token = IERC20(asset.contractAddress);
                return string(abi.encodePacked(token.safeSymbol(), " (", asset.strategy.name(), ")"));
            } else if (asset.tokenType == TokenType.ERC1155) {
                return string(abi.encodePacked("ERC1155", " (", asset.strategy.name(), ")"));
            } else {
                return string(abi.encodePacked(nativeSymbol, " (", asset.strategy.name(), ")"));
            }
        }
    }

    function decimals(Asset calldata asset, uint8 nativeDecimals) external view returns (uint8) {
        if (asset.tokenType == TokenType.ERC1155) {
            return 0;
        } else if (asset.tokenType == TokenType.ERC20) {
            IERC20 token = IERC20(asset.contractAddress);
            return token.safeDecimals();
        } else {
            return nativeDecimals;
        }
    }

    function uri(
        Asset calldata asset,
        NativeToken calldata nativeToken,
        uint256 totalSupply,
        address owner
    ) external view returns (string memory) {
        AssetDetails memory details;
        if (asset.tokenType == TokenType.ERC1155) {
            // Contracts can't retrieve URIs, so the details are out of reach
            details.tokenType = "ERC1155";
            details.name = string(
                abi.encodePacked("ERC1155:", uint256(uint160(asset.contractAddress)).toHexString(20), "/", asset.tokenId.toString())
            );
            details.symbol = "ERC1155";
        } else if (asset.tokenType == TokenType.ERC20) {
            IERC20 token = IERC20(asset.contractAddress);
            details = AssetDetails("ERC20", token.safeName(), token.safeSymbol(), token.safeDecimals());
        } else {
            // Native
            details.tokenType = "Native";
            details.name = nativeToken.name;
            details.symbol = nativeToken.symbol;
            details.decimals = nativeToken.decimals;
        }

        string memory properties = string(
            asset.tokenType != TokenType.Native
                ? abi.encodePacked(',"tokenAddress":"', uint256(uint160(asset.contractAddress)).toHexString(20), '"')
                : abi.encodePacked(',"totalSupply":', totalSupply.toString(), ',"fixedSupply":', owner == address(0) ? "true" : "false")
        );

        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    abi
                        .encodePacked(
                            '{"name":"',
                            details.name,
                            '","symbol":"',
                            details.symbol,
                            '"',
                            asset.tokenType == TokenType.ERC1155 ? "" : ',"decimals":',
                            asset.tokenType == TokenType.ERC1155 ? "" : details.decimals.toString(),
                            ',"properties":{"strategy":"',
                            uint256(uint160(address(asset.strategy))).toHexString(20),
                            '","tokenType":"',
                            details.tokenType,
                            '"',
                            properties,
                            asset.tokenType == TokenType.ERC1155 ? string(abi.encodePacked(',"tokenId":', asset.tokenId.toString())) : "",
                            "}}"
                        )
                        .encode()
                )
            );
    }
}


// File contracts/YieldBox.sol

// SPDX-License-Identifier: UNLICENSED

// The YieldBox
// The original BentoBox is owned by the Sushi team to set strategies for each token. Abracadabra wanted different strategies, which led to
// them launching their own DegenBox. The YieldBox solves this by allowing an unlimited number of strategies for each token in a fully
// permissionless manner. The YieldBox has no owner and operates fully permissionless.

// Other improvements:
// Better system to make sure the token to share ratio doesn't reset.
// Full support for rebasing tokens.

// This contract stores funds, handles their transfers, approvals and strategies.

// Copyright (c) 2021, 2022 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

// Since the contract is permissionless, only one deployment per chain is needed. If it's not yet deployed
// on a chain or if you want to make a derivative work, contact @BoringCrypto. The core of YieldBox is
// copyrighted. Most of the contracts that it builds on are open source though.

// BEWARE: Still under active development
// Security review not done yet

pragma solidity ^0.8.9;
pragma experimental ABIEncoderV2;















// solhint-disable no-empty-blocks

/// @title YieldBox
/// @author BoringCrypto, Keno
/// @notice The YieldBox is a vault for tokens. The stored tokens can assigned to strategies.
/// Yield from this will go to the token depositors.
/// Any funds transfered directly onto the YieldBox will be lost, use the deposit function instead.
contract YieldBox is BoringBatchable, NativeTokenFactory, ERC1155TokenReceiver, ERC721Receiver {
    using BoringAddress for address;
    using BoringERC20 for IERC20;
    using BoringERC20 for IWrappedNative;
    using YieldBoxRebase for uint256;

    // ************** //
    // *** EVENTS *** //
    // ************** //

    // TODO: Add events

    // ******************* //
    // *** CONSTRUCTOR *** //
    // ******************* //

    IWrappedNative public immutable wrappedNative;
    YieldBoxURIBuilder public immutable uriBuilder;

    constructor(IWrappedNative wrappedNative_, YieldBoxURIBuilder uriBuilder_) {
        wrappedNative = wrappedNative_;
        uriBuilder = uriBuilder_;
    }

    // ************************** //
    // *** INTERNAL FUNCTIONS *** //
    // ************************** //

    /// @dev Returns the total balance of `token` this contracts holds,
    /// plus the total amount this contract thinks the strategy holds.
    function _tokenBalanceOf(Asset storage asset) internal view returns (uint256 amount) {
        if (asset.strategy == NO_STRATEGY) {
            if (asset.tokenType == TokenType.ERC20) {
                return IERC20(asset.contractAddress).safeBalanceOf(address(this));
            } else if (asset.tokenType == TokenType.ERC1155) {
                return IERC1155(asset.contractAddress).balanceOf(address(this), asset.tokenId);
            } else {
                return IERC721(asset.contractAddress).balanceOf(address(this));
            }
        } else {
            return asset.strategy.currentBalance();
        }
    }

    // ************************ //
    // *** PUBLIC FUNCTIONS *** //
    // ************************ //

    /// @notice Deposit an amount of `token` represented in either `amount` or `share`.
    /// @param assetId The id of the asset.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @param amount Token amount in native representation to deposit.
    /// @param share Token amount represented in shares to deposit. Takes precedence over `amount`.
    /// @param minShareOut The minimum amount of shares required for the transaction to continue.
    /// Useful to prevent front-running and ratio attacks due to 1st depositor ratio influence.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount repesented in shares.
    function depositAsset(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share,
        uint256 minShareOut
    ) public allowed(from) returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType != TokenType.Native, "YieldBox: can't deposit Native");
        require(asset.tokenType != TokenType.ERC721, "YieldBox: use depositNFT");

        // Effects
        uint256 totalAmount = _tokenBalanceOf(asset);
        if (share == 0) {
            // value of the share may be lower than the amount due to rounding, that's ok
            share = amount._toShares(totalSupply[assetId], totalAmount, false);
        } else {
            // amount may be lower than the value of share due to rounding, in that case, add 1 to amount (Always round up)
            amount = share._toAmount(totalSupply[assetId], totalAmount, true);
        }
        require(share >= minShareOut, "YieldBox: shareOut too low");

        _mint(to, assetId, share);

        address destination = asset.strategy == NO_STRATEGY ? address(this) : address(asset.strategy);

        // Interactions
        if (asset.tokenType == TokenType.ERC20) {
            IERC20(asset.contractAddress).safeTransferFrom(from, destination, amount);
        } else {
            // ERC1155
            // When depositing yieldBox tokens into the yieldBox, things can be simplified
            if (asset.contractAddress == address(this)) {
                _transferSingle(from, destination, asset.tokenId, amount);
            } else {
                IERC1155(asset.contractAddress).safeTransferFrom(from, destination, asset.tokenId, amount, "");
            }
        }

        if (asset.strategy != NO_STRATEGY) {
            asset.strategy.deposited(amount);
        }

        return (amount, share);
    }

    /// @notice Deposit an NFT asset
    /// @param assetId The id of the asset.
    /// @param from which account to pull the tokens.
    /// @param to which account to push the tokens.
    /// @return amountOut The amount deposited.
    /// @return shareOut The deposited amount represented in shares.
    function depositNFTAsset(
        uint256 assetId,
        address from,
        address to
    ) public allowed(from) returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType == TokenType.ERC721, "YieldBox: not ERC721");

        // Effects
        _mint(to, assetId, 1);

        address destination = asset.strategy == NO_STRATEGY ? address(this) : address(asset.strategy);

        // Interactions
        IERC721(asset.contractAddress).safeTransferFrom(from, destination, asset.tokenId);

        if (asset.strategy != NO_STRATEGY) {
            asset.strategy.deposited(1);
        }

        return (1, 1);
    }

    function depositETHAsset(
        uint256 assetId,
        address to,
        uint256 minShareOut
    )
        public
        payable
        returns (
            // TODO: allow shares with refund?
            uint256 amountOut,
            uint256 shareOut
        )
    {
        // Checks
        require(msg.value > 0, "YieldBox: no ETH sent");
        Asset storage asset = assets[assetId];
        require(asset.tokenType == TokenType.ERC20 && asset.contractAddress == address(wrappedNative), "YieldBox: not wrappedNative");

        // Effects
        uint256 share = msg.value._toShares(totalSupply[assetId], _tokenBalanceOf(asset), false);
        require(share >= minShareOut, "YieldBox: shareOut too low");

        _mint(to, assetId, share);

        // Interactions
        wrappedNative.deposit{ value: msg.value }();
        if (asset.strategy != NO_STRATEGY) {
            // Strategies always receive wrappedNative (supporting both wrapped and raw native tokens adds too much complexity)
            wrappedNative.safeTransfer(address(asset.strategy), msg.value);
        }

        if (asset.strategy != NO_STRATEGY) {
            asset.strategy.deposited(msg.value);
        }

        return (msg.value, share);
    }

    /// @notice Withdraws an amount of `token` from a user account.
    /// @param assetId The id of the asset.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param amount of tokens. Either one of `amount` or `share` needs to be supplied.
    /// @param share Like above, but `share` takes precedence over `amount`.
    function withdraw(
        uint256 assetId,
        address from,
        address to,
        uint256 amount,
        uint256 share
    ) public allowed(from) returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType != TokenType.Native, "YieldBox: can't withdraw Native");
        require(asset.tokenType != TokenType.ERC721, "YieldBox: use withdrawNFT");

        // Effects
        uint256 totalAmount = _tokenBalanceOf(asset);
        if (share == 0) {
            // value of the share paid could be lower than the amount paid due to rounding, in that case, add a share (Always round up)
            share = amount._toShares(totalSupply[assetId], totalAmount, true);
        } else {
            // amount may be lower than the value of share due to rounding, that's ok
            amount = share._toAmount(totalSupply[assetId], totalAmount, false);
        }

        _burn(from, assetId, share);

        // Interactions
        if (asset.strategy == NO_STRATEGY) {
            if (asset.tokenType == TokenType.ERC20) {
                // Native tokens are always unwrapped when withdrawn
                if (asset.contractAddress == address(wrappedNative)) {
                    wrappedNative.withdraw(amount);
                    to.sendNative(amount);
                } else {
                    IERC20(asset.contractAddress).safeTransfer(to, amount);
                }
            } else {
                // IERC1155
                IERC1155(asset.contractAddress).safeTransferFrom(address(this), to, asset.tokenId, amount, "");
            }
        } else {
            asset.strategy.withdraw(to, amount);
        }

        return (amount, share);
    }

    /// @notice Withdraws an NFT from a user account.
    /// @param assetId The id of the asset.
    /// @param from which user to pull the NFT.
    /// @param to which user to push the NFT.
    function withdrawNFT(
        uint256 assetId,
        address from,
        address to
    ) public allowed(from) returns (uint256 amountOut, uint256 shareOut) {
        // Checks
        Asset storage asset = assets[assetId];
        require(asset.tokenType == TokenType.ERC721, "YieldBox: use withdraw");

        // Effects
        // Unauthorized users can't withdraw NFTs as it an underflow revert would occur
        _burn(from, assetId, 1);

        // Interactions
        if (asset.strategy == NO_STRATEGY) {
            IERC721(asset.contractAddress).safeTransferFrom(address(this), to, asset.tokenId);
        } else {
            asset.strategy.withdraw(to, 1);
        }

        return (1, 1);
    }

    function _requireTransferAllowed(address from) internal view override allowed(from) {}

    /// @notice Transfer shares from a user account to another one.
    /// @param from which user to pull the tokens.
    /// @param to which user to push the tokens.
    /// @param assetId The id of the asset.
    /// @param share The amount of `token` in shares.
    function transfer(
        address from,
        address to,
        uint256 assetId,
        uint256 share
    ) public allowed(from) {
        _transferSingle(from, to, assetId, share);
    }

    function batchTransfer(
        address from,
        address to,
        uint256[] calldata assetIds_,
        uint256[] calldata shares_
    ) public allowed(from) {
        _transferBatch(from, to, assetIds_, shares_);
    }

    /// @notice Transfer shares from a user account to multiple other ones.
    /// @param assetId The id of the asset.
    /// @param from which user to pull the tokens.
    /// @param tos The receivers of the tokens.
    /// @param shares The amount of `token` in shares for each receiver in `tos`.
    function transferMultiple(
        address from,
        address[] calldata tos,
        uint256 assetId,
        uint256[] calldata shares
    ) public allowed(from) {
        // Checks
        uint256 len = tos.length;
        for (uint256 i = 0; i < len; i++) {
            require(tos[i] != address(0), "YieldBox: to not set"); // To avoid a bad UI from burning funds
        }

        // Effects
        uint256 totalAmount;
        for (uint256 i = 0; i < len; i++) {
            address to = tos[i];
            uint256 share_ = shares[i];
            balanceOf[to][assetId] += share_;
            totalAmount += share_;
            emit TransferSingle(msg.sender, from, to, assetId, share_);
        }
        balanceOf[from][assetId] -= totalAmount;
    }

    function setApprovalForAll(address operator, bool approved) external override {
        // Checks
        require(operator != address(0), "YieldBox: operator not set"); // Important for security
        require(masterContractOf[msg.sender] == address(0), "YieldBox: user is clone");
        require(operator != address(this), "YieldBox: can't approve yieldBox");

        // Effects
        isApprovedForAll[msg.sender][operator] = approved;

        emit ApprovalForAll(msg.sender, operator, approved);
    }

    // This functionality has been split off into a separate contract. This is only a view function, so gas usage isn't a huge issue.
    // This keeps the YieldBox contract smaller, so it can be optimized more.
    function uri(uint256 assetId) external view override returns (string memory) {
        return uriBuilder.uri(assets[assetId], nativeTokens[assetId], totalSupply[assetId], owner[assetId]);
    }

    function name(uint256 assetId) external view returns (string memory) {
        return uriBuilder.name(assets[assetId], nativeTokens[assetId].name);
    }

    function symbol(uint256 assetId) external view returns (string memory) {
        return uriBuilder.symbol(assets[assetId], nativeTokens[assetId].symbol);
    }

    function decimals(uint256 assetId) external view returns (uint8) {
        return uriBuilder.decimals(assets[assetId], nativeTokens[assetId].decimals);
    }

    // Included to support unwrapping wrapped native tokens such as WETH
    receive() external payable {}

    // Helper functions

    function assetTotals(uint256 assetId) external view returns (uint256 totalShare, uint256 totalAmount) {
        totalShare = totalSupply[assetId];
        totalAmount = _tokenBalanceOf(assets[assetId]);
    }

    /// @dev Helper function to represent an `amount` of `token` in shares.
    /// @param assetId The id of the asset.
    /// @param amount The `token` amount.
    /// @param roundUp If the result `share` should be rounded up.
    /// @return share The token amount represented in shares.
    function toShare(
        uint256 assetId,
        uint256 amount,
        bool roundUp
    ) external view returns (uint256 share) {
        if (assets[assetId].tokenType == TokenType.Native || assets[assetId].tokenType == TokenType.ERC721) {
            share = amount;
        } else {
            share = amount._toShares(totalSupply[assetId], _tokenBalanceOf(assets[assetId]), roundUp);
        }
    }

    /// @dev Helper function represent shares back into the `token` amount.
    /// @param assetId The id of the asset.
    /// @param share The amount of shares.
    /// @param roundUp If the result should be rounded up.
    /// @return amount The share amount back into native representation.
    function toAmount(
        uint256 assetId,
        uint256 share,
        bool roundUp
    ) external view returns (uint256 amount) {
        if (assets[assetId].tokenType == TokenType.Native || assets[assetId].tokenType == TokenType.ERC721) {
            amount = share;
        } else {
            amount = share._toAmount(totalSupply[assetId], _tokenBalanceOf(assets[assetId]), roundUp);
        }
    }

    /// @dev Helper function represent the balance in `token` amount for a `user` for an `asset`.
    /// @param user The `user` to get the amount for.
    /// @param assetId The id of the asset.
    function amountOf(address user, uint256 assetId) external view returns (uint256 amount) {
        if (assets[assetId].tokenType == TokenType.Native || assets[assetId].tokenType == TokenType.ERC721) {
            amount = balanceOf[user][assetId];
        } else {
            amount = balanceOf[user][assetId]._toAmount(totalSupply[assetId], _tokenBalanceOf(assets[assetId]), false);
        }
    }

    function deposit(
        TokenType tokenType,
        address contractAddress,
        IStrategy strategy,
        uint256 tokenId,
        address from,
        address to,
        uint256 amount,
        uint256 share,
        uint256 minShareOut
    ) public returns (uint256 amountOut, uint256 shareOut) {
        if (tokenType == TokenType.Native) {
            // If native token, register it as an ERC1155 asset (as that's what it is)
            return depositAsset(registerAsset(TokenType.ERC1155, address(this), strategy, tokenId), from, to, amount, share, minShareOut);
        } else {
            return depositAsset(registerAsset(tokenType, contractAddress, strategy, tokenId), from, to, amount, share, minShareOut);
        }
    }

    function depositNFT(
        address contractAddress,
        IStrategy strategy,
        uint256 tokenId,
        address from,
        address to
    ) public returns (uint256 amountOut, uint256 shareOut) {
        return depositNFTAsset(registerAsset(TokenType.ERC721, contractAddress, strategy, tokenId), from, to);
    }

    function depositETH(
        IStrategy strategy,
        address to,
        uint256 minShareOut
    ) public payable returns (uint256 amountOut, uint256 shareOut) {
        return depositETHAsset(registerAsset(TokenType.ERC20, address(wrappedNative), strategy, 0), to, minShareOut);
    }
}


// File contracts/mocks/MaliciousMasterContractMock.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;


contract MaliciousMasterContractMock is IMasterContract {
    function init(bytes calldata) external payable override {
        return;
    }

    function attack(YieldBox yieldBox) public {
        yieldBox.setApprovalForAll(address(this), true);
    }
}


// File contracts/mocks/MasterContractFullCycleMock.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;


contract MasterContractFullCycleMock is IMasterContract {
    YieldBox public immutable yieldBox;
    address public deployer;
    address public token;
    address public erc1155;
    IStrategy public tokenStrategy;
    IStrategy public erc1155Strategy;
    IStrategy public ethStrategy;
    IStrategy private constant ZERO = IStrategy(address(0));

    constructor(YieldBox _yieldBox) {
        yieldBox = _yieldBox;
    }

    function init(bytes calldata data) external payable override {
        (deployer, token, erc1155, tokenStrategy, erc1155Strategy, ethStrategy) = abi.decode(
            data,
            (address, address, address, IStrategy, IStrategy, IStrategy)
        );
        return;
    }

    function run() public payable {
        yieldBox.deposit(TokenType.ERC20, token, ZERO, 0, deployer, deployer, 1000, 0, 0);
        yieldBox.deposit(TokenType.ERC20, token, ZERO, 0, deployer, deployer, 0, 1000_00000000, 0);
        yieldBox.withdraw(2, deployer, deployer, 1000, 0);
        yieldBox.withdraw(2, deployer, deployer, 0, 1000_00000000);

        yieldBox.deposit(TokenType.ERC1155, erc1155, ZERO, 42, deployer, deployer, 1000, 0, 0);
        yieldBox.deposit(TokenType.ERC1155, erc1155, ZERO, 42, deployer, deployer, 0, 1000_00000000, 0);
        yieldBox.withdraw(3, deployer, deployer, 1000, 0);
        yieldBox.withdraw(3, deployer, deployer, 0, 1000_00000000);

        yieldBox.depositETH{ value: 1000 }(ZERO, deployer, 0);
        yieldBox.withdraw(4, deployer, deployer, 1000, 0);

        yieldBox.deposit(TokenType.ERC20, token, tokenStrategy, 0, deployer, deployer, 1000, 0, 0);
        yieldBox.deposit(TokenType.ERC20, token, tokenStrategy, 0, deployer, deployer, 0, 1000_00000000, 0);
        yieldBox.withdraw(5, deployer, deployer, 1000, 0);
        yieldBox.withdraw(5, deployer, deployer, 0, 1000_00000000);

        yieldBox.deposit(TokenType.ERC1155, erc1155, erc1155Strategy, 42, deployer, deployer, 1000, 0, 0);
        yieldBox.deposit(TokenType.ERC1155, erc1155, erc1155Strategy, 42, deployer, deployer, 0, 1000_00000000, 0);
        yieldBox.withdraw(6, deployer, deployer, 1000, 0);
        yieldBox.withdraw(6, deployer, deployer, 0, 1000_00000000);

        yieldBox.depositETH{ value: 1000 }(ethStrategy, deployer, 0);
        yieldBox.withdraw(7, deployer, deployer, 1000, 0);
    }
}


// File contracts/mocks/MasterContractMock.sol

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.9;


contract MasterContractMock is IMasterContract {
    YieldBox public immutable yieldBox;

    constructor(YieldBox _yieldBox) {
        yieldBox = _yieldBox;
    }

    function deposit(uint256 id, uint256 amount) public {
        yieldBox.depositAsset(id, msg.sender, address(this), 0, amount, 0);
    }

    function setApproval() public {
        yieldBox.setApprovalForAll(msg.sender, true);
    }

    function init(bytes calldata) external payable override {
        return;
    }
}


// File contracts/mocks/SushiBarMock.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// solhint-disable const-name-snakecase

// SushiBar is the coolest bar in town. You come in with some Sushi, and leave with more! The longer you stay, the more Sushi you get.
// This contract handles swapping to and from xSushi, SushiSwap's staking token.
contract SushiBarMock is ERC20 {
    ERC20 public sushi;
    uint256 public override totalSupply;
    string public constant name = "SushiBar";
    string public constant symbol = "xSushi";

    // Define the Sushi token contract
    constructor(ERC20 _sushi) {
        sushi = _sushi;
    }

    // Enter the bar. Pay some SUSHIs. Earn some shares.
    // Locks Sushi and mints xSushi
    function enter(uint256 _amount) public {
        // Gets the amount of Sushi locked in the contract
        uint256 totalSushi = sushi.balanceOf(address(this));
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply;
        // If no xSushi exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalSushi == 0) {
            _mint(msg.sender, _amount);
        }
        // Calculate and mint the amount of xSushi the Sushi is worth. The ratio will change overtime,
        // as xSushi is burned/minted and Sushi deposited + gained from fees / withdrawn.
        else {
            uint256 what = (_amount * totalShares) / totalSushi;
            _mint(msg.sender, what);
        }
        // Lock the Sushi in the contract
        sushi.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your SUSHIs.
    // Unclocks the staked + gained Sushi and burns xSushi
    function leave(uint256 _share) public {
        // Gets the amount of xSushi in existence
        uint256 totalShares = totalSupply;
        // Calculates the amount of Sushi the xSushi is worth
        uint256 what = (_share * sushi.balanceOf(address(this))) / totalShares;
        _burn(msg.sender, _share);
        sushi.transfer(msg.sender, what);
    }

    function _mint(address account, uint256 amount) internal {
        totalSupply += amount;
        balanceOf[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        balanceOf[account] -= amount;
        totalSupply -= amount;
        emit Transfer(account, address(0), amount);
    }
}


// File contracts/mocks/YieldBoxRebaseMock.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

contract YieldBoxRebaseMock {
    using YieldBoxRebase for uint256;

    uint256 public totalAmount;
    uint256 public totalShares;

    function toShare(uint256 amount, bool roundUp) public view returns (uint256 share) {
        share = amount._toShares(totalShares, totalAmount, roundUp);
    }

    function toAmount(uint256 share, bool roundUp) public view returns (uint256 amount) {
        amount = share._toAmount(totalShares, totalAmount, roundUp);
    }

    function deposit(uint256 share, uint256 amount) public returns (uint256 shareOut, uint256 amountOut) {
        if (share == 0) {
            // value of the share may be lower than the amount due to rounding, that's ok
            share = amount._toShares(totalShares, totalAmount, false);
        } else {
            // amount may be lower than the value of share due to rounding, in that case, add 1 to amount (Always round up)
            amount = share._toAmount(totalShares, totalAmount, true);
        }
        totalAmount += amount;
        totalShares += share;
        return (share, amount);
    }

    function withdraw(uint256 share, uint256 amount) public returns (uint256 shareOut, uint256 amountOut) {
        if (share == 0) {
            // value of the share paid could be lower than the amount paid due to rounding, in that case, add a share (Always round up)
            share = amount._toShares(totalShares, totalAmount, true);
        } else {
            // amount may be lower than the value of share due to rounding, that's ok
            amount = share._toAmount(totalShares, totalAmount, false);
        }

        totalAmount -= amount;
        totalShares -= share;
        return (share, amount);
    }

    function gain(uint256 amount) public {
        totalAmount += amount;
    }

    function lose(uint256 amount) public {
        totalAmount -= amount;
    }
}


// File contracts/samples/Escrow.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

struct Offer {
    address owner;
    uint256 assetFrom;
    uint256 assetTo;
    uint256 shareFrom;
    uint256 shareTo;
    bool closed;
}

contract Escrow {
    YieldBox public yieldBox;

    constructor(YieldBox _yieldBox) {
        yieldBox = _yieldBox;
    }

    Offer[] public offers;

    function make(
        uint256 assetFrom,
        uint256 assetTo,
        uint256 shareFrom,
        uint256 shareTo
    ) public {
        offers.push(Offer(msg.sender, assetFrom, assetTo, shareFrom, shareTo, false));
    }

    function take(uint256 offerId) public {
        Offer memory offer = offers[offerId];
        yieldBox.transfer(msg.sender, offer.owner, offer.assetFrom, offer.shareFrom);
        yieldBox.transfer(offer.owner, msg.sender, offer.assetTo, offer.shareTo);
        offers[offerId].closed = true;
    }

    function cancel(uint256 offerId) public {
        require(offers[offerId].owner == msg.sender);
        offers[offerId].closed = true;
    }
}


// File contracts/samples/helloworld.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// An example a contract that stores tokens in the YieldBox.
// PS. This isn't good code, just kept it simple to illustrate usage.
contract HelloWorld {
    YieldBox public immutable yieldBox;
    uint256 public immutable assetId;

    constructor(YieldBox _yieldBox, IERC20 token) {
        yieldBox = _yieldBox;
        assetId = _yieldBox.registerAsset(TokenType.ERC20, address(token), IStrategy(address(0)), 0);
    }

    mapping(address => uint256) public yieldBoxShares;

    // Deposits an amount of token into the YieldBox. YieldBox shares are given to the HelloWorld contract and
    // assigned to the user in yieldBoxShares.
    // Don't deposit twice, you'll lose the first deposit ;)
    function deposit(uint256 amount) public {
        uint256 shares;
        (, shares) = yieldBox.depositAsset(assetId, msg.sender, address(this), amount, 0, 0);
        yieldBoxShares[msg.sender] += shares;
    }

    // This will return the current value in amount of the YieldBox shares.
    // Through a strategy, the value can go up over time, although in this example no strategy is selected.
    function balance() public view returns (uint256 amount) {
        return yieldBox.toAmount(assetId, yieldBoxShares[msg.sender], false);
    }

    // Withdraw all shares from the YieldBox and receive the token.
    function withdraw() public {
        yieldBox.withdraw(assetId, address(this), msg.sender, 0, yieldBoxShares[msg.sender]);
        yieldBoxShares[msg.sender] = 0;
    }
}


// File contracts/samples/lending/ISwapper.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISwapper {
    /// @notice Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for at least 'amountToMin' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Returns the amount of tokens 'to' transferred to BentoBox.
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swap(
        uint256 fromAssetId,
        uint256 toAssetId,
        address recipient,
        uint256 shareToMin,
        uint256 shareFrom
    ) external returns (uint256 extraShare, uint256 shareReturned);

    /// @notice Calculates the amount of token 'from' needed to complete the swap (amountFrom),
    /// this should be less than or equal to amountFromMax.
    /// Withdraws 'amountFrom' of token 'from' from the BentoBox account for this swapper.
    /// Swaps it for exactly 'exactAmountTo' of token 'to'.
    /// Transfers the swapped tokens of 'to' into the BentoBox using a plain ERC20 transfer.
    /// Transfers allocated, but unused 'from' tokens within the BentoBox to 'refundTo' (amountFromMax - amountFrom).
    /// Returns the amount of 'from' tokens withdrawn from BentoBox (amountFrom).
    /// (The BentoBox skim function will be used by the caller to get the swapped funds).
    function swapExact(
        uint256 fromAssetId,
        uint256 toAssetId,
        address recipient,
        address refundTo,
        uint256 shareFromSupplied,
        uint256 shareToExact
    ) external returns (uint256 shareUsed, uint256 shareReturned);
}


// File @boringcrypto/boring-solidity/contracts/BoringOwnable.sol@v2.0.2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Source: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol + Claimable.sol
// Simplified by BoringCrypto

contract BoringOwnableData {
    address public owner;
    address public pendingOwner;
}

contract BoringOwnable is BoringOwnableData {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /// @notice `owner` defaults to msg.sender on construction.
    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /// @notice Transfers ownership to `newOwner`. Either directly or claimable by the new pending owner.
    /// Can only be invoked by the current `owner`.
    /// @param newOwner Address of the new owner.
    /// @param direct True if `newOwner` should be set immediately. False if `newOwner` needs to use `claimOwnership`.
    /// @param renounce Allows the `newOwner` to be `address(0)` if `direct` and `renounce` is True. Has no effect otherwise.
    function transferOwnership(
        address newOwner,
        bool direct,
        bool renounce
    ) public onlyOwner {
        if (direct) {
            // Checks
            require(newOwner != address(0) || renounce, "Ownable: zero address");

            // Effects
            emit OwnershipTransferred(owner, newOwner);
            owner = newOwner;
            pendingOwner = address(0);
        } else {
            // Effects
            pendingOwner = newOwner;
        }
    }

    /// @notice Needs to be called by `pendingOwner` to claim ownership.
    function claimOwnership() public {
        address _pendingOwner = pendingOwner;

        // Checks
        require(msg.sender == _pendingOwner, "Ownable: caller != pending owner");

        // Effects
        emit OwnershipTransferred(owner, _pendingOwner);
        owner = _pendingOwner;
        pendingOwner = address(0);
    }

    /// @notice Only allows the `owner` to execute the function.
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: caller is not the owner");
        _;
    }
}


// File @boringcrypto/boring-solidity/contracts/libraries/BoringRebase.sol@v2.0.2

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Rebase {
    uint128 elastic;
    uint128 base;
}

/// @notice A rebasing library using overflow-/underflow-safe math.
library RebaseLibrary {
    /// @notice Calculates the base value in relationship to `elastic` and `total`.
    function toBase(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (uint256 base) {
        if (total.elastic == 0) {
            base = elastic;
        } else {
            base = (elastic * total.base) / total.elastic;
            if (roundUp && (base * total.elastic) / total.base < elastic) {
                base++;
            }
        }
    }

    /// @notice Calculates the elastic value in relationship to `base` and `total`.
    function toElastic(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (uint256 elastic) {
        if (total.base == 0) {
            elastic = base;
        } else {
            elastic = (base * total.elastic) / total.base;
            if (roundUp && (elastic * total.base) / total.elastic < base) {
                elastic++;
            }
        }
    }

    /// @notice Add `elastic` to `total` and doubles `total.base`.
    /// @return (Rebase) The new total.
    /// @return base in relationship to `elastic`.
    function add(
        Rebase memory total,
        uint256 elastic,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 base) {
        base = toBase(total, elastic, roundUp);
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return (total, base);
    }

    /// @notice Sub `base` from `total` and update `total.elastic`.
    /// @return (Rebase) The new total.
    /// @return elastic in relationship to `base`.
    function sub(
        Rebase memory total,
        uint256 base,
        bool roundUp
    ) internal pure returns (Rebase memory, uint256 elastic) {
        elastic = toElastic(total, base, roundUp);
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return (total, elastic);
    }

    /// @notice Add `elastic` and `base` to `total`.
    function add(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic += uint128(elastic);
        total.base += uint128(base);
        return total;
    }

    /// @notice Subtract `elastic` and `base` to `total`.
    function sub(
        Rebase memory total,
        uint256 elastic,
        uint256 base
    ) internal pure returns (Rebase memory) {
        total.elastic -= uint128(elastic);
        total.base -= uint128(base);
        return total;
    }

    /// @notice Add `elastic` to `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function addElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic += uint128(elastic);
    }

    /// @notice Subtract `elastic` from `total` and update storage.
    /// @return newElastic Returns updated `elastic`.
    function subElastic(Rebase storage total, uint256 elastic) internal returns (uint256 newElastic) {
        newElastic = total.elastic -= uint128(elastic);
    }
}


// File contracts/samples/lending/IOracle.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IOracle {
    /// @notice Get the latest exchange rate.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function get(bytes calldata data) external returns (bool success, uint256 rate);

    /// @notice Check the last exchange rate without any state changes.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return success if no valid (recent) rate is available, return false else true.
    /// @return rate The rate of the requested asset / pair / pool.
    function peek(bytes calldata data) external view returns (bool success, uint256 rate);

    /// @notice Check the current spot exchange rate without any state changes. For oracles like TWAP this will be different from peek().
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return rate The rate of the requested asset / pair / pool.
    function peekSpot(bytes calldata data) external view returns (uint256 rate);

    /// @notice Returns a human readable (short) name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable symbol name about this oracle.
    function symbol(bytes calldata data) external view returns (string memory);

    /// @notice Returns a human readable name about this oracle.
    /// @param data Usually abi encoded, implementation specific data that contains information and arguments to & about the oracle.
    /// For example:
    /// (string memory collateralSymbol, string memory assetSymbol, uint256 division) = abi.decode(data, (string, string, uint256));
    /// @return (string) A human readable name about this oracle.
    function name(bytes calldata data) external view returns (string memory);
}


// File contracts/samples/lending/Lending.sol

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;








// Isolated Lending

// Quick port, most certainly broken... very broken

// Copyright (c) 2021, 2022 BoringCrypto - All rights reserved
// Twitter: @Boring_Crypto

// Special thanks to:
// @0xKeno - for all his invaluable contributions

// solhint-disable avoid-low-level-calls
// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

struct Market {
    uint32 collateral;
    uint32 asset;
    IOracle oracle;
    bytes oracleData;
    // Collateral
    uint256 totalCollateralShare; // Total collateral supplied is yieldBox shares
    mapping(address => uint256) userCollateralShare; // Amount of collateral per user in yieldBox shares
    // Assets
    uint256 totalAssetShares;
    // totalAssetFractions and userAssetFraction are stored as the ERC1155 totalSupply and balanceOf in yieldBox

    // Borrow
    // elastic = Total token amount to be repayed by borrowers
    // base = Total parts of the debt held by borrowers
    Rebase totalBorrow;
    // User balances
    mapping(address => uint256) userBorrowPart;
    /// @notice Exchange and interest rate tracking.
    /// This is 'cached' here because calls to Oracles can be very expensive.
    uint256 exchangeRate;
    uint64 interestPerSecond;
    uint64 lastAccrued;
    uint32 assetId;
}

/// @title LendingPair
contract LendingPair is IMasterContract {
    using RebaseLibrary for Rebase;
    using BoringERC20 for IERC20;
    using BoringMath for uint256;

    event LogExchangeRate(uint256 rate);
    event LogAccrue(uint256 accruedAmount, uint64 rate, uint256 utilization);
    event LogAddCollateral(address indexed from, address indexed to, uint256 share);
    event LogAddAsset(address indexed from, address indexed to, uint256 share, uint256 fraction);
    event LogRemoveCollateral(address indexed from, address indexed to, uint256 share);
    event LogRemoveAsset(address indexed from, address indexed to, uint256 share, uint256 fraction);
    event LogBorrow(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogRepay(address indexed from, address indexed to, uint256 amount, uint256 part);
    event LogLiquidate(uint256 indexed marketId, address indexed user, uint256 borrowPart, address to, ISwapper swapper);

    // Immutables (for MasterContract and all clones)
    YieldBox public immutable yieldBox;
    LendingPair public immutable masterContract;

    mapping(uint256 => Market) public markets;
    uint256[] public marketList;

    // Settings for the Medium Risk LendingPair
    uint256 private constant COLLATERIZATION_RATE = 75000; // 75%
    uint256 private constant COLLATERIZATION_RATE_PRECISION = 1e5; // Must be less than EXCHANGE_RATE_PRECISION (due to optimization in math)
    uint256 private constant MINIMUM_TARGET_UTILIZATION = 7e17; // 70%
    uint256 private constant MAXIMUM_TARGET_UTILIZATION = 8e17; // 80%
    uint256 private constant UTILIZATION_PRECISION = 1e18;
    uint256 private constant FULL_UTILIZATION = 1e18;
    uint256 private constant FULL_UTILIZATION_MINUS_MAX = FULL_UTILIZATION - MAXIMUM_TARGET_UTILIZATION;
    uint256 private constant FACTOR_PRECISION = 1e18;

    uint64 private constant STARTING_INTEREST_PER_SECOND = 317097920; // approx 1% APR
    uint64 private constant MINIMUM_INTEREST_PER_SECOND = 79274480; // approx 0.25% APR
    uint64 private constant MAXIMUM_INTEREST_PER_SECOND = 317097920000; // approx 1000% APR
    uint256 private constant INTEREST_ELASTICITY = 28800e36; // Half or double in 28800 seconds (8 hours) if linear

    uint256 private constant EXCHANGE_RATE_PRECISION = 1e18;

    uint256 private constant LIQUIDATION_MULTIPLIER = 112000; // add 12%
    uint256 private constant LIQUIDATION_MULTIPLIER_PRECISION = 1e5;

    /// @notice The constructor is only used for the initial master contract. Subsequent clones are initialised via `init`.
    constructor(YieldBox yieldBox_) {
        yieldBox = yieldBox_;
        masterContract = this;
    }

    /// @notice No clones are used
    function init(bytes calldata) public payable override {
        revert("No clones");
    }

    function createMarket(
        uint32 collateral_,
        uint32 asset_,
        IOracle oracle_,
        bytes calldata oracleData_
    ) public {
        uint32 marketId = yieldBox.createToken(
            string(abi.encodePacked(yieldBox.name(collateral_), "/", yieldBox.name(asset_), "-", oracle_.name(oracleData_))),
            string(abi.encodePacked(yieldBox.symbol(collateral_), "/", yieldBox.symbol(asset_), "-", oracle_.symbol(oracleData_))),
            18,
            ""
        );

        Market storage market = markets[marketId];
        (market.collateral, market.asset, market.oracle, market.oracleData) = (collateral_, asset_, oracle_, oracleData_);
        market.interestPerSecond = STARTING_INTEREST_PER_SECOND; // 1% APR, with 1e18 being 100%
        market.assetId = marketId;

        marketList.push(marketId);
    }

    /// @notice Accrues the interest on the borrowed tokens.
    function accrue(uint256 marketId) public {
        Market storage market = markets[marketId];

        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - market.lastAccrued;
        if (elapsedTime == 0) {
            return;
        }
        market.lastAccrued = block.timestamp.to64();

        if (market.totalBorrow.base == 0) {
            // If there are no borrows, reset the interest rate
            if (market.interestPerSecond != STARTING_INTEREST_PER_SECOND) {
                market.interestPerSecond = STARTING_INTEREST_PER_SECOND;
                emit LogAccrue(0, STARTING_INTEREST_PER_SECOND, 0);
            }
            return;
        }

        uint256 extraAmount = 0;

        // Accrue interest
        extraAmount = (market.totalBorrow.elastic * market.interestPerSecond * elapsedTime) / 1e18;
        market.totalBorrow.elastic += extraAmount.to128();
        uint256 fullAssetAmount = yieldBox.toAmount(market.asset, yieldBox.totalSupply(marketId), false) + market.totalBorrow.elastic;

        // Update interest rate
        uint256 utilization = (market.totalBorrow.elastic * UTILIZATION_PRECISION) / fullAssetAmount;
        if (utilization < MINIMUM_TARGET_UTILIZATION) {
            uint256 underFactor = ((MINIMUM_TARGET_UTILIZATION - utilization) * FACTOR_PRECISION) / MINIMUM_TARGET_UTILIZATION;
            uint256 scale = INTEREST_ELASTICITY + (underFactor * underFactor * elapsedTime);
            market.interestPerSecond = ((market.interestPerSecond * INTEREST_ELASTICITY) / scale).to64();

            if (market.interestPerSecond < MINIMUM_INTEREST_PER_SECOND) {
                market.interestPerSecond = MINIMUM_INTEREST_PER_SECOND; // 0.25% APR minimum
            }
        } else if (utilization > MAXIMUM_TARGET_UTILIZATION) {
            uint256 overFactor = ((utilization - MAXIMUM_TARGET_UTILIZATION) * FACTOR_PRECISION) / FULL_UTILIZATION_MINUS_MAX;
            uint256 scale = INTEREST_ELASTICITY + (overFactor * overFactor * elapsedTime);
            uint256 newInterestPerSecond = (market.interestPerSecond * scale) / INTEREST_ELASTICITY;
            if (newInterestPerSecond > MAXIMUM_INTEREST_PER_SECOND) {
                newInterestPerSecond = MAXIMUM_INTEREST_PER_SECOND; // 1000% APR maximum
            }
            market.interestPerSecond = newInterestPerSecond.to64();
        }

        emit LogAccrue(extraAmount, market.interestPerSecond, utilization);
    }

    /// @notice Concrete implementation of `isSolvent`. Includes a third parameter to allow caching `exchangeRate`.
    /// @param _exchangeRate The exchange rate. Used to cache the `exchangeRate` between calls.
    function _isSolvent(
        uint256 marketId,
        address user,
        uint256 _exchangeRate
    ) internal view returns (bool) {
        Market storage market = markets[marketId];

        // accrue must have already been called!
        uint256 borrowPart = market.userBorrowPart[user];
        if (borrowPart == 0) return true;
        uint256 collateralShare = market.userCollateralShare[user];
        if (collateralShare == 0) return false;

        return
            yieldBox.toAmount(
                market.collateral,
                ((collateralShare * EXCHANGE_RATE_PRECISION) / COLLATERIZATION_RATE_PRECISION) * COLLATERIZATION_RATE,
                false
            ) >=
            // Moved exchangeRate here instead of dividing the other side to preserve more precision
            (borrowPart * market.totalBorrow.elastic * _exchangeRate) / market.totalBorrow.base;
    }

    modifier solvent(uint256 marketId) {
        _;
        // TODO
    }

    /// @notice Gets the exchange rate. I.e how much collateral to buy 1e18 asset.
    /// This function is supposed to be invoked if needed because Oracle queries can be expensive.
    /// @return updated True if `exchangeRate` was updated.
    /// @return rate The new exchange rate.
    function updateExchangeRate(uint256 marketId) public returns (bool updated, uint256 rate) {
        Market storage market = markets[marketId];

        (updated, rate) = market.oracle.get(market.oracleData);

        if (updated) {
            market.exchangeRate = rate;
            emit LogExchangeRate(rate);
        } else {
            // Return the old rate if fetching wasn't successful
            rate = market.exchangeRate;
        }
    }

    /// @notice Adds `collateral` from msg.sender to the account `to`.
    /// @param marketId The id of the market.
    /// @param to The receiver of the tokens.
    /// @param share The amount of shares to add for `to`.
    function addCollateral(
        uint256 marketId,
        address to,
        uint256 share
    ) public {
        Market storage market = markets[marketId];

        market.userCollateralShare[to] += share;
        market.totalCollateralShare += share;
        yieldBox.transfer(msg.sender, address(this), market.collateral, share);
        emit LogAddCollateral(msg.sender, to, share);
    }

    /// @dev Concrete implementation of `removeCollateral`.
    function _removeCollateral(
        uint256 marketId,
        address to,
        uint256 share
    ) internal {
        Market storage market = markets[marketId];

        market.userCollateralShare[msg.sender] -= share;
        market.totalCollateralShare -= share;
        yieldBox.transfer(address(this), to, market.collateral, share);
        emit LogRemoveCollateral(msg.sender, to, share);
    }

    /// @notice Removes `share` amount of collateral and transfers it to `to`.
    /// @param to The receiver of the shares.
    /// @param share Amount of shares to remove.
    function removeCollateral(
        uint256 marketId,
        address to,
        uint256 share
    ) public solvent(marketId) {
        // accrue must be called because we check solvency
        accrue(marketId);
        _removeCollateral(marketId, to, share);
    }

    /// @dev Concrete implementation of `addAsset`.
    function _addAsset(
        uint256 marketId,
        address to,
        uint256 share
    ) internal returns (uint256 fraction) {
        Market storage market = markets[marketId];

        uint256 allShare = yieldBox.totalSupply(marketId) + yieldBox.toShare(market.asset, market.totalBorrow.elastic, true);
        fraction = allShare == 0 ? share : (share * yieldBox.totalSupply(marketId)) / allShare;
        if (yieldBox.totalSupply(marketId) + fraction < 1000) {
            return 0;
        }
        yieldBox.mint(marketId, to, share);
        yieldBox.transfer(msg.sender, to, marketId, share);
        emit LogAddAsset(msg.sender, to, share, fraction);
    }

    /// @notice Adds assets to the lending pair.
    /// @param to The address of the user to receive the assets.
    /// @param share The amount of shares to add.
    /// @return fraction Total fractions added.
    function addAsset(
        uint256 marketId,
        address to,
        uint256 share
    ) public returns (uint256 fraction) {
        accrue(marketId);
        fraction = _addAsset(marketId, to, share);
    }

    /// @dev Concrete implementation of `removeAsset`.
    function _removeAsset(
        uint256 marketId,
        address to,
        uint256 fraction
    ) internal returns (uint256 share) {
        Market storage market = markets[marketId];

        uint256 allShare = yieldBox.totalSupply(marketId) + yieldBox.toShare(market.asset, market.totalBorrow.elastic, true);
        share = (fraction * allShare) / yieldBox.totalSupply(marketId);
        yieldBox.burn(marketId, msg.sender, fraction);
        require(yieldBox.totalSupply(marketId) >= 1000, "Kashi: below minimum");
        emit LogRemoveAsset(msg.sender, to, share, fraction);
        yieldBox.transfer(address(this), to, marketId, share);
    }

    /// @notice Removes an asset from msg.sender and transfers it to `to`.
    /// @param to The user that receives the removed assets.
    /// @param fraction The amount/fraction of assets held to remove.
    /// @return share The amount of shares transferred to `to`.
    function removeAsset(
        uint256 marketId,
        address to,
        uint256 fraction
    ) public returns (uint256 share) {
        accrue(marketId);
        share = _removeAsset(marketId, to, fraction);
    }

    /// @dev Concrete implementation of `borrow`.
    function _borrow(
        uint256 marketId,
        address to,
        uint256 amount
    ) internal returns (uint256 part, uint256 share) {
        Market storage market = markets[marketId];

        (market.totalBorrow, part) = market.totalBorrow.add(amount, true);
        market.userBorrowPart[msg.sender] += part;
        emit LogBorrow(msg.sender, to, amount, part);

        share = yieldBox.toShare(market.asset, amount, false);
        require(yieldBox.totalSupply(marketId) >= 1000, "Kashi: below minimum");
        market.totalAssetShares -= share;
        yieldBox.transfer(address(this), to, market.asset, share);
    }

    /// @notice Sender borrows `amount` and transfers it to `to`.
    /// @return part Total part of the debt held by borrowers.
    /// @return share Total amount in shares borrowed.
    function borrow(
        uint256 marketId,
        address to,
        uint256 amount
    ) public solvent(marketId) returns (uint256 part, uint256 share) {
        updateExchangeRate(marketId);
        accrue(marketId);
        (part, share) = _borrow(marketId, to, amount);
    }

    /// @dev Concrete implementation of `repay`.
    function _repay(
        uint256 marketId,
        address to,
        uint256 part
    ) internal returns (uint256 amount) {
        Market storage market = markets[marketId];

        (market.totalBorrow, amount) = market.totalBorrow.sub(part, true);
        market.userBorrowPart[to] -= part;

        uint256 share = yieldBox.toShare(market.asset, amount, true);
        yieldBox.transfer(msg.sender, address(this), market.asset, share);
        market.totalAssetShares += share;
        emit LogRepay(msg.sender, to, amount, part);
    }

    /// @notice Repays a loan.
    /// @param to Address of the user this payment should go.
    /// @param part The amount to repay. See `userBorrowPart`.
    /// @return amount The total amount repayed.
    function repay(
        uint256 marketId,
        address to,
        uint256 part
    ) public returns (uint256 amount) {
        accrue(marketId);
        amount = _repay(marketId, to, part);
    }

    /// @notice Handles the liquidation of users' balances, once the users' amount of collateral is too low.
    /// @param user The user to liquidate.
    /// @param maxBorrowPart Maximum (partial) borrow amounts to liquidate.
    /// @param to Address of the receiver if `swapper` is zero.
    /// @param swapper Contract address of the `ISwapper` implementation.
    function liquidate(
        uint256 marketId,
        address user,
        uint256 maxBorrowPart,
        address to,
        ISwapper swapper
    ) public {
        Market storage market = markets[marketId];

        // Oracle can fail but we still need to allow liquidations
        (, uint256 _exchangeRate) = updateExchangeRate(marketId);
        accrue(marketId);
        require(!_isSolvent(marketId, user, _exchangeRate), "Lending: user solvent");

        uint256 availableBorrowPart = market.userBorrowPart[user];
        uint256 borrowPart = maxBorrowPart > availableBorrowPart ? availableBorrowPart : maxBorrowPart;
        market.userBorrowPart[user] = availableBorrowPart - borrowPart;
        uint256 borrowAmount = market.totalBorrow.toElastic(borrowPart, false);
        uint256 collateralShare = yieldBox.toShare(
            market.collateral,
            ((borrowAmount * LIQUIDATION_MULTIPLIER * _exchangeRate) / LIQUIDATION_MULTIPLIER_PRECISION) * EXCHANGE_RATE_PRECISION,
            false
        );

        market.userCollateralShare[user] -= collateralShare;
        emit LogRemoveCollateral(user, swapper == ISwapper(address(0)) ? to : address(swapper), collateralShare);
        emit LogRepay(swapper == ISwapper(address(0)) ? msg.sender : address(swapper), user, borrowAmount, borrowPart);

        market.totalBorrow.elastic -= borrowAmount.to128();
        market.totalBorrow.base -= borrowPart.to128();
        market.totalCollateralShare -= collateralShare;

        uint256 borrowShare = yieldBox.toShare(market.asset, borrowAmount, true);

        // Flash liquidation: get proceeds first and provide the borrow after
        yieldBox.transfer(address(this), swapper == ISwapper(address(0)) ? to : address(swapper), market.collateral, collateralShare);
        if (swapper != ISwapper(address(0))) {
            swapper.swap(market.collateral, market.asset, msg.sender, borrowShare, collateralShare);
        }

        yieldBox.transfer(msg.sender, address(this), market.asset, borrowShare);
        market.totalAssetShares += borrowShare;

        emit LogLiquidate(marketId, user, borrowPart, to, swapper);
    }
}


// File contracts/samples/Options.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

// Thanks to
// - BookyPooBah - numToBytes

// TODO:
// Gas: Reduce where safe
// Docs: Document every line in the contract
// Check: Get extreme decimal examples, does exercise work ok?

// price: this is the price of 10^18 base units of asset (ignoring decimals) as expressed in base units of currency (also ignoring decimals)

// The frontend is responsible for making the simple calculation so the code can stay decimal agnostic and simple
// For example, the price of 1 CVC (has 8 decimals) in the currency DAI (18 decimals):
// 1 CVC = 0.0365 DAI
// 1 * 8^10 base units of CVC = 0.0365 DAI (CVC has 8 decimals)
// 1 * 8^10 base units of CVC = 0.0365 * 10^18 base units of DAI (DAI has 18 decimals)
// 1 * 18^10 base units of CVC = 0.0365 * 10^28 base units of DAI (Multiply by 10^10 in this case to get to 10^18 base units)
// Price = 0.0365 * 10^28 = 365000000000000000000000000

// Design decisions and rationale

// Use of block.timestamp
// While blocknumber is more 'exact', block.timestamp is easier to understand for users and more predictable
// So while it can be slightly manipulated by miners, this is not an issue on the timescales options operate at

// solhint-disable not-rely-on-time

library String {
    bytes1 private constant DOT = bytes1(uint8(46));
    bytes1 private constant ZERO = bytes1(uint8(48));

    function numToString(uint256 number, uint8 decimals) internal pure returns (string memory) {
        uint256 i;
        uint256 j;
        uint256 result;
        bytes memory b = new bytes(40);
        if (number == 0) {
            b[j++] = ZERO;
        } else {
            i = decimals + 18;
            do {
                uint256 num = number / 10**i;
                result = result * 10 + (num % 10);
                if (result > 0) {
                    b[j++] = bytes1(uint8((num % 10) + uint8(ZERO)));
                    if ((j > 1) && (number == num * 10**i) && (i <= decimals)) {
                        break;
                    }
                } else {
                    if (i == decimals) {
                        b[j++] = ZERO;
                        b[j++] = DOT;
                    }
                    if (i < decimals) {
                        b[j++] = ZERO;
                    }
                }
                if (decimals != 0 && decimals == i && result > 0 && i > 0) {
                    b[j++] = DOT;
                }
                i--;
            } while (i >= 0);
        }

        bytes memory out = new bytes(j);
        for (uint256 x = 0; x < j; x++) {
            out[x] = b[x];
        }
        return string(out);
    }
}

struct Option {
    uint32 asset; // Allows for up to 4B assets
    uint32 currency;
    uint32 expiry;
    uint32 optionAssetId;
    uint32 minterAssetId;
    uint256 price;
}

contract YieldOptions {
    YieldBox public yieldBox;

    constructor(YieldBox _yieldBox) {
        yieldBox = _yieldBox;
    }

    Option[] public options;

    function create(
        uint32 asset,
        uint32 currency,
        uint128 price,
        uint32 expiry
    ) public returns (uint256 optionId) {
        Option memory option;
        option.asset = asset;
        option.currency = currency;
        option.price = price;
        option.expiry = expiry;
        option.optionAssetId = yieldBox.createToken(
            "YieldOption",
            string(
                abi.encodePacked(
                    "yo",
                    yieldBox.symbol(option.asset),
                    ":",
                    yieldBox.symbol(option.currency),
                    " ",
                    String.numToString(option.price, yieldBox.decimals(option.currency))
                )
            ),
            18,
            ""
        );
        option.minterAssetId = yieldBox.createToken(
            "YieldOptionMinter",
            string(
                abi.encodePacked(
                    "ym",
                    yieldBox.symbol(option.asset),
                    ":",
                    yieldBox.symbol(option.currency),
                    " ",
                    String.numToString(option.price, yieldBox.decimals(option.currency))
                )
            ),
            18,
            ""
        );

        optionId = options.length;
        options.push(option);
    }

    event Mint(uint256 optionId, address indexed by, uint256 amount);
    event Withdraw(uint256 optionId, address indexed by, uint256 amount);
    event Exercise(uint256 optionId, address indexed by, uint256 amount);
    event Swap(uint256 optionId, address indexed by, uint256 assetAmount);

    /**
     * @dev Mint options.
     * @param amount The amount to mint expressed in units of currency.
     */
    function mint(
        uint256 optionId,
        uint256 amount,
        address optionTo,
        address minterTo
    ) public {
        Option storage option = options[optionId];

        require(block.timestamp < option.expiry, "Option expired");
        require(yieldBox.totalSupply(option.asset) == 0, "Options exercised, no minting");

        // Step 1. Receive amount base units of currency. This is held in the contract to be paid when the option is exercised.
        yieldBox.transfer(msg.sender, address(this), option.asset, amount);

        // Step 2. Mint option tokens
        yieldBox.mint(option.optionAssetId, optionTo, amount);

        // Step 3. Mint issue tokens
        yieldBox.mint(option.minterAssetId, minterTo, amount);

        // EVENTS
        emit Mint(optionId, msg.sender, amount);
    }

    /**
     * @dev Withdraw from the pool. Asset and currency are withdrawn to the proportion in which they are exercised.
     * @param amount The amount to withdraw expressed in units of the option.
     */
    function withdraw(
        uint256 optionId,
        uint256 amount,
        address to
    ) public {
        Option storage option = options[optionId];

        // CHECKS
        require(block.timestamp >= option.expiry, "Option not yet expired");

        // EFFECTS
        yieldBox.transfer(
            address(this),
            to,
            option.asset,
            (yieldBox.totalSupply(option.currency) * amount) / yieldBox.totalSupply(option.minterAssetId)
        );
        yieldBox.transfer(
            address(this),
            to,
            option.asset,
            (yieldBox.totalSupply(option.currency) * amount) / yieldBox.totalSupply(option.minterAssetId)
        );
        yieldBox.burn(option.minterAssetId, msg.sender, amount);

        // EVENTS
        emit Withdraw(optionId, msg.sender, amount);
    }

    /**
     * @dev Withdraw from the pool before expiry by returning the options.
     * In this case Assets are withdrawn first if available. Only currency is returned if assets run to 0.
     * @param amount The amount to withdraw expressed in units of the option.
     */
    function withdrawEarly(
        uint256 optionId,
        uint256 amount,
        address to
    ) public {
        Option storage option = options[optionId];

        // CHECKS
        require(block.timestamp < option.expiry, "Option not yet expired");

        // EFFECTS
        yieldBox.burn(option.optionAssetId, msg.sender, amount);
        yieldBox.burn(option.minterAssetId, msg.sender, amount);

        // Step 3. Receive from the asset pool
        uint256 assetAmount;
        uint256 currencyAmount;
        uint256 totalAsset = yieldBox.totalSupply(option.asset);

        if (totalAsset > 0) {
            // The amount fully in Assets
            assetAmount = (amount * 1e18) / option.price;

            // If there aren't enough Assets in the contract, use as much as possible and get the rest from currency
            if (assetAmount > totalAsset) {
                currencyAmount = ((assetAmount - totalAsset) * option.price) / 1e18;
                assetAmount = totalAsset;
            }
        } else {
            currencyAmount = amount;
        }

        yieldBox.transfer(address(this), to, option.currency, currencyAmount);
        yieldBox.transfer(address(this), to, option.asset, assetAmount);

        // EVENTS
        emit Withdraw(optionId, msg.sender, amount);
    }

    /**
     * @dev Exercise options.
     * @param amount The amount to exercise expressed in units of currency.
     */
    function exercise(uint256 optionId, uint256 amount) public {
        Option storage option = options[optionId];

        require(block.timestamp < option.expiry, "Option has expired");

        yieldBox.burn(option.optionAssetId, msg.sender, amount);
        yieldBox.transfer(msg.sender, address(this), option.asset, (amount * 1e18) / option.price);
        yieldBox.transfer(address(this), msg.sender, option.currency, amount);

        emit Exercise(optionId, msg.sender, amount);
    }

    /**
     * @dev If some of the options are exercised, but the price of the asset goes back up, anyone can
     * swap the assets for the original currency. The main reason for this is that minted gets locked
     * once any option is exercised. When all assets are swapped back for currency, further minting
     * can happen again.
     * @param assetAmount The amount to swap. This is denominated in asset (NOT currency!) so it's always possible to swap ALL
     * assets, and rounding won't leave dust behind.
     */
    function swap(
        uint256 optionId,
        uint256 assetAmount,
        address to
    ) public {
        Option storage option = options[optionId];

        uint256 currencyAmount = (assetAmount * option.price) / 1e18;
        yieldBox.transfer(msg.sender, address(this), option.currency, currencyAmount); // TODO: Round up
        yieldBox.transfer(address(this), msg.sender, option.asset, assetAmount);
        yieldBox.mint(option.optionAssetId, to, currencyAmount);

        // EVENTS
        emit Swap(optionId, msg.sender, currencyAmount);
    }
}


// File contracts/samples/salary.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

// solhint-disable not-rely-on-time

// IDEA: Make changes to salaries, funder or recipient
// IDEA: Enable partial withdrawals

contract Salary is BoringBatchable {
    YieldBox public yieldBox;

    event LogCreate(
        address indexed funder,
        address indexed recipient,
        uint256 indexed assetId,
        uint32 cliffTimestamp,
        uint32 endTimestamp,
        uint32 cliffPercent,
        uint256 totalShare,
        uint256 salaryId
    );
    event LogWithdraw(uint256 indexed salaryId, address indexed to, uint256 share);
    event LogCancel(uint256 indexed salaryId, address indexed to, uint256 share);

    constructor(YieldBox _yieldBox) {
        yieldBox = _yieldBox;
    }

    ///     now                      cliffTimestamp
    ///      |                             |     endTimestamp
    ///      V                             V          |
    ///      -------------------------------          |
    ///      |        ^             ^      |          V
    ///      |        |       cliffPercent |
    ///      |        |             V      |
    ///      |        |             -----> |
    ///      |        |                      \
    ///      |   totalShare                   \
    ///      |        |                          \
    ///      |        |                            \
    ///      |        V                              \
    ///      -----------------------------------------
    struct UserSalary {
        // The funder of the salary, the one who can cancel it
        address funder;
        // The recipient of the salary
        address recipient;
        // The ERC20 token
        uint256 assetId;
        // The amount of share that the recipient has already withdrawn
        uint256 withdrawnShare;
        // The timestamp of the cliff (also the start of the slope)
        uint32 cliffTimestamp;
        // The timestamp of the end of vesting (the end of the slope)
        uint32 endTimestamp;
        // The cliff payout in percent of the share
        uint64 cliffPercent;
        // The total payout in share
        uint256 share;
    }

    /// Array of all salaries managed by the contract
    UserSalary[] public salaries;

    function salaryCount() public view returns (uint256) {
        return salaries.length;
    }

    /// Create a salary
    function create(
        address recipient,
        uint256 assetId,
        uint32 cliffTimestamp,
        uint32 endTimestamp,
        uint32 cliffPercent,
        uint128 amount
    ) public returns (uint256 salaryId, uint256 share) {
        // Check that the end if after or equal to the cliff
        // If they are equal, all share become payable at once, use this for a fixed term lockup
        require(cliffTimestamp <= endTimestamp, "Salary: cliff > end");
        // You cannot have a cliff greater than 100%, important check, without the contract will lose funds
        require(cliffPercent <= 1e18, "Salary: cliff too large");

        // Fund this salary using the funder's YieldBox balance. Convert the amount to share, then transfer the share
        share = yieldBox.toShare(assetId, amount, false);
        yieldBox.transfer(msg.sender, address(this), assetId, share);

        salaryId = salaries.length;
        UserSalary memory salary;
        salary.funder = msg.sender;
        salary.recipient = recipient;
        salary.assetId = assetId;
        salary.cliffTimestamp = cliffTimestamp;
        salary.endTimestamp = endTimestamp;
        salary.cliffPercent = cliffPercent;
        salary.share = share;
        salaries.push(salary);

        emit LogCreate(msg.sender, recipient, assetId, cliffTimestamp, endTimestamp, cliffPercent, share, salaryId);
    }

    function _available(UserSalary memory salary) internal view returns (uint256 share) {
        if (block.timestamp < salary.cliffTimestamp) {
            // Before the cliff, none is available
            share = 0;
        } else if (block.timestamp >= salary.endTimestamp) {
            // After the end, all is available
            share = salary.share;
        } else {
            // In between, cliff is available, rest according to slope

            // Time that has passed since the cliff
            uint256 timeSinceCliff = block.timestamp - salary.cliffTimestamp;
            // Total time period of the slope
            uint256 timeSlope = salary.endTimestamp - salary.cliffTimestamp;
            uint256 payablePercent = salary.cliffPercent;
            if (timeSinceCliff > 0) {
                // The percentage paid out during the slope
                uint256 slopePercent = 100 - salary.cliffPercent;
                // The percentage payable on the slope added to the cliff percentage
                payablePercent += ((slopePercent * timeSinceCliff) / timeSlope);
            }
            // The share payable
            share = (salary.share * payablePercent) / 100;
        }

        // Remove any share already withdrawn
        share -= salary.withdrawnShare;
    }

    // Get the number of share currently available for withdrawal by salaryId
    function available(uint256 salaryId) public view returns (uint256 share) {
        share = _available(salaries[salaryId]);
    }

    function info(uint256 salaryId)
        public
        view
        returns (
            address funder,
            address recipient,
            uint256 assetId,
            uint256 withdrawnAmount,
            uint32 cliffTimestamp,
            uint32 endTimestamp,
            uint64 cliffPercent,
            uint256 amount,
            uint256 availableAmount
        )
    {
        funder = salaries[salaryId].funder;
        recipient = salaries[salaryId].recipient;
        assetId = salaries[salaryId].assetId;
        cliffTimestamp = salaries[salaryId].cliffTimestamp;
        endTimestamp = salaries[salaryId].endTimestamp;
        cliffPercent = salaries[salaryId].cliffPercent;
        amount = yieldBox.toAmount(salaries[salaryId].assetId, salaries[salaryId].share, false);
        withdrawnAmount = yieldBox.toAmount(salaries[salaryId].assetId, salaries[salaryId].withdrawnShare, false);
        availableAmount = yieldBox.toAmount(salaries[salaryId].assetId, _available(salaries[salaryId]), false);
    }

    function _withdraw(uint256 salaryId, address to) internal {
        uint256 pendingShare = _available(salaries[salaryId]);
        salaries[salaryId].withdrawnShare += pendingShare;
        yieldBox.transfer(address(this), to, salaries[salaryId].assetId, pendingShare);
        emit LogWithdraw(salaryId, to, pendingShare);
    }

    // Withdraw the maximum amount possible for a salaryId
    function withdraw(uint256 salaryId, address to) public {
        // Only pay out to the recipient
        require(salaries[salaryId].recipient == msg.sender, "Salary: not recipient");
        _withdraw(salaryId, to);
    }

    // Modifier for functions only allowed by the funder
    modifier onlyFunder(uint256 salaryId) {
        require(salaries[salaryId].funder == msg.sender, "Salary: not funder");
        _;
    }

    // Cancel a salary, can only be done by the funder
    function cancel(uint256 salaryId, address to) public onlyFunder(salaryId) {
        // Pay the recipient all accrued funds
        _withdraw(salaryId, salaries[salaryId].recipient);
        // Return the rest to the funder
        uint256 shareLeft = salaries[salaryId].share - salaries[salaryId].withdrawnShare;
        yieldBox.transfer(address(this), to, salaries[salaryId].assetId, shareLeft);
        emit LogCancel(salaryId, to, shareLeft);
    }
}


// File contracts/samples/Tokenizer.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Tokenizer {
    YieldBox public yieldBox;

    constructor(YieldBox _yieldBox) {
        yieldBox = _yieldBox;
    }

    mapping(uint256 => uint256) tokenizedAsset;

    function deposit(uint256 sourceAsset, uint256 share) public {
        uint256 assetId = tokenizedAsset[sourceAsset];
        if (assetId == 0) {
            yieldBox.createToken(
                string(string.concat("Tokenized ", bytes(yieldBox.name(sourceAsset)))),
                string(string.concat("t", bytes(yieldBox.symbol(sourceAsset)))),
                18,
                ""
            );
        }
        yieldBox.transfer(msg.sender, address(this), sourceAsset, share);
        yieldBox.mint(assetId, msg.sender, share * 1e18);
    }

    function withdraw(uint256 sourceAsset, uint256 share) public {
        uint256 assetId = tokenizedAsset[sourceAsset];
        yieldBox.burn(assetId, msg.sender, share * 1e18);
        yieldBox.transfer(address(this), msg.sender, sourceAsset, share);
    }
}


// File contracts/samples/YieldApp.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

contract YieldApp {
    using YieldBoxRebase for uint256;

    YieldBox public yieldBox;

    constructor(YieldBox _yieldBox) {
        yieldBox = _yieldBox;
    }
}


// File contracts/samples/YieldSwap.sol

// SPDX-License-Identifier: GPL-3
// Uniswap V2 for YieldBox (https://github.com/Uniswap/v2-core)
pragma solidity 0.8.9;

struct Pair {
    uint128 reserve0;
    uint128 reserve1;
    uint32 asset0;
    uint32 asset1;
    uint32 lpAssetId;
    uint256 kLast;
}

library Math {
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    // babylonian method (https://en.wikipedia.org/wiki/Methods_of_computing_square_roots#Babylonian_method)
    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

contract YieldSwap {
    using BoringMath for uint256;

    YieldBox public yieldBox;

    constructor(YieldBox _yieldBox) {
        yieldBox = _yieldBox;
    }

    uint256 public constant MINIMUM_LIQUIDITY = 10**3;

    Pair[] public pairs;
    mapping(uint256 => mapping(uint256 => uint256)) public pairLookup;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(address indexed sender, uint256 amount0In, uint256 amount1In, uint256 amount0Out, uint256 amount1Out, address indexed to);
    event Sync(uint112 reserve0, uint112 reserve1);

    function create(uint32 asset0, uint32 asset1) public returns (uint256 pairId) {
        if (asset0 > asset1) {
            (asset0, asset1) = (asset1, asset0);
        }

        uint32 lpAssetId = yieldBox.createToken("YieldBox LP Token", "YLP", 18, "");
        pairId = pairs.length;
        pairLookup[asset0][asset1] = pairId;
        pairs.push(Pair(0, 0, asset0, asset1, lpAssetId, 0));
    }

    function mint(uint256 pairId, address to) external returns (uint256 liquidity) {
        Pair storage pair = pairs[pairId];

        uint256 balance0 = yieldBox.balanceOf(address(this), pair.asset0);
        uint256 balance1 = yieldBox.balanceOf(address(this), pair.asset1);
        uint256 amount0 = balance0 - pair.reserve0;
        uint256 amount1 = balance1 - pair.reserve1;

        uint256 _totalSupply = yieldBox.totalSupply(pair.lpAssetId);
        if (_totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            yieldBox.mint(pair.lpAssetId, address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min((amount0 * _totalSupply) / pair.reserve0, (amount1 * _totalSupply) / pair.reserve1);
        }
        require(liquidity > 0, "YieldSwap: Not enough mint");
        yieldBox.mint(pair.lpAssetId, to, liquidity);

        pair.reserve0 = balance0.to128();
        pair.reserve1 = balance1.to128();
    }

    function burn(uint256 pairId, address to) external returns (uint256 share0, uint256 share1) {
        Pair storage pair = pairs[pairId];

        uint256 balance0 = yieldBox.balanceOf(address(this), pair.asset0);
        uint256 balance1 = yieldBox.balanceOf(address(this), pair.asset1);
        uint256 liquidity = yieldBox.balanceOf(address(this), pair.lpAssetId);

        uint256 _totalSupply = yieldBox.totalSupply(pair.lpAssetId);
        share0 = (liquidity * balance0) / _totalSupply; // using balances ensures pro-rata distribution
        share1 = (liquidity * balance1) / _totalSupply; // using balances ensures pro-rata distribution
        require(share0 > 0 && share1 > 0, "YieldSwap: Not enough");
        yieldBox.burn(pair.lpAssetId, address(this), liquidity);
        yieldBox.transfer(address(this), to, pair.asset0, share0);
        yieldBox.transfer(address(this), to, pair.asset1, share1);

        pair.reserve0 = yieldBox.balanceOf(address(this), pair.asset0).to128();
        pair.reserve1 = yieldBox.balanceOf(address(this), pair.asset1).to128();
    }

    function swap(
        uint256 pairId,
        uint256 share0Out,
        uint256 share1Out,
        address to
    ) external {
        Pair storage pair = pairs[pairId];

        require(share0Out > 0 || share1Out > 0, "YieldSwap: Output too low");
        require(share0Out < pair.reserve0 && share1Out < pair.reserve1, "YieldSwap: Liquidity too low");

        yieldBox.transfer(address(this), to, pair.asset0, share0Out);
        yieldBox.transfer(address(this), to, pair.asset1, share1Out);

        uint256 balance0 = yieldBox.balanceOf(address(this), pair.asset0);
        uint256 balance1 = yieldBox.balanceOf(address(this), pair.asset1);

        uint256 share0In = balance0 > pair.reserve0 - share0Out ? balance0 - (pair.reserve0 - share0Out) : 0;
        uint256 share1In = balance1 > pair.reserve1 - share1Out ? balance1 - (pair.reserve1 - share1Out) : 0;
        require(share0In > 0 || share1In > 0, "YieldSwap: No input");
        require(balance0 * balance1 >= pair.reserve0 * pair.reserve1, "YieldSwap: K");

        pair.reserve0 = balance0.to128();
        pair.reserve1 = balance1.to128();
    }

    // force balances to match reserves
    function skim(uint256 pairId, address to) external {
        Pair storage pair = pairs[pairId];

        yieldBox.transfer(address(this), to, pair.asset0, yieldBox.balanceOf(address(this), pair.asset0) - pair.reserve0);
        yieldBox.transfer(address(this), to, pair.asset1, yieldBox.balanceOf(address(this), pair.asset1) - pair.reserve1);
    }

    // force reserves to match balances
    function sync(uint256 pairId) external {
        Pair storage pair = pairs[pairId];

        pair.reserve0 = yieldBox.balanceOf(address(this), pair.asset0).to128();
        pair.reserve1 = yieldBox.balanceOf(address(this), pair.asset1).to128();
    }
}


// File contracts/strategies/BaseBufferStrategy.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;





// solhint-disable const-name-snakecase
// solhint-disable no-empty-blocks

abstract contract BaseBufferStrategy is IStrategy {
    using BoringMath for uint256;

    IYieldBox public immutable yieldBox;

    constructor(IYieldBox _yieldBox) {
        yieldBox = _yieldBox;
    }

    uint256 public constant MAX_RESERVE_PERCENT = 10e18;
    uint256 public constant TARGET_RESERVE_PERCENT = 5e18;

    // Implemented by base strategies for token type
    function _reserve() internal view virtual returns (uint256 amount);

    function _transfer(address to, uint256 amount) internal virtual;

    // Implemented by strategy
    function _balanceInvested() internal view virtual returns (uint256 amount);

    function _invest(uint256 amount) internal virtual;

    function _divestAll() internal virtual;

    function _divest(uint256 amount) internal virtual;

    function currentBalance() public view override returns (uint256 amount) {
        return _reserve() + _balanceInvested();
    }

    function withdrawable() external view override returns (uint256 amount) {
        return _reserve() + _balanceInvested();
    }

    function cheapWithdrawable() external view override returns (uint256 amount) {
        return _reserve();
    }

    /// Is called by YieldBox to signal funds have been added, the strategy may choose to act on this
    /// When a large enough deposit is made, this should trigger the strategy to invest into the actual
    /// strategy. This function should normally NOT be used to invest on each call as that would be costly
    /// for small deposits.
    /// Only accept this call from the YieldBox
    function deposited(uint256) public override {
        require(msg.sender == address(yieldBox), "Not YieldBox");

        uint256 balance = _balanceInvested();
        uint256 reserve = _reserve();

        // Get the size of the reserve in % (1e18 based)
        uint256 reservePercent = (reserve * 100e18) / (balance + reserve);

        // Check if the reserve is too large, if so invest it
        if (reservePercent > MAX_RESERVE_PERCENT) {
            _invest(balance.muldiv(reservePercent - TARGET_RESERVE_PERCENT, 100e18, false));
        }
    }

    /// Is called by the YieldBox to ask the strategy to withdraw to the user
    /// When a strategy keeps a little reserve for cheap withdrawals and the requested withdrawal goes over this amount,
    /// the strategy should divest enough from the strategy to complete the withdrawal and rebalance the reserve.
    /// Only accept this call from the YieldBox
    function withdraw(address to, uint256 amount) public override {
        require(msg.sender == address(yieldBox), "Not YieldBox");

        uint256 balance = _balanceInvested();
        uint256 reserve = _reserve();

        if (reserve < amount) {
            if (balance + reserve == amount) {
                _divestAll();
                _transfer(to, _reserve());
            } else {
                _divest(balance - (balance + reserve - amount).muldiv(TARGET_RESERVE_PERCENT, 100e18, false));
                _transfer(to, amount);
            }
        }
    }
}

abstract contract BaseERC20BufferStrategy is BaseBufferStrategy {
    using BoringERC20 for IERC20;

    TokenType public constant tokenType = TokenType.ERC20;
    uint256 public constant tokenId = 0;
    address public immutable contractAddress;

    constructor(IYieldBox _yieldBox, address _contractAddress) BaseBufferStrategy(_yieldBox) {
        contractAddress = _contractAddress;
    }

    function _reserve() internal view override returns (uint256 amount) {
        return IERC20(contractAddress).safeBalanceOf(address(this));
    }

    function _transfer(address to, uint256 amount) internal override {
        IERC20(contractAddress).safeTransfer(to, amount);
    }
}


// File contracts/strategies/BaseStrategy.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;




// solhint-disable const-name-snakecase
// solhint-disable no-empty-blocks

abstract contract BaseStrategy is IStrategy {
    IYieldBox public immutable yieldBox;

    constructor(IYieldBox _yieldBox) {
        yieldBox = _yieldBox;
    }

    function _currentBalance() internal view virtual returns (uint256 amount);

    function currentBalance() public view virtual returns (uint256 amount) {
        return _currentBalance();
    }

    function withdrawable() external view virtual returns (uint256 amount) {
        return _currentBalance();
    }

    function cheapWithdrawable() external view virtual returns (uint256 amount) {
        return _currentBalance();
    }

    function _deposited(uint256 amount) internal virtual;

    function deposited(uint256 amount) external {
        require(msg.sender == address(yieldBox), "Not YieldBox");
        _deposited(amount);
    }

    function _withdraw(address to, uint256 amount) internal virtual;

    function withdraw(address to, uint256 amount) external {
        require(msg.sender == address(yieldBox), "Not YieldBox");
        _withdraw(to, amount);
    }
}

abstract contract BaseERC20Strategy is BaseStrategy {
    TokenType public constant tokenType = TokenType.ERC20;
    uint256 public constant tokenId = 0;
    address public immutable contractAddress;

    constructor(IYieldBox _yieldBox, address _contractAddress) BaseStrategy(_yieldBox) {
        contractAddress = _contractAddress;
    }
}

abstract contract BaseERC1155Strategy is BaseStrategy {
    TokenType public constant tokenType = TokenType.ERC1155;
    uint256 public immutable tokenId;
    address public immutable contractAddress;

    constructor(
        IYieldBox _yieldBox,
        address _contractAddress,
        uint256 _tokenId
    ) BaseStrategy(_yieldBox) {
        contractAddress = _contractAddress;
        tokenId = _tokenId;
    }
}

abstract contract BaseNativeStrategy is BaseStrategy {
    TokenType public constant tokenType = TokenType.Native;
    uint256 public immutable tokenId;
    address public constant contractAddress = address(0);

    constructor(IYieldBox _yieldBox, uint256 _tokenId) BaseStrategy(_yieldBox) {
        tokenId = _tokenId;
    }
}


// File contracts/strategies/SushiStakingBufferStrategy.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;




// solhint-disable const-name-snakecase
// solhint-disable no-empty-blocks

interface ISushiBar is IERC20 {
    function enter(uint256 amount) external;

    function leave(uint256 share) external;
}

contract SushiStakingBufferStrategy is BaseERC20BufferStrategy {
    using BoringMath for uint256;
    using BoringERC20 for IERC20;
    using BoringERC20 for ISushiBar;

    constructor(IYieldBox _yieldBox) BaseERC20BufferStrategy(_yieldBox, address(sushi)) {}

    string public constant override name = "xSUSHI-Buffered";
    string public constant override description = "Stakes SUSHI into the SushiBar for xSushi with a buffer";

    IERC20 private constant sushi = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    ISushiBar private constant sushiBar = ISushiBar(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);

    uint256 private _balance;

    function _balanceInvested() internal view override returns (uint256 amount) {
        uint256 sushiInBar = sushi.safeBalanceOf(address(sushiBar));
        uint256 xSushiBalance = sushiBar.safeBalanceOf(address(this));
        return xSushiBalance.muldiv(sushiInBar, sushiBar.safeTotalSupply(), false);
    }

    function _invest(uint256 amount) internal override {
        sushiBar.enter(amount);
    }

    function _divestAll() internal override {
        sushiBar.leave(sushiBar.balanceOf(address(this)));
    }

    function _divest(uint256 amount) internal override {
        uint256 totalShares = sushiBar.totalSupply();
        uint256 totalSushi = sushi.balanceOf(address(sushiBar));

        uint256 shares = (amount * totalShares) / totalSushi;

        sushiBar.leave(shares);
    }
}


// File contracts/strategies/SushiStakingSimpleStrategy.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;





// solhint-disable const-name-snakecase
// solhint-disable no-empty-blocks

interface ISushiBar is IERC20 {
    function enter(uint256 amount) external;

    function leave(uint256 share) external;
}

contract SushiStakingStrategy is BaseERC20Strategy {
    using BoringERC20 for IERC20;
    using BoringERC20 for ISushiBar;
    using BoringMath for uint256;

    constructor(IYieldBox _yieldBox) BaseERC20Strategy(_yieldBox, address(sushi)) {}

    string public constant override name = "xSUSHI";
    string public constant override description = "Stakes SUSHI into the SushiBar for xSushi";

    IERC20 private constant sushi = IERC20(0x6B3595068778DD592e39A122f4f5a5cF09C90fE2);
    ISushiBar private constant sushiBar = ISushiBar(0x8798249c2E607446EfB7Ad49eC89dD1865Ff4272);

    function _currentBalance() internal view override returns (uint256 amount) {
        uint256 sushiBalance = sushi.safeBalanceOf(address(this));
        uint256 sushiInBar = sushi.safeBalanceOf(address(sushiBar));
        uint256 xSushiBalance = sushiBar.safeBalanceOf(address(this));
        return sushiBalance + xSushiBalance.muldiv(sushiInBar, sushiBar.safeTotalSupply(), false);
    }

    function _deposited(uint256 amount) internal override {
        sushiBar.enter(amount);
    }

    function _withdraw(address to, uint256 amount) internal override {
        uint256 totalSushi = sushi.safeBalanceOf(address(sushiBar));
        uint256 totalxSushi = sushiBar.safeTotalSupply();

        sushiBar.leave(amount.muldiv(totalxSushi, totalSushi, true));
        sushi.safeTransfer(to, amount);
    }
}


// File contracts/mocks/ExternalFunctionMock.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract ExternalFunctionMock {
    event Result(uint256 output);

    function sum(uint256 a, uint256 b) external returns (uint256 c) {
        c = a + b;
        emit Result(c);
    }
}


// File contracts/mocks/ReturnFalseERC20Mock.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// solhint-disable no-inline-assembly
// solhint-disable not-rely-on-time

// ReturnFalseERC20 does not revert on errors, it just returns false
contract ReturnFalseERC20Mock {
    string public symbol;
    string public name;
    uint8 public immutable decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => uint256) public nonces;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 supply
    ) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        totalSupply = supply;
        balanceOf[msg.sender] = supply;
    }

    function transfer(address to, uint256 amount) public returns (bool success) {
        if (balanceOf[msg.sender] >= amount && balanceOf[to] + amount >= balanceOf[to]) {
            balanceOf[msg.sender] -= amount;
            balanceOf[to] += amount;
            emit Transfer(msg.sender, to, amount);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool success) {
        if (balanceOf[from] >= amount && allowance[from][msg.sender] >= amount && balanceOf[to] + amount >= balanceOf[to]) {
            balanceOf[from] -= amount;
            allowance[from][msg.sender] -= amount;
            balanceOf[to] += amount;
            emit Transfer(from, to, amount);
            return true;
        } else {
            return false;
        }
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return keccak256(abi.encode(keccak256("EIP712Domain(uint256 chainId,address verifyingContract)"), chainId, address(this)));
    }

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        require(block.timestamp < deadline, "ReturnFalseERC20: Expired");
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9,
                        owner,
                        spender,
                        value,
                        nonces[owner]++,
                        deadline
                    )
                )
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress == owner, "ReturnFalseERC20: Invalid Sig");
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }
}


// File contracts/mocks/RevertingERC20Mock.sol

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

// RevertingERC20 reverts on errors
contract RevertingERC20Mock {
    string public symbol;
    string public name;
    uint8 public immutable decimals;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 supply
    ) {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        totalSupply = supply;
        balanceOf[msg.sender] = supply;
        emit Transfer(address(0), msg.sender, supply);
    }

    function transfer(address to, uint256 amount) public returns (bool success) {
        require(balanceOf[msg.sender] >= amount, "TokenB: balance too low");
        require(amount >= 0, "TokenB: amount should be > 0");
        require(balanceOf[to] + amount >= balanceOf[to], "TokenB: overflow detected");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool success) {
        require(balanceOf[from] >= amount, "TokenB: balance too low");
        require(allowance[from][msg.sender] >= amount, "TokenB: allowance too low");
        require(amount >= 0, "TokenB: amount should be >= 0");
        require(balanceOf[to] + amount >= balanceOf[to], "TokenB: overflow detected");
        balanceOf[from] -= amount;
        allowance[from][msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool success) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
}


// File contracts/mocks/WETH9Mock.sol

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.8.9;

contract WETH9Mock {
    string public name = "Wrapped Ether";
    string public symbol = "WETH";
    uint8 public decimals = 18;

    event Approval(address indexed src, address indexed guy, uint256 wad);
    event Transfer(address indexed src, address indexed dst, uint256 wad);
    event Deposit(address indexed dst, uint256 wad);
    event Withdrawal(address indexed src, uint256 wad);

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    /*fallback () external payable {
        deposit();
    }*/
    function deposit() public payable {
        balanceOf[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint256 wad) public {
        require(balanceOf[msg.sender] >= wad, "WETH9: Error");
        balanceOf[msg.sender] -= wad;
        bool success;
        (success, ) = msg.sender.call{ value: wad }("");
        emit Withdrawal(msg.sender, wad);
    }

    function totalSupply() public view returns (uint256) {
        return address(this).balance;
    }

    function approve(address guy, uint256 wad) public returns (bool) {
        allowance[msg.sender][guy] = wad;
        emit Approval(msg.sender, guy, wad);
        return true;
    }

    function transfer(address dst, uint256 wad) public returns (bool) {
        return transferFrom(msg.sender, dst, wad);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) public returns (bool) {
        require(balanceOf[src] >= wad, "WETH9: Error");

        if (src != msg.sender && allowance[src][msg.sender] != type(uint256).max) {
            require(allowance[src][msg.sender] >= wad, "WETH9: Error");
            allowance[src][msg.sender] -= wad;
        }

        balanceOf[src] -= wad;
        balanceOf[dst] += wad;

        emit Transfer(src, dst, wad);

        return true;
    }
}
