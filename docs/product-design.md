# Tilo product design

Date: November 3, 2026. Product scope follows the owner's direct build request. Creative direction and Kitchen are implementation decisions delegated to Codex.

## Product

Tilo brings cooking inspiration, European and American recipes, meal planning and conversations into one iPhone app. The five bottom destinations are Live, Recipes, Kitchen, Chats and Me. Every destination preserves its own navigation stack; pushed details hide the dock.

## Reference decisions

Toti and Bibi inform interaction completeness, not identity, credentials or theme. Reuse their empty-inbox composition, contextual chat filters, explicit message creation, profile metric meanings, privacy controls, report/block management and wallet error handling. Do not seed artificial relationships, messages or balance. The November 6 owner-authorized editorial display baselines below are separate from real engagement records. Live uses sourced cooking replays with clear Replay labels, real AVPlayer lifecycle and no invented viewers or live delivery.

## Visual direction

Warm ivory paper, tomato red and deep olive; spacious cookbook cards, real food photography, generated gouache raster icons and generated paper background. Kalam Bold is used for expressive headings and Comic Neue Regular for readable handwritten body text. Minimum interactive target is 44 points. Dynamic Type, accessibility labels and reduced-motion behavior remain part of the implementation.

The November 9, 2026 entry refresh uses the owner-supplied orange and yellow wordmark from `Assets/Brand/TiloLogo.png`. The home screen icon preserves its full square artwork. The launch and welcome screens share a warm cream background. The welcome screen pairs a rounded logo tile and centered copy with a warm amber Log in button, dark brown button text, and inline agreement links.

## Functional routes

- Live: replay discovery, query/category filters, source credits, full-screen looping player, automatic looping playback, reactions, room messages, gifts, share, report and upload cooking work. Broadcast creation does not fake streaming availability.
- Recipes: original English recipes covering Italian, French, British and American cooking; search/filter; ingredient scaling, numbered steps, cook mode, timer, bookmark and meal-plan entry. Food photography is independently licensed.
- Kitchen: weekly meal planning, recipe selection, date/meal slots, persistent shopping items, ingredient aggregation, completion/removal, custom items and wall-clock cooking timers.
- Chats: real member directory, following contacts, follow-first direct conversations and mutual-friend groups, server-backed text messages, stable message IDs, history, realtime reconciliation, drafts, pin/mute and unread states. The video call entry uses the existing direct-message permission and opens a full-screen, device-only camera preview. Users can flip the camera, toggle the microphone and speaker indicators, and end the preview to return to the same chat. The preview requests camera permission only, stops when dismissed or inactive, and has no signaling, audio capture, transmission or call history.
- Me: profile/avatar editing, actual own works, received likes/saves, following/followers, saved recipes, settings, blocked members/reports, legal PDFs, wallet and ledger. New members have empty personal state.

## Service and payment boundaries

Supabase A is selected. Dedicated project provisioning, real anonymous Auth, protected rows/storage, chat and legal PDFs are in scope. B external authentication, arbitrary WebViews and external order transport are excluded. No AI is introduced. The wallet exposes recharge configuration and real StoreKit purchase handling, with the nine owner-authorized product IDs configured on November 6, 2026; no successful recharge or available Apple catalog is claimed.

## Configuration and verification

The provisional local bundle identifier is com.toli.cooking; team is unset. The owner must confirm production identity, signing and products. The owner authorized compilation, launch and major-feature acceptance on November 3, 2026, exclusively on the named iPhone simulator Tilo UI Acceptance. Current-source build and native UI results are tracked separately in runtime-acceptance/. Static checks and finite backend evidence remain distinct. The November 6 purchase request supersedes the empty-ID constraint; current purchase evidence is tracked separately in payment-configuration.md.

## Legal name and version update - November 6, 2026

The owner authorized both public agreements to use Tilo, effective November 6, 2026, while preserving their exact URLs. Version `2026-11-06-99d6afcc3037` identifies the updated English sources and is synchronized between the manifest, client and server. Historical consent records preserve their original versions. The native agreement viewer reloads the unchanged URLs without using its local cached PDFs. Earlier app builds require an update before submitting current consent.

## Welcome agreement presentation update — November 4, 2026

The owner requested the Toti/Bibi agreement pattern: a separate unchecked checkbox beside one English declaration, with underlined inline Terms of Service and Privacy Policy hyperlinks. The checkbox uses Tilo's existing image-model check artwork inside a compact outlined control, with a 44-point touch target. Agreement text uses Comic Neue and opens the existing Tilo PDF documents in-app; reading a link never changes consent. The fixed Log in action retains the existing unchecked confirmation and real authentication behavior. No agreement content, service binding or purchase configuration changes.

