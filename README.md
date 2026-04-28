# chl_dpp_treasury

Монорепо для смарт-контрактов проекта Cheelee.

## Подпроекты

- [`cheelee/`](./cheelee) — Hardhat-проект с контрактом `Treasury` (signature-based withdrawal vault) и его развёрткой под `TransparentUpgradeableProxy` на BNB Smart Chain. Подробности, адреса прокси и имплементации, инструкции по сборке/деплою — в [`cheelee/README.md`](./cheelee/README.md).

## Структура репозитория

```
chl_dpp_treasury/
├── .gitignore       # общий, покрывает все подпроекты
├── README.md        # этот файл
└── cheelee/         # Hardhat-проект Treasury
```

Каждый подпроект самодостаточен (собственный `package.json`, `hardhat.config.js`, и т.д.). Команды (`npm install`, `npx hardhat compile`, `npm run deploy:*`) выполняются из директории конкретного подпроекта.
