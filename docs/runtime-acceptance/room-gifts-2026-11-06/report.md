# Room gift repair acceptance — November 6, 2026

## Delivered behavior and boundary

The old gift page had no Diamond costs and hardcoded Send gift to disabled. It now shows three priced gifts (10 / 50 / 100 Diamonds), selected quantities (1 / 5 / 10), checked total, current balance and actual publisher. Sending requires confirmation; cancel preserves balance. Insufficient funds offers the existing wallet route. Recipient visibility/ownership and original account are rechecked before spending. The debit and receipt are saved atomically before balance and feedback update, with duplicate/conflicting retry protection.

Old purchase ledgers decode without losing balance or transaction IDs. Gift receipts keep historical unit price/name. Credits and gifts appear together in chronological Wallet activity, and gift/nested-wallet sheets use the large detent. Existing StoreKit product mapping and local/Apple scope separation remain unchanged. See ../../room-gifts.md for the contract.

The operation is explicitly recorded in the device/account wallet. It does not establish remote creator credit, gift settlement, payout or remote recipient acknowledgement. No backend migration, server-wallet balance, fake audience message or real Apple charge was added.

## Authorized single debit

The owner explicitly authorized one retained 10-Diamond gift in the isolated Xcode StoreKit-testing wallet, with no real charge, Apple-wallet debit or creator credit. The actual UI recorded Warm thanks for Tilo Pasta Table and changed balance from **343,000 to 342,990**. Receipt ID in the observed history: c38b7954-41c1-40b4-846d-686c497d5fb7.

The initial combined UI test confirmed that debit, then failed while navigating to a gift record buried after old purchase history inside a medium sheet. The failure is retained rather than relabeled passed. The UI was repaired by chronological activity ordering and the large sheet. The spending method was not rerun; subsequent tests read the existing record and balance only. test49 now skips routine execution unless explicitly enabled with the TILO_GIFT_DEBIT_ACCEPTANCE test compilation condition, so unattended suites do not silently repeat this authorized expense.

## Latest environment and results

- Workspace/source: /Users/apple/Desktop/Tilo; Tilo target, com.toli.cooking, Debug, iPhone only.
- Simulator: **Tilo UI Acceptance**, iPhone 17 Pro / iOS 26.0.1; 26399755-5402-48C1-A2C9-CA26E57505AB.
- Latest native build/install/launch used current workspace source. Retained source.json hashes match the tested Swift/configuration files.
- **13 hosted wallet tests passed**, zero failures, exit 0: eight existing purchase/catalog/session/environment tests plus five new gift-ledger tests. These use random account tokens and temporary ledgers, not the existing wallet. Coverage includes all nine local StoreKit tiers, permanent purchase deduplication, session reservation, catalog timeout/cancellation, atomic gift debit, duplicate/conflicting retry, save failure, insufficiency/invalid quantities, old JSON compatibility and historical gift prices.
- **2 latest native UI tests passed**, zero failures, exit 0. test48 checks available sending, prices, quantity selection, total and cancellation with unchanged balance. test50 checks the existing single gift history, the same wallet balance, playback while/after sheets and relaunch persistence without spending again.
- **375 static checks passed**. Installed ios-app-bulid references were updated and pass quick_validate.py.

Actual result bundles:

| Result | Path |
| --- | --- |
| Original disabled-button reproduction, failed as expected | /private/tmp/toli-room-gift-disabled-red-20261106-073607.xcresult |
| Initial isolated gift-ledger checks, 5 passed | /private/tmp/tilo-gift-ledger-20261106.xcresult |
| Authorized single debit followed by history-navigation failure | /private/tmp/toli-room-gift-controls-green-20261106-075903.xcresult |
| Latest selection/history/relaunch UI checks, 2 passed | /private/tmp/toli-room-gift-history-final-20261106-081905.xcresult |
| Latest wallet regression, 13 passed | /private/tmp/tilo-gift-purchase-regression-20261106.xcresult |

Selected actual screenshots under screenshots/ retain initial successful debit, initial navigation failure, current gift selection, reachable chronological history and unchanged balance after relaunch. Only the specifically authorized single debit remains in the existing test wallet; no second debit or compensating fabricated credit was performed. No new account or private message was created.

## Final launch and limits

Xcode's final observed activity was **Running Tilo on Tilo UI Acceptance**, scheme Tilo, from the latest project source. Its existing TiloDiamonds.storekit fixture and TILO_STOREKIT_MODE=local remain selected; the app remains running from Xcode. Signing, product IDs, agreements, backend stage and existing Apple wallet were preserved.

This acceptance is local StoreKit/device-wallet and native UI evidence. It does not prove Apple sandbox/production product availability or remote creator settlement. The full application suite and a dedicated gift accessibility-size runtime pass were not executed in this focused repair; the gift layout implements a vertical card arrangement for accessibility sizes.
