// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";

import "./interfaces/IBlockList.sol";
import "./interfaces/ISeeToken.sol";

/**
 * @dev Abstract contract implementing the common token logic (ported verbatim
 *      from the DOPPY token template; only identifiers are renamed).
 */
abstract contract SeeToken is
    ISeeToken,
    ContextUpgradeable,
    ERC20PermitUpgradeable,
    OwnableUpgradeable
{
    IBlockList public blockList;

    // Storage gap to allow for future upgrades without shifting storage layout of child contracts
    uint256[49] private __gap;

    function __SeeToken_init(
        string memory name,
        string memory symbol
    ) internal onlyInitializing {
        __ERC20_init(name, symbol);
        __ERC20Permit_init(name);
        __Ownable_init();
    }

    /**
     * @dev Returns the maximum supply of the token. Must be implemented by child contracts.
     */
    function maxSupply() public view virtual override returns (uint256);

    /**
     * @param _to: recipient address
     * @param _amount: amount of tokens
     */
    function mint(address _to, uint256 _amount) external override virtual onlyOwner {
        if (totalSupply() + _amount > maxSupply()) revert MaxSupplyExceeded();
        _mint(_to, _amount);
    }

    /**
     * @param _amount: amount of tokens
     */
    function burn(uint256 _amount) external override virtual onlyOwner {
        _burn(_msgSender(), _amount);
    }

    /**
     * @param _blockList: new blocklist address
     */
    function setBlockList(IBlockList _blockList) external override onlyOwner {
        blockList = _blockList;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (address(blockList) != address(0)) {
            if (blockList.userIsBlocked(_msgSender(), from, to))
                revert BlockedByGlobalBlockList();
            if (
                blockList.userIsInternalBlocked(
                    address(this),
                    _msgSender(),
                    from,
                    to
                )
            ) revert BlockedByInternalBlockList();

            blockList.limitAllows(from, to, amount);
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        if (address(blockList) != address(0)) {
            if (blockList.userIsBlocked(owner, spender, address(0)))
                revert BlockedByGlobalBlockList();
            if (
                blockList.userIsInternalBlocked(
                    address(this),
                    owner,
                    spender,
                    address(0)
                )
            ) revert BlockedByInternalBlockList();
        }

        super._approve(owner, spender, amount);
    }
}
