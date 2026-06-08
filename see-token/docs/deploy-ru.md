# Деплой токена SEE — пошаговый runbook

Инструкция по выкатке токена **SEE** (обновляемый BEP-20 за `TransparentUpgradeableProxy`)
в сеть BNB Smart Chain. Рассчитана на оператора деплоя: выполняй шаги по порядку,
не пропуская проверки.

> **Что такое SEE.** Это сам ERC20/BEP-20 токен. Логика — дословная копия живого
> токена DOPPY; отличаются только идентификаторы, отображаемые `name`/`symbol`
> и владелец-мультисиг. Это **не** Treasury-хранилище из `cheelee/`, `doppy/`,
> `pulsee/` — те контракты *раздают* токены, а здесь сам токен.

---

## 0. Что именно деплоится

```
                    BNB Smart Chain
   ┌──────────────────────────────────────────────────────┐
   │   TransparentUpgradeableProxy  ◀── адрес для юзеров    │
   │        │  хранит storage, делегирует логику            │
   │        ▼                                                │
   │   SEE.sol (implementation)                             │
   │     initialize() → __SeeToken_init(name,"SEE")         │
   │     MAX_SUPPLY = 30 млрд × 1e18, owner → SEE_MULTISIG   │
   │        ▼ наследует                                      │
   │   SeeToken.sol (abstract)                              │
   │     ERC20Permit + Ownable + blockList-хуки             │
   │     mint(onlyOwner) / burn(onlyOwner) / setBlockList   │
   │                                                         │
   │   ProxyAdmin  ◀── управляет апгрейдами прокси           │
   └──────────────────────────────────────────────────────┘
```

`deploy.js` разворачивает **три** контракта: сам прокси, реализацию (`SEE`) и
`ProxyAdmin`. После деплоя владельцем токена становится `SEE_MULTISIG`
(это делает `initialize` автоматически), но владельцем `ProxyAdmin` остаётся
деплоер — его права нужно передать **вручную** (см. шаг 8).

### Параметры сборки (не менять — должны совпадать с верифицированным DOPPY)

| Параметр | Значение |
| --- | --- |
| Solidity | **0.8.18** |
| Optimizer | **enabled, 200 runs** |
| `@openzeppelin/contracts-upgradeable` | строго **4.7.3** (нужны `draft-`-пути permit) |
| Сеть mainnet | BNB Smart Chain, `chainId = 56` |
| Сеть testnet | BSC Testnet, `chainId = 97` |
| `MAX_SUPPLY` | `30 * 10**9 * 10**18` |
| `initialize()` | **без аргументов** — `name`/`symbol` зашиты в коде |

---

## 1. 🔴 Обязательная подготовка кода (без неё деплой невозможен)

В файле [`contracts/SEE.sol`](../contracts/SEE.sol) остался один `TODO(see)` —
адрес мультисига-владельца. Это намеренный «предохранитель»: пока он не заполнен,
деплой упадёт. Имя токена уже зафиксировано (`"SEE"`), его трогать не нужно.

### 1.1. Поставить адрес мультисига-владельца

```solidity
// было — предохранитель:
address public constant SEE_MULTISIG = address(0);

// стало (пример — подставь реальный адрес):
address public constant SEE_MULTISIG = 0xВашМультисигАдрес;
```

> Пока `SEE_MULTISIG == address(0)`, вызов `transferOwnership(SEE_MULTISIG)`
> внутри `initialize` реверт с **`"Ownable: new owner is the zero address"`**.
> Это защита от выкатки бесхозного токена. Деплой просто не пройдёт.

### 1.2. Отображаемое имя — оставляем просто `"SEE"`

**Решение проекта:** в отличие от DOPPY, у SEE **нет длинной расшифровки**.
И `name`, и `symbol` равны `"SEE"` — оставляем как есть, ничего не придумываем.

```solidity
function initialize() external initializer {
    __SeeToken_init("SEE", "SEE");   // ← имя = "SEE", расшифровки нет (так и надо)
    transferOwnership(SEE_MULTISIG);
}
```

> Для сравнения: у DOPPY `name = "Dreams, Optimism, Playfulness & You"`,
> `symbol = "DOPPY"`. Из-за `&` в имени BscScan показывал его с двойным
> экранированием (`...&amp;amp; You`). Решение «имя = SEE» эту проблему убирает.

> ⚠️ К `name` привязывается **EIP-712 permit domain** (`DOMAIN_SEPARATOR`).
> Раз имя зафиксировано как `"SEE"` — менять его перед деплоем не нужно,
> ничего не трогаем. (Изменить после деплоя можно только через апгрейд.)

---

## 2. Установка зависимостей и компиляция

```bash
cd see-token
npm install
npx hardhat compile
```

Компиляция должна пройти без ошибок. Если упала на путях `draft-...Permit...` —
проверь, что стоит именно `@openzeppelin/contracts-upgradeable@4.7.3`.

---

## 3. Настройка окружения

```bash
cp .env.example .env
```

Заполни `.env`:

| Переменная | Обязательна | Назначение |
| --- | --- | --- |
| `PRIVATE_KEY` | ✅ | Приватный ключ деплоера (с `0x` или без). Кошелёк должен иметь BNB на газ. **Никогда не коммить.** |
| `BSC_RPC_URL` | — | RPC mainnet. Если пусто — публичный `https://bsc-dataseed.binance.org`. |
| `BSC_TESTNET_RPC_URL` | — | RPC testnet. Если пусто — публичный seed-нод. |
| `BSCSCAN_API_KEY` | для верификации | Ключ BscScan (см. шаг 7). |

