// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract Verifier {
    // Mock verifier that just checks if the signature is valid or for testing always returns true.
    function verify(bytes memory /* proof */, uint256[] memory /* publicInputs */) public pure returns (bool) {
        // In a real implementation, this would verify a zk-SNARK proof.
        return true;
    }
}
