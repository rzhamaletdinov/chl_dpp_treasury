# Doppy Treasury — поднять дневной лимит DOPPY с 10 до 30

Инструкция для владельцев Doppy Treasury Safe (multisig). Адресовано тем, кто будет подписывать и исполнять транзакцию.

## Что и зачем

Менять дневной лимит вывода для DOPPY с текущих `10 * 10**18` до `30 * 10**18`. Меняется одно поле — `maxTokenTransferPerDay[0]` в Treasury.

- Никакого редеплоя контракта **не** требуется.
- Никакого upgrade'а имплементации **не** требуется.
- `setTokenLimit` это onlyOwner-операция, владелец — этот Safe, поэтому транзакция должна уйти именно отсюда.

BNH (option=1) и USDT (option=2) этой транзой **не трогаем**.

## Параметры on-chain

| Параметр | Значение |
| --- | --- |
| Сеть | BSC mainnet (chainId 56) |
| Safe (owner of Treasury) | `0x53fcbbF9c2317A920F2b4272DB992881e00d3726` |
| Treasury proxy (`to` транзакции) | `0x28fDaf06991734891e5184FC1C147f60280eA8E2` |
| Treasury implementation | `0x3f81e1207324C8D329d9D0e29551165A1a5B5D71` |
| Функция | `setTokenLimit(uint256 _index, uint256 _newLimit)` |
| `_index` | `0` (DOPPY) |
| `_newLimit` | `30000000000000000000` (= `30 * 10**18`) |
| Value | `0` BNB |
| 4-byte selector | `0x0f71aa67` |

## Шаги в Safe Web App

1. Открыть Safe: <https://app.safe.global/home?safe=bnb:0x53fcbbF9c2317A920F2b4272DB992881e00d3726>.
2. **Apps** → **Transaction Builder**.
3. **Enter Address or ENS Name** — вставить адрес Treasury proxy:

   ```text
   0x28fDaf06991734891e5184FC1C147f60280eA8E2
   ```

   Если Builder подгрузил ABI прокси (а не имплементации) — нажать **«Use Implementation ABI»**, либо вручную вставить минимальный ABI:

   ```json
   [
     {
       "inputs": [
         { "internalType": "uint256", "name": "_index",    "type": "uint256" },
         { "internalType": "uint256", "name": "_newLimit", "type": "uint256" }
       ],
       "name": "setTokenLimit",
       "outputs": [],
       "stateMutability": "nonpayable",
       "type": "function"
     }
   ]
   ```

4. В **Transaction information**:
   - **Contract Method Selector**: `setTokenLimit`
   - `_index (uint256)`: `0`
   - `_newLimit (uint256)`: `30000000000000000000`
   - **ETH value**: `0`
5. **Add transaction** → **Create Batch** → **Send Batch**.
6. Safe собирает M-of-N подписей. Когда подписей достаточно, последний подписант (или любой owner) жмёт **Execute**.

## Альтернатива — режим Custom data

Если в Builder не хочется разворачивать ABI:

```text
to:    0x28fDaf06991734891e5184FC1C147f60280eA8E2
value: 0
data:  0x0f71aa670000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a055690d9db80000
```

Раскладка `data`:

```text
0x0f71aa67                                                          // selector setTokenLimit(uint256,uint256)
  0000000000000000000000000000000000000000000000000000000000000000  // _index    = 0  (DOPPY)
  000000000000000000000000000000000000000000000001a055690d9db80000  // _newLimit = 30 * 10**18
```

`0x1a055690d9db80000` в десятичном — `30000000000000000000`. Можно перепроверить:

```bash
python3 -c "print(int('1a055690d9db80000', 16))"
# 30000000000000000000
```

Селектор `0x0f71aa67` можно перепроверить независимо:

```bash
# через cast (foundry)
cast sig "setTokenLimit(uint256,uint256)"
# через node + ethers
node -e "console.log(require('ethers').id('setTokenLimit(uint256,uint256)').slice(0,10))"
```

## Что подписанты должны проверить перед подписью

- В Safe TX preview поле **To** = `0x28fDaf06991734891e5184FC1C147f60280eA8E2` (Treasury proxy, **не** implementation, **не** ProxyAdmin).
- **Value** = `0`.
- **Data**: первые 4 байта `0x0f71aa67`, затем два uint256 — `0` и `30000000000000000000`.
- В Safe **Decoded data** должно отображаться: `setTokenLimit(uint256 _index, uint256 _newLimit)` с параметрами `0`, `30000000000000000000`.
- Никаких других транзакций в батче быть не должно.

## Постпроверка после execute

1. На странице прокси на BscScan: <https://bscscan.com/address/0x28fDaf06991734891e5184FC1C147f60280eA8E2#readProxyContract> → **Read as Proxy** → функция `maxTokenTransferPerDay` с параметром `0` должна вернуть `30000000000000000000`. До исполнения там `10000000000000000000`.
2. В логах исполненной транзакции должно быть событие `SetTokenLimit(index = 0, newLimit = 30000000000000000000)`.

## Что **не** делаем этой транзакцией

- Не трогаем BNH (option=1) и USDT (option=2). Под BNH/USDT — отдельные транзакции, по этой же схеме.
- Не трогаем `signer`, массив `tokens`, `owner`.
- Не апгрейдим имплементацию.
- Не отправляем BNB и токены.

## Откат

`setTokenLimit(0, 10000000000000000000)` — той же схемой, через Safe. Обратно в `10 * 10**18`.
