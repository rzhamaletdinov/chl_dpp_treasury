# Деплой Pulsee Treasury — пошаговый runbook

Инструкция по выкатке контракта **Treasury** проекта Pulsee (обновляемый
signature-based вольт за `TransparentUpgradeableProxy`) в сеть BNB Smart Chain.
Рассчитана на оператора деплоя: выполняй шаги по порядку, не пропуская проверки.

> **Что такое Pulsee Treasury.** Это вольт-хранилище, которое выдаёт ERC20-токены
> по EIP-712 подписи доверенного `signer`, с дневными лимитами на пользователя.
> Single-token форк Doppy Treasury: обслуживает **только токен SEE**. Это **не**
> сам токен (тот лежит в `see-token/`) — Treasury *раздаёт* уже существующий SEE.

> 📌 **Зависимость:** Treasury принимает на вход адрес уже задеплоенного
> токена SEE. Поэтому **сначала деплоится токен SEE** (см.
> [`../../see-token/docs/deploy-ru.md`](../../see-token/docs/deploy-ru.md)),
> и только потом — этот Treasury.

---

## 0. Что именно деплоится

```
                    BNB Smart Chain
   ┌──────────────────────────────────────────────────────────┐
   │   Пользователь / dApp ──withdraw──▶ TransparentUpgradeable │
   │                                       Proxy (хранит state) │
   │                                          │ delegatecall    │
   │                                          ▼                 │
   │                              Treasury (implementation)     │
   │                                initialize(_signer,_see)    │
   │                                owner → CUSTODY (multisig)   │
   │                                                            │
   │   ProxyAdmin ──upgradeTo──▶ Proxy   (owner → multisig, TODO)│
   └──────────────────────────────────────────────────────────┘
```

`deploy.js` разворачивает **три** контракта: прокси, реализацию (`Treasury`) и
`ProxyAdmin`. После деплоя владельцем Treasury становится `CUSTODY` (это делает
`initialize` автоматически), но владельцем `ProxyAdmin` остаётся деплоер — его
права нужно передать **вручную** (см. шаг 9).

### Параметры сборки (⚠️ ОТЛИЧАЮТСЯ от токена SEE — не перепутать)

| Параметр | Значение |
| --- | --- |
| Solidity | **0.8.17** |
| Optimizer | **ВЫКЛЮЧЕН** (`enabled: false`), `runs = 200` |
| EVM version | default |
| `@openzeppelin/contracts-upgradeable` | **4.7.3** (та же линия, что Doppy/Cheelee) |
| Сеть mainnet | BNB Smart Chain, `chainId = 56` |
| Сеть testnet | BSC Testnet, `chainId = 97` |
| `initialize(...)` | **2 аргумента**: `_signer`, `_see` (берутся из `.env`) |
| Дневной лимит SEE | `10 * 1e18` ставится автоматически (option = 0) |

> Совпадает с Doppy Treasury (0.8.17 / optimizer **off**). Это важно при
> верификации на BscScan — профиль компиляции должен совпасть байт-в-байт.

---

## 1. 🔴 Обязательная подготовка кода (без неё деплой невозможен)

В файле [`contracts/Treasury.sol`](../contracts/Treasury.sol) есть один
предохранитель — константа `CUSTODY`:

```solidity
// было — предохранитель:
address public constant CUSTODY = address(0);

// стало (пример — подставь реальный мультисиг Pulsee):
address public constant CUSTODY = 0xВашPulseeМультисиг;
```

> Пока `CUSTODY == address(0)`, вызов `transferOwnership(CUSTODY)` внутри
> `initialize` реверт с **`"Ownable: new owner is the zero address"`**.
> Это защита от выкатки вольта без владельца. Деплой не пройдёт.

После правки — пересобрать (шаг 2).

---

## 2. Установка зависимостей и компиляция

```bash
cd pulsee
npm install
npx hardhat compile
```

Артефакт появится в `artifacts/contracts/Treasury.sol/Treasury.json`.

---

## 3. Настройка окружения

```bash
cp .env.example .env
```

Заполни `.env`:

| Переменная | Обязательна | Назначение |
| --- | --- | --- |
| `PRIVATE_KEY` | ✅ | Приватный ключ деплоера (с `0x` или без). Нужен BNB на газ. **Не коммить.** |
| `SIGNER` | ✅ | EOA-адрес бэкенда, который подписывает `WithdrawSignature` payload'ы. |
| `SEE` | ✅ | **Прокси-адрес** уже задеплоенного токена SEE (не имплементации!). |
| `BSC_RPC_URL` | — | RPC mainnet. Если пусто — публичная нода. |
| `BSC_TESTNET_RPC_URL` | — | RPC testnet. Если пусто — публичный seed-нод. |
| `BSCSCAN_API_KEY` | для верификации | Ключ BscScan (см. шаг 7). |

> ⚠️ `deploy.js` проверяет наличие `SIGNER` и `SEE` ещё до деплоя и падает с
> `Missing required env vars: ...`, если их нет. Это аргументы `initialize`.

> `SEE` должен указывать на **прокси** токена SEE (тот адрес, который видят
> пользователи), а не на implementation. Возьми его из вывода деплоя токена SEE
> (поле `proxy`).

---

## 4. (Рекомендуется) Сначала testnet

1. Тестовый BNB: <https://testnet.bnbchain.org/faucet-smart>
2. Для полноценного теста токен SEE тоже должен быть в testnet, а его прокси-адрес
   — в `.env` как `SEE`.
3. Деплой:

```bash
npm run deploy:bscTestnet
```

Только после успешного testnet-прогона переходи на mainnet.

---

## 5. Деплой

```bash
# testnet:
npm run deploy:bscTestnet

# mainnet:
npm run deploy:bsc
```