The owner's subsequent placement instruction puts the checkbox and declaration below Log in. A vertical footer now contains the login action followed by the complete agreement row with 14-point spacing; introductory content scrolls above it. This supersedes the earlier placement in the introductory scroll content.

## Continuous title background — November 5, 2026

Navigation titles share the underlying page background. All shared navigation bar appearances are transparent, with no background effect, opaque cream fill or separator. The page's existing generated paper artwork extends behind the title and status area; custom title fonts, text colors and navigation actions are preserved.

## Cooking room redesign — November 5, 2026

The current UIKit Teto VideoFeedController live branch is the interaction reference. Its live bubbles sit at the lower left above a single compact message/action bar; pause and comment-sheet controls belong to its Shorts branch. The room keeps playing behind gift and other sheets. Tilo adopts that room composition with its own existing generated icons and cooking media. It removes visible progress and pause controls, uses automatic background/foreground playback management and moves sound, recipe, source details, report and retry into More.

Tilo does not copy the reference's fictional automatic messages or local gifts. Actual room messages use the existing protected content_comments RPC/storage for compatibility, reconciled while the room is active, with stable server IDs and no separate comment page. Existing records are preserved; no backend migration is required. Room input is limited to 50 characters. Gifts expose selection, quantity and the actual wallet route, but sending remains unavailable until gift prices, recipient delivery and purchase configuration are established. No charge or successful gift effect is fabricated. Product IDs remain empty.

## Recipe home grid — November 5, 2026

The owner requested the Bibi post-home approach. Current CircleControllers.swift and its addTwoColumns/community-card implementation were inspected, together with the maintained two-column home notes. Tilo now uses two equal cover-led recipe columns with square food photos, compact padding, short title/category/time metadata and whole-card navigation. An odd final result keeps the left half-width slot. Detail pages and personal collections remain single-column. Accessibility text categories use one column so expanded custom text remains readable. Search, selected cuisine filters, refresh and publication continue using the existing real backend; no authored audience, author identity or engagement count is introduced. The oversized introductory copy is replaced with one short heading. Title backgrounds remain continuous with the illustrated page background.

## Short recipe journey and publisher tutorials — November 5, 2026

The recipe detail is now a short overview with the finished-dish photograph, concise facts, source-attributed video tutorial, preparation entry and saved/liked controls. Meal planning, discussion and ownership/report actions live in Recipe options. Preparation is a separate page with serving scaling, a temporary checklist and the existing server-backed shopping-list action. Cooking shows one step at a time with persistent previous/next controls, tutorial and timer routes. One shared in-memory session retains servings, checklist and current step across these routes, without replacing account data.

Current Bibi challenge detail inspiration-video actions and Teto's historical lesson section/mode navigation were inspected for progressive disclosure; their theme, data and retired feature modules are not imported. Twelve real creator tutorials were searched online and verified with YouTube oEmbed; metadata is stored in the existing editorial recipe payloads. Official embedded playback is separate from Live's no-pause replay room: tutorials retain publisher playback controls, including pause and seek. Optional tutorial metadata preserves compatibility with member recipes without a video. Existing member content is not modified.

Preparation rows use compact 44-point checkbox targets with the existing generated check artwork and a short vertical rhythm, replacing large ingredient panels so the list stays shorter.

## Inline recipe tutorial and categories — November 5, 2026

This supersedes the separate overview/preparation composition above, following the owner's explicit layout. Discovery covers remain finished-dish photographs. A recipe detail starts with its official publisher tutorial instead of a repeated photograph or Watch video tutorial button. A compact Ingredient prep / Cooking steps control switches the detail body in place. Ingredients retain one checkable row each and quantity scaling; steps appear as one numbered row per instruction. Start cooking sits above three plain, background-free Like, Save and Share controls. The inactive heart uses a separately generated hollow olive raster; the active state retains the filled red heart. Server acknowledgement still governs collection state.

The existing official-player logic becomes an independently retained view shared by detail and focused tutorial pages. Tab selection, temporary checklist updates and collection responses must not rebuild or reload it. Preparation state and step progress remain in the open recipe session. Recipe options retains meal planning, conversation, source/reload and ownership/report actions. Recipes without tutorial metadata explicitly show an unavailable-video message, without presenting a finished image as video. No catalog, account, backend or purchase configuration changes are required.

## Consistent reaction and collection states — November 5, 2026

