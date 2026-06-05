# SEE token

Hardhat project for **SEE**, an upgradeable BEP-20 token deployed behind a
`TransparentUpgradeableProxy` on BNB Smart Chain.

SEE reuses the logic of the live **DOPPY** token
(`0x3ac8ed37f980469802d7c3777ee568b928cb3c6b` proxy →
`0x83e41e74359f3501bb98d564f2191958ef7c7486` implementation) **verbatim**. Only
identifiers, the display `name`/`symbol`, and the owner multisig differ.

> This is the ERC20 **token** itself. It is a different contract lineage from the
> `Treasury` vaults under `cheelee/`, `doppy/`, and `pulsee/` (which *release*
> tokens). `pulsee/` is the SEE Treasury vault; `see-token/` is the SEE token.

## Architecture

```
interfaces/IBlockList.sol     interfaces/ISeeToken.sol
        \                            /
         SeeToken.sol (abstract)              = ERC20PermitUpgradeable + OwnableUpgradeable
         + blockList hooks, mint/burn,          + ContextUpgradeable, ISeeToken
           setBlockList, __SeeToken_init
                    |
              SEE.sol (concrete)
              SEE_MULTISIG, MAX_SUPPLY = 30 * 10**9 * 10**18,
              initialize() -> __SeeToken_init(<name>, "SEE"),
              transferOwnership(SEE_MULTISIG), maxSupply() override
```

- `ERC20PermitUpgradeable` (EIP-2612 `permit`, `nonces`, `DOMAIN_SEPARATOR`) +
  `OwnableUpgradeable`.
- `mint(_to, _amount)` — `onlyOwner`, reverts `MaxSupplyExceeded` if it would push
  `totalSupply()` above `maxSupply()`.
- `burn(_amount)` — `onlyOwner`, burns from the caller.
- Optional external **BlockList**: `_beforeTokenTransfer` and `_approve` consult
  `blockList` (an `IBlockList`) for global/internal blocks and transfer limits.
  `blockList` defaults to `address(0)` (**disabled**) until `setBlockList` wires a
  deployed BlockList contract. The BlockList itself is a separate contract; this
  repo only ships the `IBlockList` interface.

## Differences vs DOPPY

This is a faithful logic copy. The only changes are:

| | DOPPY | SEE |
| --- | --- | --- |
| concrete contract | `DOPPY` | `SEE` |
| abstract template | `DoppyToken` / `__DoppyToken_init` | `SeeToken` / `__SeeToken_init` |
| interface | `IDoppyToken` | `ISeeToken` |
| owner constant | `GNOSIS_WALLET` | `SEE_MULTISIG` |
| `name` | `"Dreams, Optimism, Playfulness & You"` | TODO(see) — placeholder `"SEE"` |
| `symbol` | `"DOPPY"` | `"SEE"` |
| `MAX_SUPPLY` | `30 * 10**9 * 10**18` | `30 * 10**9 * 10**18` (same) |

`interfaces/IBlockList.sol` is copied **unchanged** from the DOPPY source.

## Toolchain

Matches the verified DOPPY implementation's compile profile (this differs from
the `doppy/`/`pulsee/` Treasury projects, which use 0.8.17 / optimizer off):

- Solidity **0.8.18**, optimizer **enabled, 200 runs**.
- `@openzeppelin/contracts-upgradeable@4.7.3` (the `draft-` permit/EIP712 import
  paths), `@openzeppelin/hardhat-upgrades` for the transparent proxy.

## Before deploying (REQUIRED)

1. Set **`SEE_MULTISIG`** in `contracts/SEE.sol` to the real SEE owner multisig.
   While it is `address(0)` (the `TODO(see)` placeholder), `initialize` reverts
   and no deploy is possible — an intentional safety fuse.
2. Set the final **SEE display name** in the `__SeeToken_init(...)` call in
   `contracts/SEE.sol`. The EIP-712 permit domain binds to this `name`.

## Build & deploy

```bash
npm install
npx hardhat compile

cp .env.example .env   # fill PRIVATE_KEY (+ optional RPC / BSCSCAN_API_KEY)

npm run deploy:bscTestnet   # or: npm run deploy:bsc
```

`scripts/deploy.js` deploys the proxy and calls the no-arg `initialize()`, then
prints the proxy, implementation, and proxyAdmin addresses. After a successful
deploy, transfer the **ProxyAdmin** ownership to the same SEE multisig.
