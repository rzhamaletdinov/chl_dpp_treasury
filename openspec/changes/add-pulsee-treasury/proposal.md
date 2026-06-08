## Why

We are launching a new application, **Pulsee**, which needs its own signature-based ERC20 withdrawal vault — the same pattern already used by Cheelee and Doppy. Pulsee only deals with a single token (**SEE**); it does not need the multi-token (BNH/USDT) support that Doppy carries. We also want the on-chain source to read as its own product rather than an obvious 1:1 copy of the Doppy Treasury.

## What Changes

- Add a new `pulsee/` subproject (Hardhat) mirroring `doppy/`, with its own `Treasury.sol`, `scripts/deploy.js`, `hardhat.config.js`, `package.json`, `.env.example`, and `README.md`.
- The Pulsee `Treasury` supports **only the SEE token**. BNH and USDT are removed. **BREAKING** vs Doppy: `initialize` takes `(address _signer, IERC20Upgradeable _see)` instead of four args; the managed-token array holds a single element.
- Light cosmetic obfuscation: rename **only** these state identifiers (no public function, event, `NAME`, or typehash renames):
  - `tokens[]` → `assets[]`
  - `maxTokenTransferPerDay[]` → `dailyCaps[]`
  - `tokensTransfersPerDay` → `drawnPerDay`
  - `GNOSIS` → `CUSTODY` (kept as `address(0)` placeholder safety fuse)
- Everything else stays byte-for-byte aligned with Doppy: function names (`withdraw`, `setSigner`, `setTokenLimit`, `addToken`, `disableToken`, `withdrawToken`, `verifySignature`, `getCurrentDay`), events, `NAME = "TREASURY"`, `PASS_TYPEHASH`, and the `_option` signature field (always `0` for SEE).
- Deploy/infra files copy Doppy's, replacing the `DOPPY/BNH/USDT` env trio with a single `SEE`.

## Capabilities

### New Capabilities
- `pulsee-treasury`: A single-token (SEE) upgradeable signature-based withdrawal vault for the Pulsee app, derived from the Doppy Treasury with single-token support and minimal state-identifier renaming.

### Modified Capabilities
<!-- None: this is a new, independent subproject; Doppy and Cheelee Treasuries are untouched. -->

## Impact

- New code: `pulsee/` subproject only. No changes to `cheelee/` or `doppy/`.
- ABI: getter names shift (`tokens(i)`→`assets(i)`, `maxTokenTransferPerDay(i)`→`dailyCaps(i)`, `tokensTransfersPerDay(...)`→`drawnPerDay(...)`). `withdraw` and the EIP-712 `WithdrawSignature(...)` payload are unchanged, so the backend signer logic is reusable (only `verifyingContract` differs).
- Dependencies: same OZ pins as Doppy (`@openzeppelin/contracts-upgradeable@4.7.3`, `@openzeppelin/contracts@^4.9.6`, hardhat-upgrades v3, Solidity 0.8.17, optimizer off).
- Deploy safety: `CUSTODY = address(0)` placeholder makes any deploy revert in `initialize` until the real Pulsee multisig is set (same fuse as Doppy's `GNOSIS`).
