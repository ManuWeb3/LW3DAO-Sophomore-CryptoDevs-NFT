//SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IWhitelist { 
    function whitelistedAddresses(address) external view returns (bool);
    // see how we declared a function with the same name as a mapping to access it via this f()
}