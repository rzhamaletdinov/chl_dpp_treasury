## Why

The live **DOPPY** token on BSC (`0x3ac8…3c6b`, an upgradeable BEP-20 behind a `TransparentUpgradeableProxy`, implementation `0x83e4…7486`) is built on a small, reusable token template (`DoppyToken`) explicitly designed to back multiple tokens ("common logic for DOPPY and BNH"). We want a new token, **SEE**, that reuses this exact logic and method surface, differing only in its name/symbol (and its own owner multisig). It lives in a new, self-contained `see-token/` subproject so it does not touch the existing Treasury subprojects.

Note: `see-token` is the **ERC20 token itself**. It is distinct from `pulsee/`, which is a Treasury *vault* that releases SEE. The two are complementary, not duplicates.

## What Changes

- Add a new `see-token/` Hardhat subproject (upgradeable ERC20, OZ upgradeable + hardhat-upgrades), self-contained like `doppy/`.
- Port the verified DOPPY token source 1:1, renaming the contract/template identifiers (but keeping all ERC20/permit/blocklist logic and method names byte-aligned):
  - `contract DOPPY` → `contract SEE`
  - `abstract DoppyToken` → `abstract SeeToken`, `__DoppyToken_init` → `__SeeToken_init`
  - `interface IDoppyToken` → `interface ISeeToken`
  - `GNOSIS_WALLET` constant → `SEE_MULTISIG`
  - `interfaces/IBlockList.sol` copied **unchanged**
- Per-token values in the concrete `SEE` contract:
  - `name` = **owner-provided display name** (TBD — analog of DOPPY's `"Dreams, Optimism, Playfulness & You"`)
  - `symbol` = `"SEE"`
  - `MAX_SUPPLY` = `30 * 10 ** 9 * 10 ** 18` (**same as DOPPY**, per "only the name differs")
  - `SEE_MULTISIG` = the SEE owner multisig (TBD address; until provided, kept as `address(0)` placeholder fuse)
- Preserve all token logic byte-for-byte vs DOPPY: `ERC20PermitUpgradeable` + `OwnableUpgradeable`, the `_beforeTokenTransfer`/`_approve` BlockList hooks, `mint(onlyOwner)` with `MAX_SUPPLY` check (`MaxSupplyExceeded`), `burn(onlyOwner)`, `setBlockList(onlyOwner)`, `__gap[49]`, Solidity `0.8.18`, optimizer enabled (200 runs), OZ `contracts-upgradeable@4.7.3` (the `draft-` permit/EIP712 import paths).
- Add infra mirroring `doppy/`: `hardhat.config.js`, `scripts/deploy.js` (deploys the proxy and calls the no-arg `initialize()`), `package.json`, `.env.example`, `README.md`.

## Capabilities

### New Capabilities
- `see-token`: An upgradeable ERC20 token (SEE) that reuses the DOPPY token template logic verbatim (permit, owner-gated mint with max-supply cap, burn, optional external BlockList), differing only in name/symbol and owner multisig.

### Modified Capabilities
<!-- None: new, independent subproject. cheelee/, doppy/, pulsee/ are untouched. -->

## Impact

- New code: `see-token/` subproject only. No changes to `cheelee/`, `doppy/`, or `pulsee/`.
- This is the live DOPPY token's logic, not the repo's Treasury vault — it is a separate contract lineage from the existing `Treasury.sol` files.
- Upgradeable: deployed behind a `TransparentUpgradeableProxy`; fresh storage layout, not upgrade-compatible with any existing proxy.
- Deploy safety: `SEE_MULTISIG = address(0)` placeholder makes `transferOwnership(SEE_MULTISIG)` in `initialize()` revert until the real SEE multisig is hardcoded.
- External dependency: the BlockList is a separate deployed contract; the token only references `IBlockList`. `blockList` defaults to `address(0)` (disabled) until `setBlockList` is called.
- Open inputs before implementation: (1) the SEE `name` string, (2) the `SEE_MULTISIG` address.
