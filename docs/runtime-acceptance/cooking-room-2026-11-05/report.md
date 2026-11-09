# Cooking room redesign

Date: November 5, 2026.

## Study and implementation

The current Teto UIKit live branch in Features/Shorts/VideoFeedController.swift was read before implementation. Its live HUD has compact top controls, a bottom message field with send/like/gift/share icons and lower-left message bubbles. Its live branch does not use the Shorts pause or comment-panel interactions. Live messages have a 50-character limit, and its gift sheet leaves playback running. Its older docs/live-room.md describes a previous architecture and is historical, not the implementation authority.

Toli adopts this composition using its own image-model icons and custom fonts. It has no visible elapsed-time control, pause button or comment-list route in the room. More contains sound, linked recipe, retry, message refresh and reporting. Backgrounding stops playback and polling; foregrounding resumes automatically. Leaving cancels polling and releases the media item. Actual AVPlayer seconds remain available through the existing accessibility element for playback verification without a visible progress label.

Teto's fictional automatic message scripts and local gift spending are not copied. Toli reads actual protected server records every four seconds while active; only acknowledged sends clear the input. Stable server IDs reconcile up to five recent bubbles (one for VoiceOver); Reduce Motion suppresses the fade. Existing content_comments storage/RPC names are compatibility details; existing records are preserved and recipes retain their separate discussion feature. Message-author reporting uses the existing supported profile report operation.

The gift sheet supports three appreciation choices, 1/5/10 quantity selection, current balance and the wallet route. Sending remains disabled because diamond prices and recipient delivery are unconfigured; purchase IDs remain empty. No wallet debit, remote gift delivery, success effect or payment is fabricated.

## Environment and initial evidence

Latest workspace source was built, ad hoc signed, installed and launched on Toli UI Acceptance (iPhone 17 Pro / iOS 26.0.1, device 26399755-5402-48C1-A2C9-CA26E57505AB).

Initial batch result: /private/tmp/toli-cooking-room-redesign-20261105-061802.xcresult.

- test06RealReplayAndRecipeComments passed (148.645 seconds): server-acknowledged room message, close/reopen readback, and unchanged separate recipe discussion.
- test07NativeReplayShareInspection passed (48.708 seconds): actual native share controls and hierarchy.
- test01 initially failed because its first selector still requested removed description text. The test now waits for the actual gift control and reads time from the AVPlayer accessibility element rather than a removed progress label. This diagnostic failure is retained, not counted as passing.

Inspected screenshots: [Room message](room-message.png), [Persisted message](room-persisted.png), [Share](share.png). The room now leaves the cooking film visible behind compact controls.

## Playback regression

Final focused playback batch: /private/tmp/toli-cooking-room-playback-final-20261105-062630.xcresult. test01ReplayPlaybackControlsAndLinkedRecipe passed with zero failures (76.002 seconds): actual AVPlayer time advances, pause/play/comment controls are absent, time advances while the gift sheet is open, foreground playback resumes automatically, retry works and the linked recipe opens through More and dismisses correctly.

Three distinct relevant cases have passing latest outcomes across the two batches. Static verification passed 285 checks. The full earlier acceptance suite, maximum-text room layout, deliberate network failure, multi-device concurrent room delivery and actual gift/payment transactions were not rerun or validated here. Room message refresh uses polling rather than a newly deployed realtime subscription.

The gift screenshot exposed an awkward horizontal title wrap, so gift choice artwork was moved above each name before the subsequent Xcode run. No payment state or service configuration changed.

## Requested Xcode run

The current Toli.xcodeproj was opened in Xcode. The active scheme was Toli and the active destination was Toli UI Acceptance (26399755-5402-48C1-A2C9-CA26E57505AB). After building the final gift-label layout, the Xcode activity explicitly showed "Running Toli on Toli UI Acceptance" with an active debug session. The app remains running on that specified simulator. This confirms the final Xcode build/run separately from the earlier CLI XCTest batches.