Под капотом ([`scripts/deploy.js`](../scripts/deploy.js)):

```
readInitializeArgs()  → [SIGNER, SEE]   (падает, если их нет в .env)
upgrades.deployProxy(Treasury, [SIGNER, SEE], { kind:"transparent", initializer:"initialize" })
   → деплоит implementation (Treasury)
   → деплоит ProxyAdmin
   → деплоит Proxy и вызывает initialize(SIGNER, SEE):
        • assets.push(SEE)            ← SEE регистрируется как option 0
        • dailyCaps.push(10 * 1e18)   ← дневной лимит по умолчанию
        • signer = SIGNER
        • transferOwnership(CUSTODY)  ← владелец = мультисиг
```

---

## 6. Зафиксировать адреса из вывода

Скрипт печатает JSON — **сохрани его**:

```json
{
  "proxy":          "0x...",   // ← адрес Treasury (для dApp, бэкенда, withdraw)
  "implementation": "0x...",   // ← логика (её верифицируем на BscScan)
  "proxyAdmin":     "0x..."    // ← админ прокси (права передаём мультисигу, шаг 9)
}
```

Адрес `proxy` пропиши в [README.md](../README.md) (раздел «Адреса в BSC») и отдай
бэкенду — у него в EIP-712 `verifyingContract` должен стоять именно этот адрес.

---

## 7. Верификация на BscScan

### 7.1. API-ключ
Зарегистрируйся на <https://bscscan.com> (или testnet), создай API-ключ, впиши
в `.env` как `BSCSCAN_API_KEY`.

### 7.2. Верифицировать реализацию
У implementation конструктор без аргументов (`_disableInitializers()`), поэтому
`--constructor-args` не нужны:

```bash
# mainnet:
npx hardhat verify --network bsc <IMPLEMENTATION_ADDRESS>

# testnet:
npx hardhat verify --network bscTestnet <IMPLEMENTATION_ADDRESS>
```

> ⚠️ Профиль компиляции — **0.8.17, optimizer OFF, runs 200** (из
> `hardhat.config.js`). Если верификация не сходится — проверь, что не подставил
> случайно профиль токена SEE (там 0.8.18 / optimizer ON).

### 7.3. Связать прокси с реализацией
На странице **proxy**-адреса: `Contract → More Options → Is this a proxy? →
Verify`. После этого появятся вкладки `Read/Write as Proxy` с методами Treasury
(`withdraw`, `setSigner`, `setTokenLimit`, `addToken`, и т.д.).

---

## 8. Пополнить вольт токенами SEE

Treasury выдаёт SEE из собственного баланса. Пока на нём нет токенов, `withdraw`
будет падать на переводе. После деплоя переведи нужный объём SEE на адрес
**`proxy`** Treasury (минтом со стороны владельца SEE или обычным трансфером).

---

## 9. ⚠️ Передать владение ProxyAdmin мультисигу

`deploy.js` передаёт мультисигу владение **Treasury**, но **НЕ** владение
`ProxyAdmin`. Пока этого не сделать — деплоер сохраняет право апгрейдить прокси
(подменить логику вольта). Передать обязательно:

- через BscScan: на адресе **`proxyAdmin`** → `Write Contract` →
  `transferOwnership(<CUSTODY>)` (подписывает кошелёк деплоера);
- либо разовым скриптом / hardhat-консолью: `ProxyAdmin.transferOwnership(<CUSTODY>)`.

---

## 10. Финальный чек-лист

- [ ] `CUSTODY` в `Treasury.sol` = реальный мультисиг Pulsee (не `address(0)`)
- [ ] Токен SEE уже задеплоен; его **прокси**-адрес стоит в `.env` как `SEE`
- [ ] `SIGNER` в `.env` = верный бэкенд-EOA
- [ ] `npx hardhat compile` прошёл без ошибок
- [ ] Прогон на **testnet** успешен
- [ ] Mainnet-деплой выполнен, JSON с тремя адресами сохранён
- [ ] `implementation` верифицирован (профиль **0.8.17 / optimizer OFF**)
- [ ] Прокси помечен как proxy и связан с реализацией
- [ ] Адрес `proxy` записан в README и передан бэкенду (`verifyingContract`)
- [ ] Вольт пополнен токенами SEE
- [ ] **Владение `ProxyAdmin` передано мультисигу** (`transferOwnership`)
- [ ] `owner()` Treasury (через прокси) = `CUSTODY`

---

## Приложение. Поведение и параметры после деплоя

- **Один токен:** SEE зарегистрирован как `option = 0`. Все `withdraw` идут с
  `_option = 0`. Дневной лимит — `10 * 1e18`, меняется владельцем через
  `setTokenLimit(0, newLimit)`.
- **Подпись:** EIP-712 домен `NAME = "TREASURY"`, `EIP712_VERSION = "1"`,
  `PASS_TYPEHASH = WithdrawSignature(uint256 nonce,uint256 amount,address address_to,uint256 ttl,uint256 option)`.
  Идентичны Doppy — бэкенд переиспользует тот же код подписи, меняется только
  `verifyingContract` (= адрес этого прокси).
- **Ротация signer:** `setSigner(newSigner)` — только владелец.
- **Escape hatch:** `withdrawToken(token, amount)` — владелец может вывести любые
  токены с контракта.
- **Доп. токены:** `addToken(addr, limit)` добавит ещё ERC20 (option 1, 2, …),
  но по дизайну Pulsee Treasury — single-token (только SEE).
- **Storage layout** у Pulsee свой — нельзя апгрейдить им прокси Doppy/Cheelee и
  наоборот; будущие апгрейды добавляют поля только в конец, поверх `__gap`.
