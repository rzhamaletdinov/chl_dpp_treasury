## ADDED Requirements

### Requirement: Pulsee subproject scaffold
The system SHALL provide a `pulsee/` Hardhat subproject mirroring `doppy/`, containing `contracts/Treasury.sol`, `scripts/deploy.js`, `hardhat.config.js`, `package.json`, `.env.example`, and `README.md`, and SHALL NOT modify the `cheelee/` or `doppy/` subprojects.

#### Scenario: Subproject builds
- **WHEN** a developer runs `npm install` and `npx hardhat compile` inside `pulsee/`
- **THEN** the `Treasury` contract compiles under Solidity 0.8.17 with the optimizer disabled, producing `artifacts/contracts/Treasury.sol/Treasury.json`

#### Scenario: Siblings untouched
- **WHEN** the change is applied
- **THEN** no files under `cheelee/` or `doppy/` are added, modified, or removed

### Requirement: Single SEE token support
The Pulsee `Treasury` SHALL manage exactly one ERC20 token (SEE). The `initialize` function SHALL accept `(address _signer, IERC20Upgradeable _see)`, reject a zero `_see` address, register SEE as the single managed asset at index `0`, and set a daily cap for it.

#### Scenario: Initialize with SEE
- **WHEN** the proxy is initialized with a non-zero signer and a non-zero SEE address
- **THEN** the managed-asset list contains exactly one entry (SEE) at index `0` with a configured daily cap, and `signer` is set

#### Scenario: Reject zero token
- **WHEN** `initialize` is called with `_see == address(0)`
- **THEN** the call reverts with "Can't set zero address"

#### Scenario: No BNH/USDT parameters
- **WHEN** inspecting the `initialize` signature
- **THEN** it has no BNH or USDT parameters and no NFT parameters

### Requirement: Signature-based SEE withdrawal compatible with Doppy
The Pulsee `Treasury` SHALL release SEE to a recipient against a valid EIP-712 signature from `signer`, using the same `NAME = "TREASURY"`, `EIP712_VERSION = "1"`, and `PASS_TYPEHASH` (`WithdrawSignature(uint256 nonce,uint256 amount,address address_to,uint256 ttl,uint256 option)`) as Doppy. The public function names (`withdraw`, `verifySignature`, `setSigner`, `setTokenLimit`, `addToken`, `disableToken`, `withdrawToken`, `getCurrentDay`), events, and the `_option` parameter SHALL remain identical to Doppy.

#### Scenario: Valid withdrawal
- **WHEN** `withdraw` is called with a non-expired, unused, signer-signed payload for `_option = 0` within the daily cap
- **THEN** the contract transfers `_amount` SEE to `_to`, marks the nonce used, accumulates the per-user per-day amount, and emits `Withdrawed`

#### Scenario: Backend signer reuse
- **WHEN** a backend that signs Doppy `WithdrawSignature(...)` payloads targets the Pulsee proxy address as `verifyingContract`
- **THEN** the produced signature verifies successfully against the Pulsee `Treasury` with no change to the payload schema

#### Scenario: Daily cap enforced
- **WHEN** a withdrawal would push a recipient's same-day total for `_option = 0` above the daily cap
- **THEN** the call reverts with "Amount greater than allowed"

#### Scenario: Replay rejected
- **WHEN** `withdraw` is called twice with the same nonce
- **THEN** the second call reverts with "Signature already used"

### Requirement: State identifier renaming
The Pulsee `Treasury` SHALL rename exactly the following state identifiers relative to Doppy and SHALL leave all other identifiers (functions, events, `NAME`, typehash) unchanged: `tokens` → `assets`, `maxTokenTransferPerDay` → `dailyCaps`, `tokensTransfersPerDay` → `drawnPerDay`, `GNOSIS` → `CUSTODY`.

#### Scenario: Renamed getters present
- **WHEN** inspecting the compiled ABI
- **THEN** public getters `assets`, `dailyCaps`, and `drawnPerDay` exist and getters named `tokens`, `maxTokenTransferPerDay`, `tokensTransfersPerDay` do not

#### Scenario: Public surface preserved
- **WHEN** comparing function and event names against Doppy
- **THEN** `withdraw`, `setSigner`, `setTokenLimit`, `addToken`, `disableToken`, `withdrawToken`, `verifySignature`, `getCurrentDay` and all event names are identical

### Requirement: Deploy safety fuse
The Pulsee `Treasury` SHALL define `CUSTODY` as a constant initialized to `address(0)` placeholder and SHALL call `transferOwnership(CUSTODY)` inside `initialize`, so that any deploy reverts until a real owner address is hardcoded.

#### Scenario: Deploy blocked while placeholder set
- **WHEN** a deploy is attempted while `CUSTODY == address(0)`
- **THEN** `initialize` reverts with "Ownable: new owner is the zero address"

#### Scenario: Deploy script requires SEE env
- **WHEN** `scripts/deploy.js` runs without the `SIGNER` or `SEE` environment variables
- **THEN** it throws an error listing the missing variables and does not deploy
