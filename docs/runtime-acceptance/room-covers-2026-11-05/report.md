# Cooking room cover study and acceptance

Date: November 5, 2026.

## Reference study before implementation

Read-only source study used the current /Users/apple/Desktop/Teto/Teto/Features/Live/VideoDiscoveryController.swift: VideoTile uses cover-led portrait tiles, overlaid title/creator identity, live framing and status chrome, whole-tile navigation and muted first-second AVQueuePlayer loops. videoGrid uses two columns with a one-column accessibility layout. syncLiveTiles restricts motion to visible discovery tiles and stops it when leaving discovery. The current UIKit implementation takes precedence over historical SwiftUI design notes. The reference project was not modified, built or launched.

Toli adopts the composition using existing generated raster video/play icons, a warm room frame, explicit REPLAY badge, COOKING ROOM label, subject/category and actual filmmaker attribution over real footage. It does not import Living labels, synthetic viewers, unrelated portraits or code-drawn icon marks. Whole-cover entry replaces the white article panel and separate entry button. Source media, IDs and cloud URLs remain unchanged.

The existing cooking contact sheet was revisited. The vegetable clip starts out of focus, so Toli adapts the motion rule to a one-second excerpt near the true midpoint, matching the previously inspected covers rather than copying the reference's opening-second choice. At most two visible covers play silently. Native forward time deltas describe actual cover playback; loading/seek offsets do not count as played time. The still cover remains until an actual layer frame is ready. Offscreen, other-tab and opened-room players are released; backgrounding pauses them. Reduce Motion retains still covers. Cuisine filters expose visible selected state. Accessibility text categories use one column.

## Build and environment

Use only Toli UI Acceptance, iPhone 17 Pro / iOS 26.0.1, 26399755-5402-48C1-A2C9-CA26E57505AB. The build helper generates current metadata, rebuilds the workspace source, installs that package and launches it before tests. Product IDs remain empty. No backend deployment, agreement change, source rehosting or new generated asset was needed.

Initial static inspection reported the new ToliLiveRoomCard.swift missing from old Xcode metadata; XcodeGen subsequently included it. The first app build succeeded, but test compilation exposed a pre-existing query error in test17: count was read from a single XCUIElement instead of an XCUIElementQuery. The query was corrected. No runtime pass is claimed from /private/tmp/toli-room-cover-grid-20261105-103705-test.log.

## Limits

This work targets discovery covers and existing room entry. It does not connect live broadcasting, invent hosts/audience, configure gift/payment delivery or validate Apple purchases. Source inspection and screenshot review are separate from native playback evidence.

## Runtime diagnosis

The initial two-case runtime bundle /private/tmp/toli-room-cover-grid-fixed-20261105-103907.xcresult passed test01ReplayPlaybackControlsAndLinkedRecipe (71.171 seconds) but failed the new cover-time assertion. Two focused diagnostic runs retained the same failure: /private/tmp/toli-room-cover-diagnostic-20261105-104435.xcresult and /private/tmp/toli-room-cover-lifecycle-diagnostic-20261105-104824.xcresult. These are not passing discovery results.

[Native diagnostics](native-cover-diagnostics.log) showed the page foreground/window/Reduce Motion gates were correct, but initial visibility evaluation happened before stack tiles acquired frames. The reference's deferred layout scheduling was then applied. The following run actually activated two cards and recorded forward native media positions, including cooking-01 from 9.5 to 9.6, 9.7 and 9.8 seconds, and cooking-02 from 4.74 through 5.1 seconds. This established actual playback rather than a loaded still frame. Temporary logging was removed afterward.

/private/tmp/toli-room-cover-layout-sync-20261105-105128.xcresult completed cover playback, filtering, search and matching-room entry, then failed when the test helper attempted to tap a disabled, offscreen Search keyboard key after clearing a query. Empty Live searches now permit Return, and the helper only taps a reachable enabled Search key. That diagnostic result remains separate from final acceptance.

## Passing default-text discovery acceptance

/private/tmp/toli-room-cover-final-20261105-105550.xcresult: test22LiveRoomCoversAndNavigation passed in 67.182 seconds, zero failures, with temporary logging removed. It verifies six real records, equal-width portrait columns, room/replay accessibility meaning, actual forward cover playback, half-width filtering, empty/search results, whole-card entry to the matching salad room, real room playback, retained search and cover playback after tab/foreground restoration. [Room grid](room-grid.png) and [searched room](searched-room.png) were visually inspected. [Filtered cover](filtered-room.png), [returned grid](returned-grid.png) and [opened room](opened-room.png) are retained.

The existing room playback/actions case passed separately in the earlier runtime batch. These focused outcomes do not replace a full-app suite or establish playback for all six covers under every network condition.

## Maximum-text and static acceptance

/private/tmp/toli-room-cover-accessibility-20261105-105944.xcresult: test23AccessibleLiveRoomCovers passed in 62.066 seconds, zero failures, at accessibility-extra-extra-extra-large. It confirms one full-width column, reachable last-room entry and ordinary dismissal. [Accessible first room](accessible-room.png) and [last room](accessible-last-room.png) were visually inspected. The wrapper restored the original large text setting in finally; a separate simctl readback confirmed large. Final static verification passed 309 checks with zero failures. Product IDs remain empty. Three distinct relevant methods have passing outcomes across the focused discovery/accessibility and existing-room batches; no full-app-suite or purchase pass is claimed.

## Final Xcode delivery state

Xcode rebuilt the latest current Toli.xcodeproj using scheme Toli and destination Toli UI Acceptance, then visibly reported Running Toli on Toli UI Acceptance. The latest app remains running on that named simulator at the restored large text setting. No StoreKit, Apple sandbox or production transaction was performed.
