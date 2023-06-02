methods {
    function _.deposit()                                                       external => DISPATCHER(true);
    function _.withdraw(uint256)                                               external => DISPATCHER(true);
    function _.balanceOf(address, uint256)                                     external => DISPATCHER(true);
    function _.safeTransferFrom(address, address, uint256, uint256, bytes)     external => DISPATCHER(true);
}
