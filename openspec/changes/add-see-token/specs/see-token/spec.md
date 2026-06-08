## ADDED Requirements

### Requirement: see-token subproject scaffold
The system SHALL provide a `see-token/` Hardhat subproject containing `contracts/SEE.sol`, `contracts/SeeToken.sol`, `contracts/interfaces/ISeeToken.sol`, `contracts/interfaces/IBlockList.sol`, `scripts/deploy.js`, `hardhat.config.js`, `package.json`, `.env.example`, and `README.md`, and SHALL NOT modify the `cheelee/`, `doppy/`, or `pulsee/` subprojects.

#### Scenario: Subproject builds
- **WHEN** a developer runs `npm install` and `npx hardhat compile` inside `see-token/`
- **THEN** the contracts compile under Solidity 0.8.18 with the optimizer enabled (200 runs), producing `artifacts/contracts/SEE.sol/SEE.json`

#### Scenario: Siblings untouched
- **WHEN** the change is applied
- **THEN** no files under `cheelee/`, `doppy/`, or `pulsee/` are added, modified, or removed

### Requirement: SEE token reuses DOPPY template logic
The `SEE` token SHALL be an upgradeable ERC20 extending an abstract `SeeToken` template (the renamed `DoppyToken`) which inherits `ERC20PermitUpgradeable` and `OwnableUpgradeable`, and SHALL preserve DOPPY's method surface: `mint`, `burn`, `setBlockList`, `maxSupply`, `permit`, `nonces`, `DOMAIN_SEPARATOR`, standard ERC20 methods, and `Ownable` methods. The custom errors `MaxSupplyExceeded`, `BlockedByGlobalBlockList`, `BlockedByInternalBlockList` SHALL be retained unchanged.

#### Scenario: Method surface preserved
- **WHEN** inspecting the compiled `SEE` ABI
- **THEN** it exposes `mint(address,uint256)`, `burn(uint256)`, `setBlockList(address)`, `maxSupply()`, `blockList()`, `permit(...)`, `nonces(address)`, `DOMAIN_SEPARATOR()`, and the standard ERC20 + Ownable methods, matching DOPPY's surface

#### Scenario: Owner-gated mint with max-supply cap
- **WHEN** the owner calls `mint(_to, _amount)` such that `totalSupply() + _amount > maxSupply()`
- **THEN** the call reverts with `MaxSupplyExceeded`

#### Scenario: Mint and burn are owner-only
- **WHEN** a non-owner calls `mint` or `burn`
- **THEN** the call reverts with the `Ownable` not-owner error

#### Scenario: BlockList hooks honored when set
- **WHEN** a non-zero `blockList` is configured and a transfer or approval involves a blocked party
- **THEN** the operation reverts with `BlockedByGlobalBlockList` or `BlockedByInternalBlockList` per the BlockList result

#### Scenario: BlockList disabled by default
- **WHEN** `blockList == address(0)`
- **THEN** transfers and approvals proceed without any BlockList checks

### Requirement: SEE differs from DOPPY only in name, symbol, and owner
The concrete `SEE` contract SHALL set `symbol` to `"SEE"`, set `name` to the owner-provided display string, define `MAX_SUPPLY` equal to DOPPY's (`30 * 10 ** 9 * 10 ** 18`), and define an owner multisig constant `SEE_MULTISIG`. The `initialize()` function SHALL take no arguments, call `__SeeToken_init(<name>, "SEE")`, and `transferOwnership(SEE_MULTISIG)`.

#### Scenario: Name and symbol
- **WHEN** reading `name()` and `symbol()` after initialization
- **THEN** `symbol()` returns `"SEE"` and `name()` returns the configured SEE display name

#### Scenario: Max supply unchanged
- **WHEN** reading `maxSupply()`
- **THEN** it returns `30 * 10 ** 9 * 10 ** 18`, identical to DOPPY

#### Scenario: Initialize is arg-less
- **WHEN** inspecting the `initialize` signature
- **THEN** it accepts no parameters (name/symbol are hardcoded in the contract)

### Requirement: Identifier renaming
The `see-token` sources SHALL rename exactly these identifiers relative to the DOPPY sources and leave all logic, method names, errors, and events otherwise unchanged: `contract DOPPY` → `contract SEE`, `abstract DoppyToken` → `abstract SeeToken`, `__DoppyToken_init` → `__SeeToken_init`, `interface IDoppyToken` → `interface ISeeToken`, `GNOSIS_WALLET` → `SEE_MULTISIG`. `interfaces/IBlockList.sol` SHALL be copied unchanged.

#### Scenario: Renamed types present
- **WHEN** inspecting the source files
- **THEN** `SEE`, `SeeToken`, `ISeeToken`, `__SeeToken_init`, and `SEE_MULTISIG` are present and `DOPPY`, `DoppyToken`, `IDoppyToken`, `__DoppyToken_init`, `GNOSIS_WALLET` are absent

#### Scenario: IBlockList unchanged
- **WHEN** comparing `see-token/contracts/interfaces/IBlockList.sol` to the DOPPY source
- **THEN** the file content is identical

### Requirement: Deploy safety fuse
The `SEE` contract SHALL define `SEE_MULTISIG` as a constant initialized to `address(0)` placeholder until the real multisig is hardcoded, and `initialize()` SHALL call `transferOwnership(SEE_MULTISIG)`, so that any deploy reverts until a real owner address is set.

#### Scenario: Deploy blocked while placeholder set
- **WHEN** a deploy is attempted while `SEE_MULTISIG == address(0)`
- **THEN** `initialize()` reverts with "Ownable: new owner is the zero address"

#### Scenario: Proxy deploy via initialize
- **WHEN** `scripts/deploy.js` runs with a valid deployer and a non-zero `SEE_MULTISIG`
- **THEN** it deploys a `TransparentUpgradeableProxy` for `SEE`, calls the no-arg `initialize()`, and prints the proxy, implementation, and proxyAdmin addresses
