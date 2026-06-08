// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./SeeToken.sol";

contract SEE is SeeToken {
    // TODO(see): replace with the real SEE owner multisig before deploying.
    // While SEE_MULTISIG == address(0), `transferOwnership(SEE_MULTISIG)` inside
    // `initialize` reverts ("Ownable: new owner is the zero address"), which
    // prevents shipping an ownerless token to mainnet/testnet by mistake.
    address public constant SEE_MULTISIG = address(0);
    uint256 public constant MAX_SUPPLY = 30 * 10 ** 9 * 10 ** 18;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() external initializer {
        // SEE has no descriptive long name (unlike DOPPY's "Dreams, Optimism,
        // Playfulness & You"): both name and symbol are simply "SEE". This is
        // the final value; the EIP-712 permit domain binds to this name.
        __SeeToken_init("SEE", "SEE");
        transferOwnership(SEE_MULTISIG);
    }

    /**
     * @dev Returns the maximum supply of the token.
     */
    function maxSupply() public pure override returns (uint256) {
        return MAX_SUPPLY;
    }
}