Recipe save controls now use the hollow olive outlined bookmark when inactive and a newly generated solid golden-yellow bookmark when saved. The shared TiloIcon state selectors define like and save artwork together. The earlier replay heart toggle and pale backing are superseded by the November 6 repeatable room-reaction decision below. Recipe social actions retain their background-free layout. Text labels, accessibility selected state and values agree with the server-acknowledged state. Failed requests do not change icons or private state.

Other stateful controls were inspected: following already switches plus/check artwork, preparation uses checkbox marks, category filters use selected fill, grocery rows now distinguish pending bag/completed check artwork and completion labels and chat rows expose pinned/muted text and pin highlighting. Static collection-navigation icons identify destinations and do not represent an individual saved item.

## Cover-led cooking-room discovery — November 5, 2026

Current Teto VideoDiscoveryController.swift was inspected: two portrait columns, full-cover captions, live framing/status chrome, whole-tile entry and muted first-second video loops limited to visible tiles. Tilo adopts the room-card composition with its own warm frame, existing generated video/play icons, explicit REPLAY badge, COOKING ROOM label, recipe subject and actual filmmaker credit over real footage. It does not import Living claims, animated signal indicators, synthetic audience counts or unrelated portraits. The old white article panel and separate Enter kitchen button are replaced by whole-card entry. Source covers and cloud videos remain unchanged.

At most two visible covers play a one-second excerpt near the actual midpoint silently. The existing inspected midpoint frames guide this choice: the vegetable clip begins out of focus, while its middle shows the food clearly. Covers remain visible until a real player frame is ready; unavailable media retains its cover. Offscreen, other-tab and opened-room players are released. Backgrounding pauses covers and foregrounding reconciles visible cards. Reduce Motion uses static covers. Accessibility text categories use one column, and selected cuisine filters have consistent fill/selected traits. Search, refresh, stable room IDs and ordinary room navigation continue using existing services. No new image asset, source license, backend or payment configuration is introduced.

## Accessibility text refinements — November 5, 2026

Comprehensive screenshot review identified character-level wrapping in the recipe social controls and profile relationship labels at the maximum accessibility text category. At accessibility categories, recipe Like/Save/Share controls now stack at full width below Start cooking, and profile metrics use two columns. Standard categories retain their existing horizontal compositions. Trait changes update these layouts without recreating the recipe publisher player or changing account data. The actual red/green and standard-text regression evidence is recorded in runtime-acceptance/full-test-2026-11-05-1816/.

## Toolbar search entry — November 6, 2026

Live discovery no longer shows a search field by default. The existing generated search icon sits immediately to the left of the top-right creation action. Tapping it reveals and focuses the existing field; the same toolbar action becomes a generated close icon. Closing hides the field, clears the query and restores the current cuisine's rooms, so no invisible query remains active. Submitting dismisses the keyboard while keeping the query visible; entering and returning from a room retains the open search state. Cuisine filters, creation, cover playback and source records keep their existing behavior. No asset, backend or purchase configuration is added.


## Recipe search, personal grids and repeatable room hearts — November 6, 2026

Recipes now uses the same toolbar search pattern as Live: the generated search icon sits beside creation, reveals and focuses the field, and becomes Close search. Closing clears the query and restores the selected cuisine. Returning from a recipe retains an open query; submission dismisses the keyboard.

Bibi's MeController was inspected for its direct category/body composition, compact wallet action and shared grid layout. Tilo keeps its own identity, four actual profile metrics and three Works / Liked / Saved categories. Profile editing lives in Settings; there is no homepage edit button. A compact My wallet action replaces the oversized marketing panel. Category content shows every returned recipe in two compact square-cover columns, or one column at accessibility sizes. Odd final cards retain half width. Separate collection routes share this layout. Redundant collection-heading copy, View collection buttons and duplicate Following / Followers actions are removed; relationship metrics remain actionable. Empty and retry states remain honest.

Room hearts are repeatable applause, separate from recipe likes and bookmarks. Every tap creates a unique UUID and inserts an authenticated, owner-scoped room_reactions row. Acknowledgement advances the visit-only accessibility count and pulses the same generated red heart; failures do not advance it. There is no Unlike state, pale backing or per-user reaction limit. The heart uses the same 44-point dark circular backing as send, gift and share before and after each acknowledgement. Room reactions never enter content_likes or the Me recipe collections. Existing stored records are preserved. Purchase IDs remain empty.

Recipe detail now disables Like and Save until the original account's collection state has loaded. Initial accessibility values say Loading; Refresh recipe state in More retries a failed load. This prevents the default inactive icon from accepting input before an existing server favorite is restored. The retained tutorial and preparation state are unaffected.

