# Full application acceptance plan

Date: November 5, 2026. Start: 18:16 Asia/Shanghai. Workspace: /Users/apple/Desktop/Tilo.

The owner requested an immediate comprehensive run while leaving the existing nightly automation unchanged. The run is limited to Toli UI Acceptance (iPhone 17 Pro, iOS 26.0.1, 26399755-5402-48C1-A2C9-CA26E57505AB), with current-source build, installation and launch before each batch. Existing isolated native and partner accounts are retained. New finite backend accounts are deleted after their checks. No production service configuration, agreement or payment product is changed.

## Planned coverage

| Layer | Planned scope | Evidence |
| --- | --- | --- |
| Static | Identity, platform constraints, fonts, generated artwork, media/source metadata, empty payment catalog | static-verification.json |
| Core UI | Consent, five roots, profile, replay, recipe search/scaling/collections/cook mode, Kitchen, wallet, PDF agreements, photo picker/upload, room and recipe discussion, share, recipe publish/edit/delete, inline links, grid and inline tutorial | Current-source core XCTest result bundle |
| Expanded UI | Six actual replays, Live search/categories, cuisine filters, invalid profile/recipe input, recipe draft restoration, cancellation of logout/two-stage deletion, timer foreground/relaunch recovery | Expanded XCTest result bundle |
| Social UI | Two real partners, mutual follows, text/photo messages, draft restoration, preferences, incoming WebSocket reply, group creation/member changes/leave, foreground retention, report/block/unblock | Social XCTest bundles plus independent partner records |
| Accessibility text | Welcome action, consent links, five roots, one-column recipe layout and last cooking instruction | Maximum-text XCTest bundle and screenshots |
| Finite backend | Three new anonymous accounts, empty personal state, session refresh, server readback, access control, realtime, deduplication, disconnected-history reconciliation, private photos, grocery atomicity/isolation, groups and deletion | backend-acceptance-final.json |
| Public resources | Anonymous download of all current manifest objects and agreement PDFs, actual-byte SHA-256 comparison | public-artifacts.json |
| Payments | Zero balance and unavailable recharge UI; static verified-transaction/atomic-ledger/account/deduplication inspection | Wallet screenshot and payment review |

Actual purchase transactions require owner-approved products and remain blocked. Physical devices, other OS/device sizes, sustained profiling, full VoiceOver, native transport fault injection and destructive native logout/account deletion are not inferred from this run. Native destructive action cancellation and real disposable backend self-deletion are separate checks. Individual publisher tutorials beyond the recipe journey's actual advancing player require separate playback evidence.

Every result will be reported by actual completed case; failures and test-harness corrections remain in the run history. Passing a subset is not full product coverage. Screenshots require visual review in addition to XCTest assertions.
