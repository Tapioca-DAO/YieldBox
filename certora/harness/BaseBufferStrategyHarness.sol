// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma experimental ABIEncoderV2;

import "../munged/strategies/BaseBufferStrategy.sol";

contract BaseBufferStrategyHarness is BaseERC20BufferStrategy {

    constructor(IYieldBox _yieldBox, address _contractAddress) BaseERC20BufferStrategy(_yieldBox, _contractAddress) { }
    
}