The owner clarified the exact simulator name as Tilo UI Acceptance on November 6, 2026. Device 26399755-5402-48C1-A2C9-CA26E57505AB and all existing data remain unchanged; the shortened Tilo simulator name was temporary.


## Safety for published content — November 6, 2026

Every member-owned recipe and replay exposes Report content, Report cook and Block cook in its existing More menu. The server resolves the actual publisher from the content record, validates visibility and prevents self-report/block actions. The UI never guesses an account from a filmmaker credit. Member replay ownership is optional so existing editorial films remain accurate; broadcasting/publishing a replay is still unavailable.

Recipe discussion comments expose a compact generated More action. Room barrage messages expose the same content/author report and block menu through touch-and-hold and an accessibility custom action, preserving the compact room toolbar. Own comments do not offer self-report/block controls. Existing profiles and private-chat sender/profile safety routes remain available.

Editorial recipes/replays expose Report and Hide rather than an invented member block. Hides persist per account on the server and apply to discovery, detail access, collections and direct RLS reads. Settings / Hidden content restores them; Settings / Blocked cooks manages actual account blocks. Blocking an actual publisher filters their recipes, replays and comments, removes follows and revokes affected chats through existing server checks. Existing favorite/save rows are retained for a later unblock. Safety receipts trigger refreshed discovery and stale-detail checks; active chat access is reconciled against server membership rather than declaring an unrelated conversation revoked.

Reports require a valid visible target and a bounded reason. Unsupported, missing, unauthorized or own targets fail without a success confirmation. No app-side success fallback or automatic fake moderation decision is added.

## Wallet grid — November 6, 2026

The owner requested a nine-card recharge grid and complete Bibi-style native purchase behavior. Use three equal-width columns with vertical raster diamond / quantity / localized price composition, compact balance, clear load/retry/cancel/pending/delivery feedback and accessible labels. At accessibility text sizes, use one column. Keep Tilo's existing account, products, StoreKit 2 delivery and Apple ledger compatibility. Default development Run uses the explicitly labeled local StoreKit wallet; the separate Apple scheme has no local fixture.


## Publisher profiles and follow-first messaging — November 6, 2026

The owner requested independent publisher avatars on Live and recipe covers, complete profiles and small stable illustrative metrics. Five explicitly authorized, labeled editorial kitchen accounts now own only the existing twelve recipes and six replays. Original film/source credits remain intact and portraits are illustrative cooking imagery, not proof of membership or endorsement by their subjects. Other member-owned content uses its real publisher profile.

Card avatar targets open that publisher; cover targets retain content entry. Profiles show compact identity, received Likes/Saves, Following/Followers, Follow/Message/Block/Report and a direct recipe-only works grid without repeated publisher avatars. Follow-first direct messaging means each sender follows the recipient; a reciprocal follow is unnecessary. Message is hidden before the saved follow, allowing Follow to fill the primary action area. Following shrinks and Message appears only after acknowledgement; unfollow hides it and expands Follow. No Rooms tab or replay fetch belongs in a profile. Publisher avatars appear only on Live/Recipes home covers. Profile, contact picker, composer and backend creation/send permission use the same rule. Group invitations retain mutual-follow requirements.

Editorial display baselines are seeded once from 12 through 26, separately from authoritative counts and actual follow rows. Refresh/relaunch preserves the baseline and real interactions add to actual counts. Ordinary new-member statistics and wallet credit remain actual and initially zero. Blocking filters the actual publisher's content and private access; independent hide/restore remains available for recipes and replays. See publisher-profile-design.md for the complete contract and source findings.


## Device-wallet gifts — November 6, 2026

The owner requested repair of the inactive room gift page. The earlier permanent unavailable state is superseded by priced gift selection, 1/5/10 quantities, confirmation, real device-wallet debit/history, insufficient-funds handling and persisted feedback. Publisher context is verified through the existing server before spending. Current Stage A balances and gift receipts remain device/account-local; no remote creator credit or payout is claimed. Gift sheets use the large detent, and wallet activity shows credits and gifts chronologically. See room-gifts.md for the exact prices, atomic/idempotent contract and scoped acceptance.


## Half-height gift picker and receipt effects — November 6, 2026

The latest owner instruction supersedes the full-height gift picker. Keep a medium-only half-height gift sheet, compact selection/quantity rows, pinned Send action and visible undimmed cooking video. Temporarily expand the wallet for prices/history and restore half height on return. After durable gift recording, show a nonblocking generated-artwork pop and floating sprite effect above the sheet, with quantity caption and automatic cleanup. Reduce Motion uses static artwork/fade. No effect is triggered by selection, cancellation, failure or a duplicate receipt, and playback continues throughout.
