// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts-upgradeable/utils/cryptography/draft-EIP712Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/cryptography/ECDSAUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

/// @title Treasury
/// @title Smart contract used to transfer tokens from inner to outter wallet
contract Treasury is
    EIP712Upgradeable,
    OwnableUpgradeable
{
    event Withdrawed(
        address indexed user,
        uint256 amount,
        uint256 indexed option
    );
    event SetSigner(address signer);
    event SetTokenLimit(uint256 index, uint256 newLimit);
    event AddToken(address addr, uint256 limit);
    event DisableToken(uint256 index);
    event WithdrawToken(address token, uint256 amount);

    string public constant NAME = "TREASURY";
    string public constant EIP712_VERSION = "1";

    bytes32 public constant PASS_TYPEHASH =
        keccak256(
            "WithdrawSignature(uint256 nonce,uint256 amount,address address_to,uint256 ttl,uint256 option)"
        );

    mapping(uint256 => bool) private usedSignature;

    //who              //when             //option   //amount
    mapping(address => mapping(uint256 => mapping(uint256 => uint256)))
        public tokensTransfersPerDay;
    uint256[] public maxTokenTransferPerDay;

    address public signer;
    // TODO(doppy): replace with the actual Doppy multisig address before deploying.
    // While GNOSIS == address(0), `transferOwnership(GNOSIS)` inside `initialize`
    // reverts with "Ownable: new owner is the zero address", so an accidental
    // mainnet/testnet deploy is impossible until the address is set.
    address public constant GNOSIS = address(0);
    IERC20Upgradeable[] public tokens;
    uint256[50] __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }
    
    function initialize(
        address _signer,
        IERC20Upgradeable _doppy,
        IERC20Upgradeable _bnh,
        IERC20Upgradeable _usdt
    ) external initializer {
        __Ownable_init();

        require(address(_doppy) != address(0), "Can't set zero address");
        require(address(_bnh) != address(0), "Can't set zero address");
        require(address(_usdt) != address(0), "Can't set zero address");

        __EIP712_init(NAME, EIP712_VERSION);

        tokens.push(_doppy);
        tokens.push(_bnh);
        tokens.push(_usdt);
        maxTokenTransferPerDay.push(10 * 10**18);
        maxTokenTransferPerDay.push(10 * 10**18);
        maxTokenTransferPerDay.push(10 * 10**18);

        signer = _signer;

        transferOwnership(GNOSIS);
    }

    /// @notice Used to verify erc20 withdrawal signature
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

    /// @notice Withdraw erc20 using signature
    function withdraw(
        uint256 _nonce,
        uint256 _amount,
        address _to,
        uint256 _ttl,
        uint256 _option,
        bytes memory _signature
    ) external virtual {
        require(address(tokens[_option]) != address(0), "Option disabled");
        uint256 currentDay = getCurrentDay();
        require(
            tokensTransfersPerDay[_to][currentDay][_option] + _amount <=
                maxTokenTransferPerDay[_option],
            "Amount greater than allowed"
        );
        tokensTransfersPerDay[_to][currentDay][_option] += _amount;

        require(_ttl >= block.timestamp, "Signature is no longer active");
        require(
            verifySignature(_nonce, _amount, _to, _ttl, _option, _signature) ==
                signer,
            "Bad Signature"
        );
        require(!usedSignature[_nonce], "Signature already used");

        usedSignature[_nonce] = true;
        SafeERC20Upgradeable.safeTransfer(tokens[_option], _to, _amount);

        emit Withdrawed(_to, _amount, _option);
    }

    /// @notice Function returns current day in format:
    /// 1 - monday
    /// 2 - tuesday
    /// etc..
    function getCurrentDay() public view returns (uint256) {
        return (block.timestamp / 86400) + 4;
    }

    /// @notice Set signer used to verify signatures
    function setSigner(address _signer) external onlyOwner {
        signer = _signer;

        emit SetSigner(_signer);
    }

    /// @notice Set limit for erc20 withdrawals(sum)
    function setTokenLimit(uint256 _index, uint256 _newLimit)
        external
        onlyOwner
    {
        maxTokenTransferPerDay[_index] = _newLimit;

        emit SetTokenLimit(_index, _newLimit);
    }

    /// @notice Add support for new erc20 token
    function addToken(IERC20Upgradeable _addr, uint256 _limit)
        external
        onlyOwner
    {
        require(address(_addr) != address(0), "Zero address not acceptable");
        tokens.push(_addr);
        maxTokenTransferPerDay.push(_limit);

        emit AddToken(address(_addr), _limit);
    }

    /// @notice Disable erc20 token by index
    function disableToken(uint256 _index) external onlyOwner {
        tokens[_index] = IERC20Upgradeable(address(0));

        emit DisableToken(_index);
    }

    /// @notice Withdraw tokens for owner
    function withdrawToken(IERC20Upgradeable _token, uint256 _amount)
        external
        virtual
        onlyOwner
    {
        SafeERC20Upgradeable.safeTransfer(_token, msg.sender, _amount);

        emit WithdrawToken(address(_token), _amount);
    }
}
