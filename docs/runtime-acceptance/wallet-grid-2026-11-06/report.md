# Tilo wallet grid and complete local purchase verification

Date: November 6, 2026 (Asia/Shanghai).

## Result

The owner requested a nine-card grid and complete Bibi-style purchase behavior. Tilo now has a compact balance and three equal-width columns of vertical diamond / amount / localized-price cards. All nine cards are visible together at the tested default text size. Accessibility text categories use one column and rebuild when the category changes.

The default Tilo Run scheme selects TiloDiamonds.storekit and DEBUG-only local mode, matching Bibi's working development setup. The final current-source application remains running from Xcode on Tilo UI Acceptance with enabled offers. A manual click on 400 Diamonds displayed the actual Xcode StoreKit sheet for Tilo / 400 Diamonds / $0.99. Dismissing it returned the cancellation message, preserved the 343,000-diamond isolated test balance and restored enabled controls. Final screenshot: [running wallet](final-wallet.png).

## Diagnosis and Bibi comparison

The supplied screenshot showed an empty App Store catalog, so disabled offers were expected. Read-only inspection of Bibi's current WalletController, WalletStore, StoreKit1Purchasing, project.yml and the skill's payment case established that Bibi's default Run selected a local StoreKit file. Tilo's default Run did not, and the previous delivery ended with a plain simctl launch without a local catalog. Default Run and final delivery now retain that actual Xcode context; no hardcoded price can authorize checkout.

Bibi's equal-width three-column rows, vertical card contents, catalog retry, real localized prices, app confirmation, native sheet, durable delivery and purchase UI verification were applied to Tilo's own products/artwork/accounts. Tilo keeps its existing StoreKit 2 verified transaction pipeline and ledger compatibility. No second purchase observer, Bibi identity/team/product value or separate Stage B backend was copied.

Review also found a redundant login catalog load; the extra callback load was removed. Ready/partial catalogs are cached for the current account, and only Refresh prices forces a new request. Entering the wallet therefore does not immediately discard returned prices or disable them again.

## Verified evidence

Environment: iPhone 17 Pro, iOS 26.0.1, device 26399755-5402-48C1-A2C9-CA26E57505AB, named Tilo UI Acceptance. Xcode 26.0.1, Swift 5 language mode. App identity remains Tilo / com.toli.cooking / iPhone only. No device or account reset occurred.

| Check | Actual result |
| --- | --- |
| Initial layout regression | Failed against the old single-column UI: first two offers had Y positions 468.667 and 536.667 instead of sharing a row. /private/tmp/TiloGridRed-20261106.xcresult |
| Final static inspection | 363 checks, 0 failures; docs/static-verification.json |
| Final isolated core purchase suite | 8 passed, 0 failed; core-summary.json; /private/tmp/TiloGridFinalUnit-20261106.xcresult |
| Final real app purchase UI suite | 2 passed, 0 failed; ui-summary.json; /private/tmp/TiloGridFinalUI-20261106.xcresult |
| All nine offers through app confirmation and app.buy | Exact configured balance deltas; 9 additional purchased StoreKit transactions; net increase 171,500 diamonds; 178.969 seconds |
| Cancellation and relaunch | App confirmation cancellation, simulated StoreKit cancellation and actual native-sheet dismissal preserved the balance; relaunch retained purchased credit; native-sheet case 66.055 seconds |
| Apple wallet isolation | Existing Apple wallet file hashes unchanged, including no new Apple wallet file; wallet-isolation.json |
| Final Xcode delivery | Active Tilo scheme, TiloDiamonds.storekit selected, local environment enabled, destination Tilo UI Acceptance, status Running Tilo on Tilo UI Acceptance; final-xcode-package.json |
| Final package | Current source snapshot matches, iPhone family [1], matching product mapping, no bundled .storekit files; deep/strict simulator signature verification exited 0 |

The initial full UI batch also passed 2 methods before the final load-cache and Dynamic Type listener corrections. Final tests above recompiled and exercised the corrected current source. Both UI purchase batches used the isolated QA StoreKit ledger, so the retained local balance is 343,000 (two verified increments of 171,500), not starting credit. Core tests use separate temporary ledgers and random account tokens.

Screenshots were inspected: [all tiers](grid-all-tiers.png), [actual native sheet](native-storekit-sheet.png), [nine purchases](nine-purchases.png), [relaunch](relaunch-wallet.png), [cancellation](canceled-wallet.png). The final manual Xcode Run was also visually inspected outside SKTestSession, including the payment sheet and cancellation recovery. The successful test bundle contains existing Supabase initial-session behavior issue attachments; its assertion/test failure counts are zero. No unrelated Auth configuration change was made.

## Data and service boundaries

Actual verified Xcode transactions require local mode and use account-scoped ToliWallet/StoreKitTesting files. Apple mode rejects Xcode transactions. Local mode rejects Apple sandbox/production transactions. Release ignores the local environment flag. The existing Apple ledger path and serialized data remain intact. Sandbox and production continue sharing that legacy Apple ledger; isolation is claimed specifically between Xcode testing and the existing Apple wallet, not between the two Apple environments.

End-to-end tests restore the already established real QA identity through normal entry and exercise the actual purchase method; they do not bypass authentication. The project rule was clarified to distinguish these account-scoped app tests from the temporary/random-token core tests. No private user wallet, account, balance or Keychain was reset.

Apple sandbox/production transactions were not run. A read-only browser attempt reached the official App Store Connect login with authResult=FAILED, so Apple product creation, application identity/team, agreements and availability remain unknown. No Apple registration, financial setting, signing identity, backend deployment or Stage B integration was changed. This local device wallet has no server receipt verification, refund reconciliation or cross-device recovery.

Not repeated in this focused payment task: the full previous five-root/chat suite, maximum Dynamic Type runtime acceptance, interrupted-delivery injection, pending approval and production purchase. Dynamic Type rebuilding received static review and compilation only. The earlier reference skill's Bibi success is local StoreKit evidence and does not establish Apple-side readiness for Tilo.
