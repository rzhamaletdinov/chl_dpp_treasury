// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "./IBlockList.sol";

interface ISeeToken {
    /// @notice Error: Max supply exceeded
    error MaxSupplyExceeded();
    /// @notice Error: User is blocked in the global blocklist
    error BlockedByGlobalBlockList();
    /// @notice Error: User is blocked in the internal blocklist
    error BlockedByInternalBlockList();

    /**
     * @notice Returns the maximum supply of the token.
     */
    function maxSupply() external view returns (uint256);

    /**
     * @param _to: recipient address
     * @param _amount: amount of tokens
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @param _amount: amount of tokens
     */
    function burn(uint256 _amount) external;

    /**
     * @param _blockList: new blocklist address
     */
    function setBlockList(IBlockList _blockList) external;

    function initialize() external;

    function SEE_MULTISIG() external view returns (address);
    function blockList() external view returns (IBlockList);
}
