# chl_dpp_treasury

Монорепо для смарт-контрактов проектов Cheelee и Doppy.

## Подпроекты

- [`cheelee/`](./cheelee) — Hardhat-проект с контрактом `Treasury` (signature-based withdrawal vault) и его развёрткой под `TransparentUpgradeableProxy` на BNB Smart Chain. Подробности, адреса прокси и имплементации, инструкции по сборке/деплою — в [`cheelee/README.md`](./cheelee/README.md).
- [`doppy/`](./doppy) — параллельный Hardhat-проект Treasury для Doppy: **ERC20-only форк** Cheelee Treasury (`DOPPY` / `BNH` / `USDT` вместо `LEE` / `CHEEL` / `USDT`), вся NFT-функциональность намеренно удалена. Адрес владельца ещё не утверждён и помечен как TODO в [`doppy/contracts/Treasury.sol`](./doppy/contracts/Treasury.sol); до подстановки реального мультисига деплой намеренно невозможен. Подробности — в [`doppy/README.md`](./doppy/README.md).

## Структура репозитория

```
chl_dpp_treasury/
├── .gitignore       # общий, покрывает все подпроекты
├── README.md        # этот файл
├── cheelee/         # Hardhat-проект Treasury (Cheelee)
└── doppy/           # Hardhat-проект Treasury (Doppy)
```

Каждый подпроект самодостаточен (собственный `package.json`, `hardhat.config.js`, и т.д.). Команды (`npm install`, `npx hardhat compile`, `npm run deploy:*`) выполняются из директории конкретного подпроекта.
