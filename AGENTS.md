# Tilo engineering rules

- Build Tilo, a cooking community app, in this workspace. Five roots: Live / Recipes / Kitchen / Chats / Me.
- iOS 16+, Swift 5, UIKit, AVFoundation. Support iPhone only, portrait orientation; disable Mac Catalyst, Designed for iPhone on Mac and Apple Vision compatibility.
- Read README.md, docs/product-design.md and docs/BackendAPI/integration.md before relevant changes.
- App identity: Tilo, target/scheme Tilo, provisional bundle identifier com.toli.cooking. Signing team and registered identifier await the owner. Never reuse Toti, Bibi or Teto service/product/account values.
- The owner confirmed the spelling Tilo on November 6, 2026. Use Tilo in current project filenames and product copy. Promptly flag statements that conflict with confirmed facts; explain uncertainty before treating a suspected mistake as a correction.
- Preserve existing compatibility identifiers during naming corrections: bundle IDs, URL scheme `toli`, Keychain service, `ToliDrafts` and `ToliWallet` data directories, `ToliKitchenTimer`, backend RPC/storage names and applied migration filenames. Historical acceptance and archived legal evidence retain their original names. The owner authorized current legal PDFs to use Tilo on November 6, 2026; preserve their existing public URLs and synchronize the content-derived consent version in the manifest, client and server.
- All project-owned text, code, documents, comments, filenames and generated asset text must be English. Converse with the owner in Chinese.
- Use image-model raster icons and background artwork, Kalam Bold headings and Comic Neue body text. No SF Symbols or system font for app-owned UI.
- Cooking media must be real sourced photography/video, with author/license/hash/representative-frame evidence. Replay content must not imply a live broadcast or real online audience.
- Supabase is the selected backend. The latest owner-selected organization is `aelm102100@139.com's Org` on the `139` connection, superseding the initial tely choice. Use the dedicated Tilo project and the A integration boundary. Preserve the old tely project unless the owner explicitly authorizes its removal. No external authentication/Socket/B integration without a later explicit continuation.
- New members start with empty personal collections, inbox, relationships and zero wallet credit. Catalog material is editorial content, not fictional member activity.
- On November 6, 2026, the owner explicitly authorized five persistent editorial kitchen accounts for the existing catalog. Cover avatars open their actual publisher profiles. Use labeled editorial collections and illustrative cooking portraits, keeping original filmmaker credits separate.
- The owner requested stable small illustrative profile statistics for these preloaded publishers only. Server-managed display baselines stay separate from actual counts, follow rows, messages and wallet values. Ordinary members retain actual statistics. Do not randomize baselines on refresh or relaunch.
- Direct messages require the sender to follow the recipient; a reciprocal follow is unnecessary. Apply this policy to profile/contact UI, existing text/photo composers and server create/send checks. Group invitations retain their independent mutual-follow rule. Unfollowing revokes new sends; blocking revokes affected content/chat access.
- Publisher profiles hide Message until following is acknowledged. Follow fills the primary action area when unfollowed; Following shrinks to share it with Message after following. Unfollow hides Message and expands Follow again. Profile works contain authored recipes only, with no Rooms category or room fetch. Publisher avatars appear only on Live/Recipes home covers, not profile/collection works cards.
- Reads/writes, messages and relationship changes must be acknowledged by the server. Never use local business success as a network fallback.
- The Stage A wallet remains device/account-local. Room gifts consume this wallet through atomic, idempotent debit receipts, with explicit device-only feedback and history. Verify the current visible publisher before spending. This is not remote creator credit, settlement or payout. Routine acceptance must not repeat a wallet debit without explicit scoped authorization.
- Room gifting uses a compact half-height picker with visible continuous video and a retained Send action. Wallet navigation may expand temporarily, then returns to half height. Animate existing generated gift artwork only after a saved receipt, in the video region above the picker; do not block playback/controls, replay duplicate receipts or animate canceled/failed gifts. Respect Reduce Motion and remove effects on completion, background and room exit.
- Keep stable IDs, account-scoped drafts, Keychain sessions and transaction deduplication. Publish wallet changes only after atomic persistence and verified transaction delivery.
- Product IDs and amounts must be owner-confirmed or explicitly delegated before enabling purchases. No fabricated price, starting balance, receipt or recharge success.
- Do not compile, typecheck, launch an app/Simulator/Preview or execute runtime tests without explicit owner authorization. Static inspection, media processing, metadata generation and finite authorized backend verification are permitted.
- Report static inspection, backend deployment, build, local StoreKit, Apple sandbox and production evidence separately.

## Repository layout

- Root: AGENTS.md, README.md, docs/, docs/BackendAPI/, scripts/, supabase/, Assets/.
- TiloApp/: project.yml, Configuration/, Tilo.xcodeproj, Tilo/ application source.
- Keep source media, import scripts and legal source outside the application target. Business media is delivered from this project's Supabase Storage. Keep shell artwork/fonts bundled.

## Authorized runtime acceptance

- On November 3, 2026, the owner explicitly authorized compilation, installation, launch, five-page/major-feature UI testing and direct fixes for Tilo. That historical empty-ID constraint was superseded by the November 6, 2026 purchase request.
- Use only the iPhone simulator named `Tilo UI Acceptance` for this acceptance work. Build the latest current-workspace source, install that package and launch it on this named device before tests; leave the latest app running after verification.
- This run uses iPhone 17 Pro / iOS 26.0.1, device `26399755-5402-48C1-A2C9-CA26E57505AB`. Do not substitute Toti/Bibi or other simulators.
- Real acceptance accounts and records must be isolated from user data. Never add authentication bypasses, fake messages, payment products or starting wallet credit for testing.

- On November 6, 2026, the owner renamed the same acceptance simulator to `Tilo`. Keep device `26399755-5402-48C1-A2C9-CA26E57505AB`; historical reports retain the former `Toli UI Acceptance` name.

- The owner clarified the full simulator name on November 6, 2026: `Tilo UI Acceptance`. This supersedes the temporary shortened `Tilo` name; keep the same device ID and data.

## Purchase catalog authorization — November 6, 2026

- The owner supplied seven exact product IDs/quantities/reference USD prices and requested two additional tiers with agent-designed quantities and 16-letter IDs. Use the nine-tier mapping in docs/payment-configuration.md and Configuration/Identity.json. This supersedes all earlier empty-product requirements.
- Keep StoreKit 2 and device/account-local durable delivery. Do not add backend Stage B, register Apple products, change signing identity or copy screenshot bank details.
- Runtime authorization continues on Tilo UI Acceptance only. Isolated core purchase tests use temporary ledgers and random account tokens. End-to-end app purchase tests use the established real QA identity and the separately labeled account-scoped StoreKitTesting ledger. Never reset or credit the existing Apple wallet.

## Bibi-style local purchase delivery — November 6, 2026

- The owner requested a 3-by-3 wallet and complete Bibi-style native purchase behavior. Default Tilo Run selects TiloDiamonds.storekit and DEBUG-only local store mode; TiloAppStore deliberately selects neither. Preserve Tilo identity, products, Stage A services and existing Apple wallet files.
- Xcode transactions require the local mode and use ToliWallet/StoreKitTesting account files. Release ignores the local launch flag. Apple sandbox/production availability remains a distinct external verification item. Final local delivery must remain launched from Xcode with the fixture active; a plain simctl launch does not retain that launch configuration.
