// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// solhint-disable no-inline-assembly

import "../helpers/Receiver.sol";

library DummyBoringAddress {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendNative(address to, uint256 amount) internal {
        // solhint-disable-next-line avoid-low-level-calls
        // (bool success, ) = to.call{value: amount}("");
        (bool success) = Receiver(payable(to)).sendTo{value:amount}();
        require(success, "BoringAddress: transfer failed");
    }
}
