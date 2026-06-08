// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface IBlockList {
    // ==================== Custom Errors ====================

    /// @notice Caller is not the blocklist admin
    error NotBlockListAdmin();

    /// @notice Zero address not allowed
    error ZeroAddressNotAllowed();

    /// @notice Sender exceeded daily outcome limit
    error DailyOutcomeLimitReached();

    /// @notice Sender exceeded monthly outcome limit
    error MonthlyOutcomeLimitReached();

    /// @notice Receiver exceeded daily income limit
    error DailyIncomeLimitReached();

    /// @notice Receiver exceeded monthly income limit
    error MonthlyIncomeLimitReached();

    // ==================== Events ====================

    event TokenLimitUpdated(
        address indexed token,
        uint256 dailyIncomeLimit,
        uint256 monthlyIncomeLimit,
        uint256 dailyOutcomeLimit,
        uint256 monthlyOutcomeLimit
    );
    event TokenLimitStatusUpdated(
        address indexed token,
        bool hasDailyIncomeLimit,
        bool hasMonthlyIncomeLimit,
        bool hasDailyOutcomeLimit,
        bool hasMonthlyOutcomeLimit
    );
    event AddToExclusionList(address indexed token);
    event RemoveFromExclusionList(address indexed token);

    // ==================== Structures ====================

    /**
     * @notice Token limit structure
     */
    struct TokenLimit {
        uint256 dailyIncome;
        uint256 monthlyIncome;
        uint256 dailyOutcome;
        uint256 monthlyOutcome;
    }

    /**
     * @notice Token transfers structure
     */
    struct TokenTransfers {
        uint256 income;
        uint256 outcome;
    }

    /**
     * @notice Token limit enabling/disabling structure
     */
    struct TokenLimitDisabling {
        bool hasDailyIncomeLimit;
        bool hasMonthlyIncomeLimit;
        bool hasDailyOutcomeLimit;
        bool hasMonthlyOutcomeLimit;
    }

    // ==================== Functions ====================

    function initialize() external;

    function BLOCKLIST_ADMIN_ROLE() external view returns (bytes32);
    function GNOSIS_WALLET() external view returns (address);
    function globalBlockList(address user) external view returns (bool);
    function internalBlockList(
        address token,
        address user
    ) external view returns (bool);
    function tokensWithLimits(
        address token
    )
        external
        view
        returns (
            bool hasDailyIncomeLimit,
            bool hasMonthlyIncomeLimit,
            bool hasDailyOutcomeLimit,
            bool hasMonthlyOutcomeLimit
        );
    function contractsExclusionList(
        address contractAddress
    ) external view returns (bool);
    function tokenLimits(
        address token
    )
        external
        view
        returns (
            uint256 dailyIncome,
            uint256 monthlyIncome,
            uint256 dailyOutcome,
            uint256 monthlyOutcome
        );
    function tokenTransfers(
        address token,
        address user,
        uint256 date
    ) external view returns (uint256 income, uint256 outcome);

    /**
     * @param _users: array of addresses to add
     */
    function addUsersToBlockList(address[] memory _users) external;

    /**
     * @param _users: array of addresses to remove
     */
    function removeUsersFromBlockList(address[] memory _users) external;

    /**
     * @param _token: token contract address
     * @param _users: array of addresses to add
     */
    function addUsersToInternalBlockList(
        address _token,
        address[] memory _users
    ) external;

    /**
     * @param _token: token contract address
     * @param _users: array of addresses to remove
     *
     */
    function removeUsersFromInternalBlockList(
        address _token,
        address[] memory _users
    ) external;

    /**
     * @param _sender: transaction sender address
     * @param _from: token sender address
     * @param _to: recipient address
     */
    function userIsBlocked(
        address _sender,
        address _from,
        address _to
    ) external view returns (bool);

    /**
     * @param _token: token contract address
     * @param _sender: transaction sender address
     * @param _from: token sender address
     * @param _to: recipient address
     */
    function userIsInternalBlocked(
        address _token,
        address _sender,
        address _from,
        address _to
    ) external view returns (bool);

    /**
     * @param _token: token contract address
     * @param _users: list of user addresses
     */
    function usersFromListIsBlocked(
        address _token,
        address[] memory _users
    ) external view returns (address[] memory);

    /**
     * @return current day
     */
    function getCurrentDay() external view returns (uint256);

    /**
     * @return current month
     */
    function getCurrentMonth() external view returns (uint256);

    /**
     * @param _token: token contract address
     * @param _dailyIncomeLimit: daily income limit
     * @param _monthlyIncomeLimit: monthly income limit
     * @param _dailyOutcomeLimit: daily outcome limit
     * @param _monthlyOutcomeLimit: monthly outcome limit
     */
    function setTokenLimits(
        address _token,
        uint256 _dailyIncomeLimit,
        uint256 _monthlyIncomeLimit,
        uint256 _dailyOutcomeLimit,
        uint256 _monthlyOutcomeLimit
    ) external;

    /**
     * @param _contract: contract address
     */
    function addContractToExclusionList(address _contract) external;

    /**
     * @param _contract: contract address
     */
    function removeContractFromExclusionList(address _contract) external;

    /**
     * @param _from: sender address
     * @param _to: recipient address
     * @param _amount: amount of transferred tokens
     */
    function limitAllows(address _from, address _to, uint256 _amount) external;

    /**
     * @param _token: token contract address
     */
    function getTokenLimits(
        address _token
    ) external view returns (TokenLimit memory);

    /**
     * @param _token: token contract address
     * @param _user: user address
     */
    function getUserTokenTransfers(
        address _token,
        address _user
    )
        external
        view
        returns (
            uint256 dailyIncomeTransfers,
            uint256 monthlyIncomeTransfers,
            uint256 dailyOutcomeTransfers,
            uint256 monthlyOutcomeTransfers
        );

    /**
     * @param _token: token contract address
     * @param _hasDailyIncomeLimit: enable daily income limit
     * @param _hasMonthlyIncomeLimit: enable monthly income limit
     * @param _hasDailyOutcomeLimit: enable daily outcome limit
     * @param _hasMonthlyOutcomeLimit: enable monthly outcome limit
     */
    function changeDisablingTokenLimits(
        address _token,
        bool _hasDailyIncomeLimit,
        bool _hasMonthlyIncomeLimit,
        bool _hasDailyOutcomeLimit,
        bool _hasMonthlyOutcomeLimit
    ) external;

    /**
     * @param _token: token contract address
     * @param _user: user address
     */
    function getUserRemainingLimit(
        address _token,
        address _user
    )
        external
        view
        returns (
            uint256 dailyIncomeRemaining,
            uint256 monthlyIncomeRemaining,
            uint256 dailyOutcomeRemaining,
            uint256 monthlyOutcomeRemaining
        );
}
