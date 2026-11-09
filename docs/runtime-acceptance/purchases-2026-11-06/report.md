# Tilo purchase integration — November 6, 2026

## Scope and identity

The owner supplied seven product IDs/quantities/reference USD prices and delegated two additions. Nine consumables are configured consistently in PurchaseProducts.json, Configuration/Identity.json, TiloDiamonds.storekit and docs/purchase-products.csv. Added offers: USD 29.99 / 16,800 diamonds / mptqzvnrkdalxwce and USD 69.99 / 42,000 diamonds / hbxqfnrjvkwtcmza. No screenshot financial fields were copied.

App/target: Tilo. Bundle ID: com.toli.cooking, still provisional. Team remains unset. Backend binding and Stage A are unchanged; no service deployment, external order forwarding, server wallet, Apple registration or signing change was performed.

Authorized native environment: Tilo UI Acceptance, iPhone 17 Pro, iOS 26.0.1, device 26399755-5402-48C1-A2C9-CA26E57505AB. Toolchain: Xcode 26.0.1 (17A400), Swift 5 language mode; simulator architecture x86_64. Existing account, Keychain and device data were preserved. No device/account reset or real recharge was performed.

## Implementation

- Keep StoreKit 2, localized returned-product pricing and account-token purchase association.
- Load with a bounded 20-second request, cancellation that resumes exactly once, and session-generation rejection of stale responses. Present partial/empty/error/timeout states and disabled missing tiers without reference-price checkout.
- Keep verified-consumable/non-revoked/known-product/account checks. Extract the existing ledger operation while preserving serialized keys, permanent transaction IDs and ToliWallet paths. Validate arithmetic; atomically save before publishing and finishing.
- Reserve the wallet synchronously before logout/deletion network awaits, blocking new store operations and delivery. Preserve that reservation during local-account cleanup. Once the server confirms deletion, local sign-out errors become cleanup warnings and cannot leave the deleted business session active.
- Keep Tilo and TiloAppStore without local fixtures. TiloLocalStore supports manual local development and focused cancellation UI tests. TiloPurchases runs hosted temporary-ledger tests. StoreKit fixtures belong only to test resources, not the application resource phase.

## Executed evidence

Initial test-first compilation failed as expected because the extracted ledger/request interfaces did not yet exist; this is compilation evidence, not an executed failing runtime test. Result: /private/tmp/TiloPurchaseRed-20261106.xcresult. An initial static run correctly rejected the old empty-ID invariant before its authorized update.

The first completed purchase run executed six tests, all passing, including every locally verified consumable and exact USD fixture price. The isolated temporary ledger increased by exactly 171,500 diamonds across nine transactions and retained the balance and transaction count after decoding from disk. Duplicate delivery after reload, arithmetic overflow/invalid quantity, failed save/retry, bounded catalog timeout and cancellation waiter completion also passed. Result: /private/tmp/TiloPurchaseGreen-20261106.xcresult.

Independent static review found a logout/deletion-versus-purchase race. A new reservation test initially failed compilation because the guard API was missing. The subsequent seven-test run passed (0 failures). Result: /private/tmp/TiloPurchaseFinal-20261106.xcresult. Review then identified reservation preservation during local cleanup and server-confirmed-deletion/local-sign-out-failure handling; both were corrected and statically re-reviewed. The final combined run below covers the final preservation behavior.

The first UI test build failed on two asynchronous assertions inside synchronous XCTest autoclosures. They were corrected to await the result before asserting. Result: /private/tmp/TiloPurchaseUI-20261106.xcresult; no runtime UI coverage is claimed for that failed build.

The combined run's UI runner exited unexpectedly during launch; its retry executed zero UI tests and is not a passing verification. That stalled run was stopped. A separate ad hoc signed UI run also failed: the result records one test failure, “Test crashed with signal kill.” No completed catalog or cancellation assertion is claimed for either run. Captured simulator diagnostics did not establish a definitive kill cause, and system free memory was 57% at inspection. The subsequent test-only adjustment moves StoreKit setup and application launch into the main-actor test method to match the skill's verified reference structure; the final isolated UI run passed, as recorded below.

The final production-source isolated purchase run executed **7 tests with 0 failures**, including all nine actual local StoreKit consumables and reservation preservation across local cleanup. Result: /private/tmp/TiloPurchaseVerified-20261106.xcresult. The machine summary is purchase-tests-summary.json. This run also includes the final transaction-update notice correction, so deferred approval no longer leaves a pending notice after a successful durable delivery; deferred approval itself remains unexecuted.

## Final verified results

- Static: **350 checks, 0 failures** in docs/static-verification.json.
- Build: final current-source simulator package compiled and ad hoc signed. Package identity, exact product mapping and absence of bundled StoreKit fixtures passed package-verification.json; codesign --verify --deep --strict exited 0. No device signing or registered Apple identity is claimed.
- Local StoreKit: **7 isolated tests, 0 failures**, 9 consumable transactions, exact USD fixture prices, 171,500 total diamonds saved/reloaded in temporary storage. purchase-tests-summary.json records the actual device and counts.
- Wallet UI: **1 test, 0 failures**, 99.556 seconds. Every package's actual fixture price and enabled state were checked. The two added tiers were captured. App confirmation cancellation and native StoreKit-sheet dismissal preserved the existing member's zero balance and recovered enabled controls. The actual native sheet showed Tilo, 400 Diamonds and $0.99, and explicitly identified a local test purchase. Result: /private/tmp/TiloPurchaseUIMainActor-20261106.xcresult; wallet-ui-summary.json.
- Screenshots were inspected: [added tiers](new-tiers.png), [higher tiers](higher-tiers.png), [native local sheet](native-local-sheet.png), [canceled wallet](canceled-wallet.png). The native accessibility hierarchy is native-sheet-hierarchy.txt. Checksums are recorded in screenshot-manifest.json.
- The successful UI result contains two identical existing Supabase SDK initial-session behavior issue attachments. The result's assertion/test failure count is zero. Authentication reconfiguration was not added to this payment task.
- Apple sandbox: not run. Production: not run. Backend deployment/receipt service: not performed.

The two earlier UI-runner exits remain recorded as failed/interrupted attempts, not passing cases. Moving setup into the main-actor method matches the verified skill reference and produced the passing run; the original signal-kill cause was not conclusively established.

## Isolation and limits

Completed automated test transactions use random appAccountToken UUIDs and temporary ledger directories. The test host stays at ordinary welcome entry; it never loads or credits the acceptance member wallet. No StoreKit transaction-history reset is performed. The UI test uses ordinary real account entry and cancels both the app confirmation and actual native sheet, comparing the member's before/after balance.

A local StoreKit run proves only the fixture/client operations actually exercised. Apple sandbox and production catalog/transactions remain unverified. App Store Connect products, registered identity, signing team, agreements and availability require owner-side confirmation. No server validation, cross-device recovery, transfers, gift delivery, payout or refund reconciliation is implemented.

Not executed: simulated partial/invalid Apple catalog, restricted-payment device state, Ask to Buy approval/rejection, forced verification failure, actual account deletion/logout during payment, full previous UI regression, Apple sandbox and production payment. Those cases are not marked passed. The account-ending gate is covered by isolated state tests and static review rather than a destructive real-account flow.

The compiler reported existing unrelated warnings in backend async/realtime calls and RecipesController captures, plus the standard no-AppIntents metadata warning. These were not broadened into unrelated refactoring.

## Final installed state

The final current-source ad hoc simulator package is reinstalled and launched on the same authorized device after testing. See final-launch.json for the actual launch result. No simulator, Keychain, member wallet or private data reset is performed.
