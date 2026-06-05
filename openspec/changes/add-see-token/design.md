## Context

The on-chain DOPPY token (`0x3ac8…3c6b` proxy → `0x83e4…7486` impl, verified on Sourcify, perfect match) is composed of four project files plus OZ upgradeable libraries:

```
interfaces/IBlockList.sol     interfaces/IDoppyToken.sol
        \                            /
         \                          /
          DoppyToken.sol (abstract)        = ERC20PermitUpgradeable + OwnableUpgradeable
          + blockList hooks, mint/burn,      + ContextUpgradeable, IDoppyToken
            setBlockList, __DoppyToken_init
                    |
                    v
              DOPPY.sol (concrete)
              GNOSIS_WALLET, MAX_SUPPLY = 30 * 10**9 * 10**18,
              initialize() -> __DoppyToken_init("Dreams, Optimism, Playfulness & You", "DOPPY"),
              transferOwnership(GNOSIS_WALLET), maxSupply() override
```

Compiler `0.8.18`, optimizer enabled (200 runs). The `draft-ERC20PermitUpgradeable` / `draft-EIP712Upgradeable` import paths match OZ `contracts-upgradeable` 4.7.x (the repo already pins `4.7.3`).

The owner wants SEE to reuse this template verbatim — only name/symbol and the owner multisig differ — placed in a standalone `see-token/` Hardhat subproject (full scaffold like `doppy/`).

## Goals / Non-Goals

**Goals:**
- New `see-token/` subproject mirroring `doppy/`'s toolchain and layout.
- Port DOPPY's four token files into SEE, renaming only the contract/template identifiers; keep all ERC20/permit/blocklist logic and method names identical.
- Concrete `SEE`: `symbol = "SEE"`, owner-provided `name`, `MAX_SUPPLY` identical to DOPPY, own multisig.
- Same compiler/optimizer/OZ pins as the verified DOPPY token.

**Non-Goals:**
- No change to the token's economic or transfer logic, method names, errors, or events.
- No re-implementation of the external BlockList contract (only the `IBlockList` interface is needed).
- No changes to `cheelee/`, `doppy/`, or `pulsee/`.
- Not the Treasury vault pattern — this is the ERC20 token itself.

## Decisions

### D1: Port the 4-file DOPPY token structure, rename template identifiers only
`SEE.sol` (concrete) extends `SeeToken.sol` (abstract, ex-`DoppyToken`) which implements `ISeeToken.sol` (ex-`IDoppyToken`) and references `IBlockList.sol` (copied unchanged).
- Renames: `DOPPY`→`SEE`, `DoppyToken`→`SeeToken`, `__DoppyToken_init`→`__SeeToken_init`, `IDoppyToken`→`ISeeToken`, `GNOSIS_WALLET`→`SEE_MULTISIG`.
- **Why:** Matches the user's "rename everything" choice while keeping the public ERC20 surface (function names, errors `MaxSupplyExceeded`/`BlockedBy*`, events) byte-aligned with DOPPY.

### D2: `MAX_SUPPLY` unchanged
`MAX_SUPPLY = 30 * 10 ** 9 * 10 ** 18` (30 billion, 18 decimals), exactly as DOPPY.
- **Why:** Owner chose "only the name differs"; supply stays identical.

### D3: New owner multisig with `address(0)` fuse until provided
`SEE_MULTISIG` is a hardcoded constant set to the SEE owner multisig. Until that address is supplied, it stays `address(0)`, so `transferOwnership(SEE_MULTISIG)` in `initialize()` reverts — preventing an accidental ownerless deploy (same fuse pattern as `doppy/`/`pulsee/`).
- **Why:** Owner chose a new SEE multisig (address TBD); the fuse keeps deploy safe meanwhile.

### D4: `initialize()` takes no arguments
Like DOPPY, `name`/`symbol` are hardcoded in the concrete contract: `initialize()` → `__SeeToken_init(<name>, "SEE")` → `transferOwnership(SEE_MULTISIG)`.
- **Why:** Faithful to DOPPY; deploy script calls the no-arg initializer via the proxy.

### D5: Toolchain pinned to DOPPY's verified settings
Solidity `0.8.18`, optimizer enabled (200 runs), `@openzeppelin/contracts-upgradeable@4.7.3` (`draft-` permit/EIP712 paths), `@openzeppelin/hardhat-upgrades` for the transparent proxy deploy.
- **Why:** Reproduces the verified DOPPY implementation's compile profile. Note this differs from the Treasury subprojects (which use `0.8.17`, optimizer off).

### D6: Full Hardhat scaffold
`hardhat.config.js`, `scripts/deploy.js` (`upgrades.deployProxy(SEE, [], { kind: "transparent", initializer: "initialize" })`), `package.json` (`name: see-token`), `.env.example` (RPC + `PRIVATE_KEY` + `BSCSCAN_API_KEY`; no initialize-arg envs since `initialize()` is arg-less), `README.md`.

## Open Inputs (block implementation/apply)

- **SEE `name`** display string (analog of DOPPY's `"Dreams, Optimism, Playfulness & You"`).
- **`SEE_MULTISIG`** address (until provided, `address(0)` placeholder + `TODO(see)` is used).

## Risks / Trade-offs

- **Bytecode closely resembles DOPPY** → Intended; this is a faithful logic copy, not an evasion exercise.
- **External BlockList coupling** → `blockList` defaults to `address(0)` (disabled). If/when a SEE BlockList is deployed, `setBlockList` wires it; the `IBlockList` ABI must match the deployed contract.
- **Different compiler vs Treasury subprojects** → `see-token` uses `0.8.18`/optimizer-on by design; documented in its README to avoid confusion with `doppy/`/`pulsee/`.
- **Accidental ownerless deploy** → Mitigated by the `SEE_MULTISIG = address(0)` fuse + `TODO(see)` + README warning.
- **Permit domain** → `__ERC20Permit_init(name)` binds the EIP-712 domain to the (new) SEE `name`; downstream permit signers must use SEE's name/`verifyingContract`.
