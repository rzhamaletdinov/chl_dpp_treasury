// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @title Treasury
/// @notice Signature-gated vault: releases ERC20 balances to recipients that an
///         off-chain signer has approved, bounded by a per-recipient daily cap.
contract Treasury is
    EIP712Upgradeable,
    OwnableUpgradeable
{
    event WithdrawToken(address token, uint256 amount);
    event AddToken(address addr, uint256 limit);
    event DisableToken(uint256 index);
    event SetTokenLimit(uint256 index, uint256 newLimit);
    event SetSigner(address signer);
    event Withdrawed(
        address indexed user,
        uint256 amount,
        uint256 indexed option
    );

    string public constant NAME = "TREASURY";
    string public constant EIP712_VERSION = "1";

    bytes32 public constant PASS_TYPEHASH =
        keccak256(
            "WithdrawSignature(uint256 nonce,uint256 amount,address address_to,uint256 ttl,uint256 option)"
        );

    mapping(uint256 => bool) private usedSignature;

    // recipient => day bucket => asset index => amount already released that day
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        public drawnPerDay;
    uint256[] public dailyCaps;

    address public signer;
    // NOTE(pulsee): CUSTODY must point at the Pulsee multisig before any deploy.
    // With the zero placeholder, `transferOwnership(CUSTODY)` in `initialize`
    // reverts ("Ownable: new owner is the zero address"), which prevents shipping
    // an ownerless vault to mainnet/testnet by mistake.
    address public constant CUSTODY = address(0);
    IERC20Upgradeable[] public assets;
    uint256[50] __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @notice One-time proxy setup: registers SEE and hands ownership to CUSTODY.
    function initialize(
        address _signer,
        IERC20Upgradeable _see
    ) external initializer {
        __Ownable_init();

        require(address(_see) != address(0), "Can't set zero address");

        __EIP712_init(NAME, EIP712_VERSION);

        assets.push(_see);
        dailyCaps.push(10 * 10**18);

        signer = _signer;

        transferOwnership(CUSTODY);
    }

    /// @notice Rotate the trusted off-chain signer.
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;

        emit SetSigner(_signer);
    }

    /// @notice Update the daily cap of an already-registered asset.
    function setTokenLimit(uint256 _index, uint256 _newLimit)
        external
        onlyOwner
    {
        dailyCaps[_index] = _newLimit;

        emit SetTokenLimit(_index, _newLimit);
    }

    /// @notice Register an extra ERC20 asset together with its daily cap.
    function addToken(IERC20Upgradeable _addr, uint256 _limit)
        external
        onlyOwner
    {
        require(address(_addr) != address(0), "Zero address not acceptable");
        assets.push(_addr);
        dailyCaps.push(_limit);

        emit AddToken(address(_addr), _limit);
    }

    /// @notice Turn off a managed asset by its index.
    function disableToken(uint256 _index) external onlyOwner {
        assets[_index] = IERC20Upgradeable(address(0));

        emit DisableToken(_index);
    }

    /// @notice Owner escape hatch: sweep arbitrary tokens held by the contract.
    function withdrawToken(IERC20Upgradeable _token, uint256 _amount)
        external
        virtual
        onlyOwner
    {
        SafeERC20Upgradeable.safeTransfer(_token, msg.sender, _amount);

        emit WithdrawToken(address(_token), _amount);
    }

    /// @notice Day bucket derived from block time; the +4 offset aligns bucket 0
    ///         to a Monday so caps roll over at UTC midnight on week boundaries.
    function getCurrentDay() public view returns (uint256) {
        return (block.timestamp / 86400) + 4;
    }

    /// @notice Recovers the address that signed an EIP-712 withdrawal voucher.
    function verifySignature(
        uint256 _nonce,
        uint256 _amount,
        address _to,
        uint256 _ttl,
        uint256 _option,
        bytes memory _signature
    ) public view virtual returns (address) {
        bytes32 _digest = _hashTypedDataV4(
            keccak256(
                abi.encode(PASS_TYPEHASH, _nonce, _amount, _to, _ttl, _option)
            )
        );
        return ECDSAUpgradeable.recover(_digest, _signature);
    }

    /// @notice Release tokens to `_to` against a signer-approved voucher, within caps.
    function withdraw(
        uint256 _nonce,
        uint256 _amount,
        address _to,
        uint256 _ttl,
        uint256 _option,
        bytes memory _signature
    ) external virtual {
        require(address(assets[_option]) != address(0), "Option disabled");
        uint256 currentDay = getCurrentDay();
        require(
            drawnPerDay[_to][currentDay][_option] + _amount <=
                dailyCaps[_option],
            "Amount greater than allowed"
        );
        drawnPerDay[_to][currentDay][_option] += _amount;

        require(_ttl >= block.timestamp, "Signature is no longer active");
        require(
            verifySignature(_nonce, _amount, _to, _ttl, _option, _signature) ==
                signer,
            "Bad Signature"
        );
        require(!usedSignature[_nonce], "Signature already used");

        usedSignature[_nonce] = true;
        SafeERC20Upgradeable.safeTransfer(assets[_option], _to, _amount);

        emit Withdrawed(_to, _amount, _option);
    }
}
