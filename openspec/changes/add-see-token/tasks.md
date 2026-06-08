## 0. Pre-implementation inputs

- [ ] 0.1 Obtain the SEE `name` display string (analog of DOPPY's `"Dreams, Optimism, Playfulness & You"`)
- [ ] 0.2 Obtain the `SEE_MULTISIG` owner address (or confirm `address(0)` placeholder for now)

## 1. Scaffold see-token subproject

- [x] 1.1 Create `see-token/` with `contracts/`, `contracts/interfaces/`, `scripts/`
- [x] 1.2 Add `package.json` (`name: see-token`, deps: `@openzeppelin/contracts-upgradeable@4.7.3`, `@openzeppelin/contracts@^4.9.6`; devDeps: hardhat-toolbox, `@openzeppelin/hardhat-upgrades`, dotenv, hardhat; scripts: compile/clean/deploy:bsc/deploy:bscTestnet)
- [x] 1.3 Add `hardhat.config.js` mirroring `doppy/` but Solidity **0.8.18** with optimizer **enabled, 200 runs** (bsc/bscTestnet networks, etherscan apiKey)
- [x] 1.4 Run `npm install` in `see-token/`

## 2. Port token contracts (rename identifiers only)

- [x] 2.1 Add `contracts/interfaces/IBlockList.sol` copied **unchanged** from the DOPPY source
- [x] 2.2 Add `contracts/interfaces/ISeeToken.sol` = DOPPY `IDoppyToken.sol` with `IDoppyToken` → `ISeeToken` and `GNOSIS_WALLET()` → `SEE_MULTISIG()` (errors, `mint`/`burn`/`setBlockList`/`maxSupply`/`initialize`/`blockList` signatures preserved)
- [x] 2.3 Add `contracts/SeeToken.sol` = DOPPY `DoppyToken.sol` with `DoppyToken` → `SeeToken`, `__DoppyToken_init` → `__SeeToken_init`; keep `ERC20PermitUpgradeable` + `OwnableUpgradeable`, `blockList`, `__gap[49]`, `_beforeTokenTransfer`/`_approve` hooks, `mint` (MAX_SUPPLY check → `MaxSupplyExceeded`), `burn`, `setBlockList` byte-aligned
- [x] 2.4 Add `contracts/SEE.sol` = DOPPY `DOPPY.sol` with `DOPPY` → `SEE`, `GNOSIS_WALLET` → `SEE_MULTISIG`; set `name` (placeholder, see 0.1), `symbol = "SEE"`, `MAX_SUPPLY = 30 * 10 ** 9 * 10 ** 18`; `initialize()` no-arg → `__SeeToken_init(<name>, "SEE")` + `transferOwnership(SEE_MULTISIG)`; `maxSupply()` override
- [x] 2.5 Set `SEE_MULTISIG` to the address from 0.2, or keep `address(0)` with a `TODO(see)` comment if not yet provided — kept `address(0)` placeholder
- [x] 2.6 `npx hardhat compile` succeeds and produces `artifacts/contracts/SEE.sol/SEE.json`

## 3. Deploy script and env

- [x] 3.1 Add `scripts/deploy.js`: `upgrades.deployProxy(SEE, [], { kind: "transparent", initializer: "initialize" })`, then print proxy/implementation/proxyAdmin
- [x] 3.2 Add the post-deploy note about the `SEE_MULTISIG` fuse and transferring ProxyAdmin ownership to the SEE multisig
- [x] 3.3 Add `.env.example`: RPC URLs, `PRIVATE_KEY`, `BSCSCAN_API_KEY` (no initialize-arg envs — `initialize()` is arg-less); include the `TODO(see)` / set-`SEE_MULTISIG`-before-deploy warning

## 4. Documentation

- [x] 4.1 Write `see-token/README.md`: SEE is the live DOPPY token's logic (permit + owner-gated mint w/ max supply + burn + optional BlockList), the identifier renames, that only name/symbol/owner differ, the `0.8.18`/optimizer-on profile (differs from Treasury subprojects), the external BlockList coupling (`address(0)` = disabled), and the `SEE_MULTISIG` deploy fuse / TODO-before-deploy
- [x] 4.2 Note that EIP-712 permit domain binds to SEE's `name`/`verifyingContract`

## 5. Verification

- [x] 5.1 Confirm no files under `cheelee/`, `doppy/`, or `pulsee/` were modified
- [x] 5.2 Diff `see-token` sources against the DOPPY sources to confirm only the agreed identifiers, `name`, `symbol`, and `SEE_MULTISIG` differ
- [x] 5.3 Sanity-check the ABI: `mint`, `burn`, `setBlockList`, `maxSupply`, `permit`, `nonces`, `DOMAIN_SEPARATOR`, ERC20 + Ownable methods present; `maxSupply()` returns `30 * 10 ** 9 * 10 ** 18`; `symbol()` = `"SEE"`