`.env` в `.gitignore` — секреты в репозиторий не попадут.

---

## 4. (Рекомендуется) Сначала testnet

Прогон на testnet ловит большинство ошибок без риска для денег.

1. Получи тестовый BNB: <https://testnet.bnbchain.org/faucet-smart>
2. Деплой:

```bash
npm run deploy:bscTestnet
```

Убедись, что вывод содержит три адреса (см. шаг 6) и нет реверта. Только после
успешного testnet-прогона переходи на mainnet.

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
upgrades.deployProxy(SEE, [], { kind: "transparent", initializer: "initialize" })
   → деплоит implementation (SEE)
   → деплоит ProxyAdmin
   → деплоит TransparentUpgradeableProxy и вызывает initialize()
   → initialize() сразу делает transferOwnership(SEE_MULTISIG)
```

---

## 6. Зафиксировать адреса из вывода

Скрипт печатает JSON — **сохрани его**:

```json
{
  "proxy":          "0x...",   // ← основной адрес токена SEE (для юзеров, бирж, кошельков)
  "implementation": "0x...",   // ← адрес логики (его верифицируем на BscScan)
  "proxyAdmin":     "0x..."    // ← админ прокси (его права передаём мультисигу, шаг 8)
}
```

- **`proxy`** — это и есть «адрес токена SEE». Его указывают везде.
- **`implementation`** — нужен для верификации (шаг 7).
- **`proxyAdmin`** — управляет апгрейдами; владелец по умолчанию = деплоер (шаг 8).

---

## 7. Верификация на BscScan

### 7.1. Получить API-ключ

Зарегистрируйся на <https://bscscan.com> (или <https://testnet.bscscan.com>),
создай API-ключ и впиши его в `.env` как `BSCSCAN_API_KEY`.

### 7.2. Верифицировать реализацию

Верифицируется контракт **implementation** (у него конструктор без аргументов —
`_disableInitializers()`, поэтому `--constructor-args` не нужны):

```bash
# mainnet:
npx hardhat verify --network bsc <IMPLEMENTATION_ADDRESS>

# testnet:
npx hardhat verify --network bscTestnet <IMPLEMENTATION_ADDRESS>
```

> Профиль компиляции (0.8.18, optimizer 200 runs) берётся из
> `hardhat.config.js` — менять ничего не нужно, он специально совпадает с
> верифицированным DOPPY.

### 7.3. Связать прокси с реализацией

На странице **proxy**-адреса в BscScan:
`Contract → More Options → Is this a proxy? → Verify`.
После этого во вкладках `Read/Write as Proxy` появятся методы токена
(`mint`, `burn`, `transfer`, `permit`, `setBlockList` и т.д.).

Контракты `TransparentUpgradeableProxy` и `ProxyAdmin` — стандартные OZ; BscScan
обычно сопоставляет их байткод автоматически.

---

## 8. ⚠️ Передать владение ProxyAdmin мультисигу

`deploy.js` передаёт мультисигу владение **токеном**, но **НЕ** владение
`ProxyAdmin`. Пока этого не сделать — деплоер сохраняет право апгрейдить прокси
(то есть подменить логику токена). Передать обязательно:

Варианты:

- через BscScan: на адресе **`proxyAdmin`** → `Write Contract` →
  `transferOwnership(<SEE_MULTISIG>)` (подписывает кошелёк деплоера);
- либо разовым скриптом / hardhat-консолью, вызвав
  `ProxyAdmin.transferOwnership(<SEE_MULTISIG>)`.

После этого и токен, и его апгрейды контролирует один и тот же мультисиг.

---

## 9. Финальный чек-лист

- [ ] `SEE_MULTISIG` в `SEE.sol` = реальный мультисиг (не `address(0)`)
- [ ] `name` оставлен как `"SEE"` (без расшифровки — по решению проекта)
- [ ] `npx hardhat compile` прошёл без ошибок
- [ ] Прогон на **testnet** успешен
- [ ] Mainnet-деплой выполнен, JSON с тремя адресами сохранён
- [ ] `implementation` верифицирован на BscScan
- [ ] Прокси помечен как proxy и связан с реализацией
- [ ] **Владение `ProxyAdmin` передано мультисигу** (`transferOwnership`)
- [ ] Владелец токена (через прокси) = `SEE_MULTISIG` (проверить `owner()`)

---

## Приложение. Поведение после деплоя

- **Эмиссия:** `mint(to, amount)` — только владелец (мультисиг), реверт
  `MaxSupplyExceeded`, если выйдет за `MAX_SUPPLY`. На старте `totalSupply == 0`.
- **Сжигание:** `burn(amount)` — только владелец, жжёт со своего баланса.
- **BlockList:** по умолчанию `blockList == address(0)` — **выключен**, переводы
  идут без ограничений. Включается позже вызовом `setBlockList(<адрес>)`
  (только владелец). Сам контракт BlockList в этом репозитории не лежит — здесь
  только интерфейс `IBlockList`.
- **Permit (EIP-2612):** `permit`, `nonces`, `DOMAIN_SEPARATOR` доступны;
  домен привязан к `name`, заданному на шаге 1.2.
