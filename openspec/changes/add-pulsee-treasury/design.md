## Context

The repo already contains two sibling Hardhat subprojects sharing one contract lineage:

- `cheelee/` — original `Treasury` (ERC20: LEE/CHEEL/USDT + NFT cases/glasses).
- `doppy/` — ERC20-only fork of Cheelee (DOPPY/BNH/USDT, NFT removed).

`Treasury` is a `TransparentUpgradeableProxy`-backed vault that releases ERC20 tokens against an EIP-712 signature from a trusted `signer`, enforcing per-user, per-day, per-token-index (`_option`) caps.

Pulsee is a new app that needs the same vault but for a **single token (SEE)** only. Additionally, the source should not read as a trivial `s/doppy/pulsee/` copy. The owner has chosen: keep Doppy's array-based structure (so backend signing stays compatible), rename a small set of state identifiers, and collapse the managed tokens to one.

## Goals / Non-Goals

**Goals:**
- New `pulsee/` subproject mirroring `doppy/` layout and toolchain.
- `Treasury` manages exactly one token, SEE, via the existing array machinery (single element).
- Cosmetic divergence limited to four state identifiers (`assets`, `dailyCaps`, `drawnPerDay`, `CUSTODY`).
- Reuse Doppy's backend signing format unchanged (`PASS_TYPEHASH`, `NAME`, `withdraw`, `_option`).
- Same compile/deploy settings and OZ pins as Doppy.

**Non-Goals:**
- No bytecode-similarity evasion. Keeping the array structure means bytecode stays close to Doppy; the obfuscation target is "a human reading the source", not automated bytecode diffing.
- No renaming of public functions, events, `NAME`, or the typehash.
- No multi-token / NFT support, no new features beyond Doppy's ERC20 path.
- No changes to `cheelee/` or `doppy/`.

## Decisions

### D1: Keep the array structure, hold a single SEE element
`tokens[]`/`maxTokenTransferPerDay[]`/`tokensTransfersPerDay` (renamed) stay arrays/maps keyed by `_option`. `initialize` pushes exactly one SEE element; `_option` is always `0`.
- **Why:** Preserves Doppy's `withdraw` signature and `PASS_TYPEHASH` byte-for-byte, so the existing backend signer code works with only a `verifyingContract` swap. Also leaves `addToken`/`disableToken` functional if a second asset is ever needed.
- **Alternative considered:** Collapse to a scalar `IERC20 see` + scalar cap, drop `_option`. Rejected by owner — it changes the typehash/ABI and produces genuinely different bytecode, which is more than wanted here (threat model is human-readability only).

### D2: Rename only four state identifiers
`tokens→assets`, `maxTokenTransferPerDay→dailyCaps`, `tokensTransfersPerDay→drawnPerDay`, `GNOSIS→CUSTODY`. Nothing else.
- **Why:** Minimal, owner-specified. Enough that the storage section reads as its own product while keeping the public surface (functions/events/typehash) identical for signer compatibility.
- **Note:** These are `public` state vars, so their auto-generated getters change name — the only ABI delta.

### D3: `initialize(address _signer, IERC20Upgradeable _see)`
Two parameters. Body: zero-check `_see`, `__EIP712_init(NAME, EIP712_VERSION)`, `assets.push(_see)`, `dailyCaps.push(<cap>)`, set `signer`, `transferOwnership(CUSTODY)`.
- **Why:** Single token; mirrors Doppy's init shape minus BNH/USDT.

### D4: `CUSTODY = address(0)` placeholder fuse
Same safety mechanism as Doppy's `GNOSIS`: `transferOwnership(CUSTODY)` reverts while it is `address(0)`, so no accidental deploy is possible until the real Pulsee multisig is hardcoded.

### D5: Infra files copied from Doppy with env swap
`hardhat.config.js` (Solidity 0.8.17, optimizer off), `package.json` (same deps/scripts, renamed to `pulsee-treasury`), `scripts/deploy.js` (required env `SIGNER`, `SEE`), `.env.example`, `README.md`.

## Risks / Trade-offs

- **Bytecode stays similar to Doppy** → Accepted. The chosen threat model is source-level readability, not automated bytecode comparison. Documented in the README so it isn't mistaken for a stronger guarantee.
- **`_option` is dead-ish (always 0)** → Acceptable; preserves signing compatibility and future extensibility. README notes that valid `_option` for SEE is `0`.
- **Renaming public getters is a (small) ABI break vs Doppy** → Intended; Pulsee's frontend/indexer are new and will target the new getter names. `withdraw`/signature are unchanged so signer reuse holds.
- **Accidental deploy without owner** → Mitigated by `CUSTODY = address(0)` fuse + TODO comment + README warning, identical to Doppy.
- **Storage layout is Pulsee-specific** → A fresh proxy; not upgrade-compatible with Doppy/Cheelee proxies (intended). Future Pulsee upgrades must append above `__gap` only.
