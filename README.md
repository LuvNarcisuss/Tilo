# Tilo

A native cooking community app for iPhone. Open `TiloApp/Tilo.xcodeproj` and select the `Tilo` scheme. Its default development Run now selects the local StoreKit catalog, matching Bibi; use `TiloAppStore` to inspect Apple's actual catalog without a local fixture.

The owner confirmed the spelling **Tilo** on November 6, 2026. Current app, target, scheme, source and artwork filenames use Tilo. Existing account/data compatibility identifiers retain their original spelling. Earlier runtime reports describe the pre-correction source. Both public legal PDFs now use Tilo at their original URLs, effective November 6, 2026, with consent version `2026-11-06-99d6afcc3037` synchronized in the client and server. See [legal update evidence](docs/BackendAPI/legal/update-2026-11-06/report.md). These changes have static and finite backend verification; no new native build or runtime acceptance is claimed.

## Product

Five independent navigation stacks: **Live / Recipes / Kitchen / Chats / Me**.

- **Live:** six real cooking films with two-column room covers, source credits, explicit Replay labels, visible-only muted cover excerpts and full-screen looping AVPlayer playback, automatic looping playback, compact room-message/reaction/gift/share controls, and sound/retry/report/recipe actions in More. Broadcasting and peer calling are not connected.
- **Recipes:** twelve original European and American recipes with licensed real food photography, search/cuisine filters, finished-dish discovery covers, twelve source-attributed inline publisher tutorials, compact preparation/step categories, one-step cook-along mode, bookmarks, likes, discussions and native photo-backed publishing/editing/deletion.
- **Kitchen:** dated breakfast/lunch/dinner plans, ingredient aggregation, private shopping items and clock-based cooking timers. Timers do not claim background alarms.
- **Chats:** real member directory and following contacts, follow-first direct conversations, mutual-friend group invitations, persistent text/photo messages, realtime reconciliation, history, unread state, pin/mute, group management and account-scoped offline drafts. Eligible direct chats include a full-screen local camera preview with camera flipping, visual audio toggles and an end control. No remote audio/video is sent. No synthetic delivery receipts or online counts.
- **Me:** profile/photo editing, actual received engagement and relationship counts, works/liked/saved recipe collections, safety controls, settings, legal PDFs and the diamond wallet.

The app icon, launch screen and welcome screen use the owner-supplied orange and yellow Tilo wordmark. The launch and welcome screens share a warm cream background. The rest of the visual shell uses 39 image-model gouache icons, an illustrated ivory paper backdrop, Kalam Bold headings and Comic Neue Regular body type. No SF Symbols or system font calls are used for app-owned content.

## Configuration

- iOS 16+, Swift 5, UIKit, AVFoundation, PDFKit, PhotosUI and Supabase Swift 2.55.6.
- iPhone only, portrait; Mac Catalyst, Designed for iPhone on Mac and Apple Vision compatibility are disabled.
- App, target and scheme: `Tilo`.
- Provisional bundle identifier: `com.toli.cooking`. Production registration and development team are not confirmed.
- Supabase A: dedicated project `hdapofqufmxlghmcrftg`, Singapore, in the owner-selected 139 organization `aelm102100@139.com's Org`. No Toti/Bibi account or product configuration is reused.
- One-tap **Log in** restores the saved guest or creates a real Supabase anonymous account. Anonymous sign-ins are enabled on the 139 project. Isolated real anonymous accounts exercised the current backend. The named iPhone acceptance run has now exercised native guest creation/restoration and profile persistence. The client never substitutes local success for an authentication error.
- Nine owner-authorized consumables are configured, including delegated USD 29.99 / 16,800-diamond and USD 69.99 / 42,000-diamond additions. StoreKit localized prices authorize checkout; unavailable offers remain disabled. StoreKit 2 and an atomic device/account ledger are used. Apple registration, signing and sandbox/production readiness remain unverified; server wallet authority, transfers and cross-device recovery are unavailable. See docs/payment-configuration.md.

## Project layout

