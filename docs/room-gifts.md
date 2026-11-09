# Room gifts

## Current implementation — November 6, 2026

The gift sheet previously contained a permanent disabled Send gift button and no configured costs. It now uses the existing device/account wallet and real stored credit. Warm thanks costs 10 Diamonds, Kitchen cheer 50, and Chef's star 100. These are Tilo virtual-gift implementation choices for the requested repair, not additional StoreKit products or reference USD prices. Quantity controls offer 1, 5 and 10; business validation accepts only 1 through 99 with checked totals.

The page shows the current wallet balance, actual publisher, selected gift/quantity and total. Selection and quantity have matching visible/accessibility states. Sending requires confirmation; cancellation does not write. Insufficient funds opens a clear message and My wallet route without changing state. Recipient loading, errors and retry remain honest. The gift picker uses a medium-only half-height sheet with an undimmed video region. Gift/quantity selection is compact and Send stays pinned in the footer. Wallet navigation temporarily switches to the large detent; returning restores medium. Large-text choices scroll within the same half-height sheet.

The current server visibility/ownership context is read both when opening the sheet and before spending. Missing, blocked, self or changed publishers cannot consume credit. Original filmmaker names are not gift-recipient account identifiers. Account/generation checks and the wallet busy/session-end reservation prevent cross-account spending and concurrent session teardown.

The debit and TiloGiftReceipt are saved together atomically before publishing balance, page confirmation and room feedback. Receipt UUIDs deduplicate retries; conflicting retries are rejected. Failed saves and insufficient balance preserve prior state. Historical receipts retain their unit price/name independently of later catalog changes. Old wallet JSON without gifts decodes with an empty gift list; balance, purchase transaction IDs, positive credit activity and compatibility paths remain intact. Local Xcode and Apple wallets retain their existing separate scopes.

Wallet activity merges positive purchase records and negative gift records by date, with latest activity first and stable record IDs. It does not bury new gift records behind all old recharge records. Gift balance loading does not require another StoreKit price fetch. StoreKit product IDs, quantities, verification, signed transaction delivery and catalog configuration are unchanged.

## Boundary

This is a durable device-wallet gift operation. It does not credit a remote creator balance, settle money, create payout entitlement or claim remote receipt. The app labels the operation as recorded in this device's wallet. No server wallet, remote gift event, fake broadcaster acknowledgement or automatic audience message was introduced. A future server economy needs its own verified authoritative credit/spend/delivery contract; it must not trust a client-supplied balance or double-debit this device ledger.

## Acceptance

The owner explicitly authorized exactly one retained 10-Diamond debit in the isolated StoreKit-testing wallet. Actual UI evidence shows 343,000 becoming 342,990 and a receipt for Warm thanks / Tilo Pasta Table. A first history-navigation check failed after this successful debit; it was not rerun to charge again. Follow-up checks read the same saved record and balance only. The mutating UI test now requires TILO_GIFT_DEBIT_ACCEPTANCE as an explicit test compilation condition and skips in routine runs. There is no app authentication or payment bypass flag.

Current build, isolated ledger tests, native screen/history checks and remaining boundaries are recorded in runtime-acceptance/room-gifts-2026-11-06/report.md. Local verification is not Apple sandbox/production purchase or remote payout verification.


## Gift effects and compact presentation

On a persisted receipt, the room shows the generated gift artwork with a spring pop, a fan of floating gift/diamond sprites and a brief artistic caption. The overlay occupies only the visible video above the picker, never intercepts controls and removes itself after approximately 2.6 seconds. Reduced Motion uses a static gift with a short fade. Each receipt animates once during that room visit; cancel/failure never emits an effect. Backgrounding or leaving the room cancels and clears it. The effect creates no receipt and changes no money.

Current half-sheet UI/playback and isolated effect rendering/lifecycle results are in runtime-acceptance/half-gift-effects-2026-11-06/report.md. No additional gift debit was performed to verify this presentation change. The earlier large-picker decision is superseded; the wallet remains temporarily expandable.
