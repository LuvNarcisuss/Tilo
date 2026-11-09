# Wallet grid and usable local purchase delivery

The owner requested a 3-by-3 recharge grid and complete Bibi-style purchasing on November 6, 2026. Read-only comparison of Bibi's actual WalletController, WalletStore, StoreKit1Purchasing and project.yml identified the critical development difference: Bibi's default Run scheme selects its local StoreKit catalog; Tilo's default Run did not. The previous final simctl launch had no selected catalog. A third-party dashboard cannot establish Apple catalog registration.

## Ranked hypotheses

1. Missing Run fixture causes the simulator's empty catalog. Prediction: the Bibi-style default Run fixture returns nine actual StoreKit products and enables the nine offers.
2. Apple identity/product registration is incomplete. Prediction: the explicit Apple scheme may remain unavailable, independently of local testing. Do not substitute another app's ID/team/products or enable a reference-price checkout.
3. A stale busy/session flag prevents interaction. Prediction: a ready catalog with a current account releases busy and enables each offer; UI purchase/cancellation tests verify this path.

## Implementation and verification

- [x] Reproduce the single-column grid assertion against the existing app.
- [x] Apply Bibi's equal-width three-column rows, vertical diamond/amount/price tiles, compact balance and actionable loading/retry feedback using Tilo artwork/type.
- [x] Match Bibi's default Run local fixture and explicit Apple scheme split. Preserve StoreKit 2 verified transaction delivery and Tilo's current account/ledger format; do not introduce a second observer or Bibi's separate Stage B backend pipeline.
- [x] Isolate actual Xcode test transactions in a clearly labeled account-scoped local-testing ledger. Preserve the existing Apple ledger path and reject cross-environment transactions. Release never enables local mode from a launch environment flag.
- [x] Exercise all nine offers through the real application's confirmation and purchase method, exact diamond deltas/history, cancellation and relaunch persistence. Keep tests serial on the authorized Tilo UI Acceptance device only.
- [x] Launch the latest source from Xcode with its actual local StoreKit selection and leave the wallet visibly enabled. Do not replace that final state with simctl launch.
- [x] Save separate static/build/local StoreKit evidence and outstanding Apple sandbox/production requirements.

No App Store Connect app, financial setting, signing identity, backend Stage B service or existing private account data is changed by copying the reference implementation's behavior.

## Verification outcome

The initial grid assertion failed on the previous list. Final current-source verification passed 363 static checks, 8 core methods and 2 end-to-end UI methods. Final delivery was launched through Xcode with the fixture selected, manually opened the native sheet, canceled, and left the enabled wallet running. See report.md and final-xcode-package.json.