`TiloApp/Tilo/` contains application code, generated shell assets and fonts. `TiloApp/project.yml` is the XcodeGen source of truth. Supabase Storage serves catalog images and replay videos. Git retains the catalog metadata, media provenance, application artwork, test source and written acceptance reports. Downloaded media, inspection frames, test recordings, screenshots, result bundles and other generated acceptance evidence are ignored.

## Codemagic release

The `tilo-ios-app-store` workflow uses Xcode 26.5 and generates the shared `TiloAppStore` scheme from `TiloApp/project.yml`. It uses Apple ID `6832414205` to look up the latest build number, then archives, exports and uploads the signed Release IPA to App Store Connect. Apple processes the upload before it appears in TestFlight. Beta distribution and App Store review are manual. The `tilo-ios-signing-validation` workflow exports the same IPA for download.

In Codemagic, configure a team App Store Connect integration named `Tilo` and make an Apple Distribution certificate and App Store provisioning profile for `com.toli.cooking` available under Code signing identities. The App Store Connect record for Apple ID `6832414205` must use the same bundle identifier.

## Static verification

Metadata generation: `xcodegen generate --spec TiloApp/project.yml`.

File/resource inspection: `python3 scripts/verify_static.py`.

See `docs/static-verification.json`, `docs/verification.md` and `docs/BackendAPI/integration.md` for actual scope and remaining dependencies. Static inspection is not compilation or runtime acceptance.

The owner authorized native acceptance on November 3, 2026. Current source has been compiled, ad hoc signed, installed and launched on **Tilo**, an iPhone 17 Pro with iOS 26.0.1. The latest outcomes of all 20 distinct major-feature UI cases passed across focused batches, including actual one-tap entry, cooking playback and real text/photo chat. Maximum-text navigation and the final default-size five-root regression also passed; see `docs/runtime-acceptance/report.md` for evidence and limits. No local StoreKit, Apple sandbox or production purchase has been performed.

## Further reading

- [Product and reference decisions](docs/product-design.md)
- [Media inventory](docs/media-inventory.md)
- [Artwork generation](Assets/Generated/prompts.md)
- [Recipe provenance](docs/recipe-provenance.md)
- [Purchase configuration](docs/payment-configuration.md)
- [Backend deployment and verification](docs/BackendAPI/integration.md)

The November 4 welcome agreement update uses a separate checkbox and inline document hyperlinks. Three default-text focused UI cases and the maximum-text agreement case passed; see [inline agreement verification](docs/runtime-acceptance/inline-consent-2026-11-04/report.md). The earlier twenty-method report remains historical evidence before this presentation update.

The subsequent placement update puts the checkbox and agreement paragraph below Log in; see [below-login update](docs/runtime-acceptance/inline-consent-2026-11-04/below-login-update.md).

The November 5 title-background update removes the separate navigation fill so existing page artwork continues through the title area. The focused five-root regression passed and all five screenshots were inspected; see [title-background verification](docs/runtime-acceptance/continuous-title-2026-11-05/report.md).

The November 5 cooking-room update replaces stacked playback/comment buttons with compact message, reaction, gift and share controls. Playback is automatic; room messages use real server records. Gift sending remains unconfigured. See [room study and verification](docs/runtime-acceptance/cooking-room-2026-11-05/report.md).

The November 5 recipe home update follows Bibi's compact two-column home-card approach, with square real food covers, whole-card navigation and a one-column accessibility layout. Details and personal collections retain their existing composition; see [recipe-home study and verification](docs/runtime-acceptance/recipe-home-2026-11-05/report.md).

The November 5 recipe journey update separates overview, ingredient preparation and cooking steps, with official publisher video tutorials. Metadata and native playback have separate evidence; see [journey verification](docs/runtime-acceptance/recipe-journey-2026-11-05/report.md) and [tutorial sources](docs/recipe-tutorial-sources.md).

The later November 5 inline recipe update replaces the detail photograph with the official tutorial player, adds ingredient/step categories and places a plain social-action row below Start cooking. This supersedes the separate preparation composition; see [inline recipe verification](docs/runtime-acceptance/inline-recipe-2026-11-05/report.md).

