# Tilo payment configuration

## Owner-authorized catalog — November 6, 2026

The owner supplied seven consumables in a screenshot and explicitly delegated two additions. All IDs below are 16 lowercase ASCII letters. Screenshot bank/account fields are unrelated to StoreKit and are not stored in this project. All prices are reference USD tiers; the app displays and confirms only actual StoreKit localized prices.

| Reference USD | Diamonds | Product ID | Source |
| --- | ---: | --- | --- |
| 0.99 | 400 | `zvoxmetxtpphulex` | Owner screenshot |
| 1.99 | 800 | `kkmbaosirntvbmst` | Owner screenshot |
| 4.99 | 2,450 | `tvrtrputxdlcupaf` | Owner screenshot |
| 9.99 | 5,150 | `wdmsigccwqigfbuv` | Owner screenshot |
| 19.99 | 10,800 | `qyomdfvoxwmnwffd` | Owner screenshot |
| 29.99 | 16,800 | `mptqzvnrkdalxwce` | Owner-delegated addition |
| 49.99 | 29,400 | `zrailjkjqgtaanyw` | Owner screenshot |
| 69.99 | 42,000 | `hbxqfnrjvkwtcmza` | Owner-delegated addition |
| 99.99 | 63,700 | `bujuisktutcsnouo` | Owner screenshot |

The two new quantities are implementation choices authorized by the owner: 16,800 at USD 29.99 and 42,000 at USD 69.99. Their IDs must be created identically in App Store Connect and, if later used, the owner-managed configuration dashboard. `purchase-products.csv` is a comparison/preparation sheet, not an Apple import format. No remote dashboard or Apple catalog was changed.

## Client behavior

StoreKit 2 remains the purchase API. The app requests the configured IDs, retains valid consumables in a partial response, disables unavailable tiers, and provides retry for empty/error/timed-out requests. Only returned products can reach the app confirmation and Apple purchase sheet. Busy/restricted purchases are disabled. Canceled and pending results never credit. Requests are bounded and invalidated on session end. Logout and account deletion reserve the wallet synchronously before network awaits, preventing new purchases until failure recovery or session teardown.

Verified transactions require a configured product, consumable type, non-revoked status and matching account token. Checked arithmetic and permanent transaction IDs prevent overflow and duplicate delivery. The account ledger is atomically saved before publishing a balance or finishing a transaction; failed delivery stays unfinished for a later retry. Existing Apple `ToliWallet/<account>.json` paths and serialized fields are preserved. Verified Xcode transactions require local mode and use `ToliWallet/StoreKitTesting/<account>.json`; Apple mode rejects them. Local mode rejects sandbox and production transactions. Release ignores the local launch flag. The legacy Apple ledger continues to combine Apple sandbox and production for compatibility; these two Apple environments are not claimed to be isolated.

Wallet credit remains device/account-local. There is no server-authoritative balance, receipt service, cross-device recovery, gift transfer, refund reconciliation or payout. No backend B workflow is added.

## Development paths

- `Tilo`: Bibi-style default development Run with `TiloDiamonds.storekit` and DEBUG-only `TILO_STOREKIT_MODE=local`. Launch it from Xcode to keep the actual StoreKit test catalog active.
- `TiloAppStore`: explicit Apple catalog scheme; no fixture.
- `TiloLocalStore`: the same local configuration, plus focused end-to-end wallet UI tests. Completed purchases use the established real QA identity and its separate `ToliWallet/StoreKitTesting` ledger; they never credit the existing Apple ledger.
- `TiloPurchases`: hosted isolated purchase tests using the same fixture. Completed test transactions use random account tokens and temporary ledgers, never the acceptance account wallet. The fixture is copied only into the test bundle.

## External dependencies

The provisional bundle ID remains `com.toli.cooking`; production registration and development team are unconfirmed. The screenshot establishes a mapping, not App Store Connect registration. The owner must create/verify nine Consumable products with matching IDs, prices, localizations and availability for the intended registered app, plus signing, Paid Apps Agreement and sandbox setup. No bank data or template team is required in the client.

## Evidence boundary

The original purchase evidence is recorded in `runtime-acceptance/purchases-2026-11-06/report.md`; the subsequent Bibi-style grid, default-run correction and full app purchase tests are recorded in `runtime-acceptance/wallet-grid-2026-11-06/report.md`. Build, isolated delivery tests, local StoreKit, Apple sandbox and production results must be reported separately. Local configuration is not uploaded to Apple. No successful sandbox/production purchase or server delivery is claimed.

## References

[Apple product discovery](https://developer.apple.com/documentation/storekit/product/products(for:)), [transaction account token](https://developer.apple.com/documentation/storekit/transaction/appaccounttoken), [StoreKit test sessions](https://developer.apple.com/documentation/storekittest/sktestsession).

## Bibi comparison and launch correction

Read-only inspection of Bibi confirmed its three-column vertical cards, default Run fixture, explicit AppStore scheme, returned-product-only checkout, localized prices, bounded catalog requests, durable delivery and local UI purchase verification. Tilo now follows those behaviors with its own nine products, artwork, account data and existing StoreKit 2 verifier. Bibi's separate Stage B backend, team, app identity and goods are not Tilo configuration.

Ready and partial catalogs are cached for the active account. Opening Wallet does not immediately clear loaded prices or disable the offers; Refresh prices explicitly reloads. Login has one initialization path. Dynamic Type changes rebuild the default 3-by-3 grid as one column for accessibility categories.

Do not finish a local development delivery by reinstalling and launching with simctl: that launch does not select Xcode's local catalog. Keep the final current-source app running from Xcode with the default Tilo scheme and named Tilo UI Acceptance destination.


## Room gift consumption — November 6, 2026

Room gifts now consume existing device-wallet Diamonds with atomic debit receipts, confirmation, balance checks and chronological activity. The nine StoreKit products and verified credit delivery remain unchanged. This is not a server transfer or creator payout. The owner authorized one retained 10-Diamond debit only in StoreKitTesting for acceptance; the Apple ledger is unchanged. Routine UI suites skip the mutating gift test unless explicit scoped authorization enables its test compilation condition. See room-gifts.md for implementation and runtime-acceptance/room-gifts-2026-11-06/report.md for evidence.
