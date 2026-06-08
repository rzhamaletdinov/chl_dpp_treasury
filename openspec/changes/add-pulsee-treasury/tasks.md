## 1. Scaffold pulsee subproject

- [x] 1.1 Create `pulsee/` directory mirroring `doppy/` layout (`contracts/`, `scripts/`)
- [x] 1.2 Copy `doppy/package.json` → `pulsee/package.json`, rename `name` to `pulsee-treasury` and update `description`
- [x] 1.3 Copy `doppy/hardhat.config.js` → `pulsee/hardhat.config.js` unchanged (Solidity 0.8.17, optimizer off, bsc/bscTestnet networks)
- [x] 1.4 Run `npm install` in `pulsee/` and confirm OZ pins match Doppy (`@openzeppelin/contracts-upgradeable@4.7.3`, `@openzeppelin/contracts@^4.9.6`)

## 2. Treasury contract

- [x] 2.1 Copy `doppy/contracts/Treasury.sol` → `pulsee/contracts/Treasury.sol` as the starting point
- [x] 2.2 Rename state identifiers only: `tokens` → `assets`, `maxTokenTransferPerDay` → `dailyCaps`, `tokensTransfersPerDay` → `drawnPerDay`, `GNOSIS` → `CUSTODY` (update the TODO comment text to reference Pulsee/CUSTODY)
- [x] 2.3 Reduce to a single token: change `initialize` to `(address _signer, IERC20Upgradeable _see)`, keep only the SEE zero-check, push one element to `assets` and one cap to `dailyCaps`
- [x] 2.4 Verify nothing else changed: function names, events, `NAME = "TREASURY"`, `EIP712_VERSION`, `PASS_TYPEHASH`, `_option` parameter, `__gap[50]` all identical to Doppy
- [x] 2.5 Keep `CUSTODY = address(0)` placeholder so `transferOwnership(CUSTODY)` reverts until a real owner is set
- [x] 2.6 `npx hardhat compile` succeeds and produces `artifacts/contracts/Treasury.sol/Treasury.json`

## 3. Deploy script and env

- [x] 3.1 Copy `doppy/scripts/deploy.js` → `pulsee/scripts/deploy.js`
- [x] 3.2 Change `REQUIRED_ENV` to `["SIGNER", "SEE"]` and `readInitializeArgs` to return `[SIGNER, SEE]`
- [x] 3.3 Update the post-deploy console note to reference `CUSTODY` and the Pulsee multisig
- [x] 3.4 Copy `doppy/.env.example` → `pulsee/.env.example`, replace the `DOPPY/BNH/USDT` block with a single `SEE=`, update the GNOSIS/CUSTODY guidance comment

## 4. Documentation

- [x] 4.1 Write `pulsee/README.md` based on `doppy/README.md`: single SEE token, the four state renames, explicit note that bytecode stays close to Doppy (human-readability obfuscation only), `_option = 0` for SEE, and the `CUSTODY` deploy fuse / TODO-before-deploy section
- [x] 4.2 Document that backend signing is reusable from Doppy (same `PASS_TYPEHASH`/`NAME`, only `verifyingContract` differs)

## 5. Verification

- [x] 5.1 Confirm no files under `cheelee/` or `doppy/` were modified
- [x] 5.2 Sanity-check the ABI: getters `assets`, `dailyCaps`, `drawnPerDay` present; `tokens`, `maxTokenTransferPerDay`, `tokensTransfersPerDay` absent; `withdraw` signature unchanged