The owner-selected bookmark states are a hollow olive outline and solid golden yellow. Shared state artwork also covers recipe/replay likes and pending/completed grocery actions; see [state consistency verification](docs/runtime-acceptance/consistent-social-states-2026-11-05/report.md).

The later November 5 room-cover update studies Teto discovery framing and replaces article-style panels with whole-cover room entry and real muted excerpts. See [room-cover study and acceptance](docs/runtime-acceptance/room-covers-2026-11-05/report.md).

The November 5 comprehensive acceptance records 32 distinct UI methods with final passing outcomes across focused batches, 77 passing finite backend checks and 309 passing static checks. It fixes occupied-username feedback and maximum-text recipe/profile layouts; payment transactions remain unverified. See [comprehensive acceptance and limits](docs/runtime-acceptance/full-test-2026-11-05-1816/report.md).

The November 6 Live search update replaces the always-visible field with a toolbar search action beside creation. Search expands on demand and closing it clears the query; see [toolbar search verification](docs/runtime-acceptance/live-toolbar-search-2026-11-06/report.md).

## Personal UI and room-reaction acceptance — November 6, 2026

Recipes toolbar search, compact Works / Liked / Saved columns, Settings-only profile editing and separate repeatable server-backed room hearts are implemented. The renamed Tilo app passed the focused replay and personal-grid suite on the same iPhone simulator now named Tilo UI Acceptance. The final current-source package also verifies UIDeviceFamily [1], matching generator and target settings. See [scope, screenshots and evidence](docs/runtime-acceptance/personal-room-refinement-2026-11-06/report.md). Purchase IDs remain empty; no purchase environment was tested.

## Purchase catalog update — November 6, 2026

The current nine-tier catalog supersedes the empty-ID state in historical acceptance records. Local StoreKit and Apple catalog schemes are separate. See [purchase configuration](docs/payment-configuration.md) and [current verification](docs/runtime-acceptance/purchases-2026-11-06/report.md) for exact IDs, quantities and environment-specific evidence.

## Published-content safety — November 6, 2026

Member recipes, replays and comments now expose real content/author reporting and blocking. Editorial material supports account-scoped hide/restore without invented member identities. Five focused native flows have passing outcomes, 38 real-service checks passed, and all temporary publisher content was cleaned up. See [safety behavior, screenshots and verification](docs/runtime-acceptance/content-safety-2026-11-06/report.md).

## Wallet grid and purchase launch correction — November 6, 2026

Recharge uses nine equal-width vertical cards in a three-by-three grid, with a compact balance and an accessibility-size single-column layout. Default Tilo Run now selects the local StoreKit file and explicitly labeled isolated testing wallet. The prior plain simulator launch did not retain this catalog context. Ready product prices are cached for the active account; Refresh explicitly retries. See [grid and end-to-end purchase evidence](docs/runtime-acceptance/wallet-grid-2026-11-06/report.md). Apple catalog readiness remains separate.


Publisher avatars on Live/Recipes open stable author profiles with statistics, recipe-only works, Follow/Message/Block/Report. Message appears only after following; Follow expands before following and shrinks alongside Message afterward. Publisher avatars appear on home covers, while profile works and collections omit them. Current direct-message policy is sender-follows-recipient; group invitations still require mutual friends. Five owner-authorized editorial kitchens use separate stable illustrative metric baselines and real publisher IDs, with original media credits preserved. See docs/publisher-profile-design.md for the contract and docs/BackendAPI/publisher-profile-verification.json for finite service checks.


Room gifts now support priced selection, quantities, confirmation, device-wallet debit receipts and chronological wallet history. Feedback explicitly describes a recorded device-wallet operation; remote creator credit/payout is not connected. See docs/room-gifts.md.


The room gift picker now occupies half the screen so cooking footage stays visible, with a pinned Send action. Saved gifts trigger a short generated-artwork celebration in the visible video area. Wallet navigation expands temporarily and returns to the compact picker. Reduce Motion and effect cleanup are supported; presentation tests do not spend additional Diamonds. See docs/room-gifts.md.
