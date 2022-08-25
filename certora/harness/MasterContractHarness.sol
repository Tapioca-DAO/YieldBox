// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@boringcrypto/boring-solidity/contracts/interfaces/IMasterContract.sol";

contract MasterContractHarness is IMasterContract {
    /// @notice Init function that gets called from `BoringFactory.deploy`.
    /// Also kown as the constructor for cloned contracts.
    /// Any ETH send to `BoringFactory.deploy` ends up here.
    /// @param data Can be abi encoded arguments or anything else.
    function init(bytes calldata data) external payable { }
}
