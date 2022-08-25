methods {
    deposit()                                                       => DISPATCHER(true)
    withdraw(uint256)                                               => DISPATCHER(true)
    balanceOf(address, uint256) returns (uint256)                   => DISPATCHER(true)
    safeTransferFrom(address, address, uint256, uint256, bytes)     => DISPATCHER(true)
}
