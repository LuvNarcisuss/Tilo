# Compact gifts and receipt effects — November 6, 2026

## Delivered behavior

The gift picker uses a fixed medium detent, approximately half the iPhone screen. The cooking video remains visible and continues playing above it without dimming. Compact artwork cards show all three gifts and prices at ordinary text sizes; quantities and a retained Send action remain reachable. Accessibility sizes scroll choices above the retained Send action. Opening Wallet temporarily expands the sheet; returning restores half height.

After a persisted gift receipt, existing generated gift artwork springs into the visible video region with a short fan of gift/diamond sprites and a quantity caption. The overlay does not intercept touches and removes itself automatically. Reduce Motion uses static artwork and a short fade. Duplicate receipts, canceled confirmations and failed sends do not create another effect. Backgrounding and room exit cancel the overlay. Wallet persistence and device-only financial scope are preserved.

## Verification

- Latest-source build succeeded for Tilo on iPhone 17 Pro / iOS 26.0.1, Tilo UI Acceptance, device 26399755-5402-48C1-A2C9-CA26E57505AB.
- Two native UI tests passed with zero failures: test51HalfHeightGiftSheetKeepsVideoVisibleAndWalletReturnsCompact and test52HalfHeightGiftSheetAccessibilityActionsRemainReachable. They checked half-height geometry, continued playback progress, normal and accessibility controls, temporary Wallet expansion, compact return and cancellation with unchanged sampled balance.
- Two hosted UIKit component tests passed with zero failures: testAnimatedEffectLeavesPlaybackControlsAvailableAndCleansUp and testReducedMotionAndCancellationDoNotLeaveAnOverlay. They exercised rendering, touch pass-through, automatic removal, Reduce Motion and idempotent cancellation using an immutable test-only receipt. They did not invoke gifting or create a wallet record.
- Static inspection: 381 checks, zero failures. Updated installed ios-app-bulid guidance passed its skill validator.
- The 36 app/config/UI-test source hashes remain identical to the native test snapshot. Hosted effect tests were compiled and executed separately.

No new gift debit, purchase, compensating credit, creator payment or backend mutation was performed. The earlier separately authorized 10-Diamond receipt remains historical evidence. This run compares balances sampled at runtime and does not reset later owner activity. A new successful paid gift and its integrated production animation were not exercised together; positive animation rendering was tested independently to avoid an additional debit.

## Evidence

- UI result: /private/tmp/toli-half-gift-panel-20261106-091244.xcresult
- Build log: /private/tmp/toli-half-gift-panel-20261106-091244-build.log
- UI log: /private/tmp/toli-half-gift-panel-20261106-091244-test.log
- Hosted rendering result: /private/tmp/tilo-gift-effect-rendering-20261106.xcresult
- Hosted log: /private/tmp/tilo-gift-effect-rendering-20261106.log
- tested-source-sha256.json records the tested source hashes; verification.json records result paths and selected screenshot hashes.

The half-height, Wallet return and accessibility screenshots are actual native UI-test captures. isolated-effect-rendering.png is a hosted component rendering on a black test canvas, not an actual gift transaction or live broadcast. final-simulator-launch.png records the final simulator startup screen.

## Final launch and limits

Xcode UI control repeatedly returned invalid accessibility element errors while trying to select the existing Tilo project. The final IDE Run could not be confirmed. As a fallback, the already-built current application was launched on the exact named simulator through simctl with TILO_STOREKIT_MODE=local (PID 10290), and its startup screen was visually verified. This fallback does not attach the Xcode StoreKit catalog; it is not evidence of an active native purchase fixture. The existing default Tilo scheme still selects TiloDiamonds.storekit. No Bibi project build, run or settings change was performed.

Apple sandbox/production purchases and remote creator settlement remain outside this verification. The outstanding final IDE launch does not invalidate the completed native UI and component results above.
