# Tilo Supabase Integration

Naming note — November 6, 2026: The owner confirmed Tilo. Current native source is `TiloApp/Tilo/Backend`, with target and scheme Tilo. Backend project names and RPC/storage identifiers retain their existing values. The subsequent owner-authorized legal update replaced both public PDFs at unchanged URLs and synchronized consent version `2026-11-06-99d6afcc3037` in the client and server. Earlier acceptance records remain historical; no new native build was performed.

Status: Stage A backend deployed and independently verified in the user-selected 139 organization, including real anonymous authentication. Native source has now been compiled and exercised on the owner-authorized Tilo UI Acceptance iPhone simulator. Major-flow native acceptance passed on the named simulator; exact scope and limits are recorded in ../runtime-acceptance/report.md.

## Project and scope

- Project: `Toli-139-20261103`, reference `hdapofqufmxlghmcrftg`.
- Organization: `wuwstedwrsfrxkbxjuqa`, the user-selected 139 account (`aelm102100@139.com's Org`).
- Region: Singapore (`ap-southeast-1`). Creation quote: USD 0 per month. This is the quote returned for creation, not a promise about future usage charges.
- API origin: `https://hdapofqufmxlghmcrftg.supabase.co`.
- Application source: `TiloApp/Tilo/Backend`. Migration and Edge source: `supabase/`.
- Production Swift dependency: official `supabase-swift`, exactly `2.55.6`, product `Supabase`. The current acceptance build compiled against that pinned source.
- Finite deployment-check dependency: official `@supabase/supabase-js`, exactly `2.80.0`, outside the iOS target, with its lockfile in `supabase/`.
- Selected workflow: `ios-swift-supabase-one-tap`, Stage A. No external B authentication, custom Socket, external web routing, remote purchase processing or AI service was added.

## One-tap account entry

The native welcome screen uses one login action after adulthood and agreement confirmation. The service restores and refreshes the existing Supabase identity from Keychain; only an absent identity creates a new anonymous account. A failed restoration does not create a replacement account. Auth access and refresh tokens use a custom `AuthLocalStorage` backed by Keychain with device-only accessibility.

The authenticated `bootstrap` Edge Function validates the user through Auth and invokes the guarded database bootstrap. Its Stage A response is `{ "code": 0, "message": "ok", "data": {} }`. The app then records adulthood and the exact content-derived agreement version `2026-11-06-99d6afcc3037` before loading the profile. The previous version `2026-11-03-24e387172fe8` remains in historical consent rows; new acceptance must use the current version. No external destination is encoded in this empty configuration.

Anonymous sign-ins were initially disabled on the new project. The current browser was authenticated into the correct 139 organization, so the authorized anonymous sign-in setting was enabled and saved through the dashboard. Three real anonymous Auth sessions were then created using this project's publishable key and used for the independent finite backend checks. No email/password identity or another project's account was used for these current checks. All three disposable anonymous accounts were subsequently deleted through the real account-deletion endpoint.

## Data and actions

`public.toli_action(action, body)` is a security-invoker RPC wrapper. Its implementation lives in a non-exposed private schema, verifies `auth.uid()` against an existing Auth account, and applies explicit ownership, membership and visibility checks. Public tables have RLS. Existing business writes use guarded RPC operations; room_reactions alone additionally permits authenticated own-row inserts under RLS, with returned-row acknowledgement. Service keys remain in the Edge environment.

| Area | Server authority | Finite backend result |
| --- | --- | --- |
| Profiles | Auth-owned profile, validated username, optional own uploaded avatar, real counts | Read/update and account isolation checked |
| Discovery | Published recipes and cooking videos, JSON payloads, cloud media | Ordinary new users read all 12 recipes and 6 videos |
| Recipe publishing | Full typed payload validation; existing photo in the author's own Storage path | Publish/edit/delete and malformed/unowned/external photo rejection checked |
| Collections | Own bookmarks and likes, real authored works | Persistence and user isolation checked |
| Comments and reports | Auth-derived author; bounded text; server-stored reports | Comment read/write and profile/recipe/video reporting checked |
| Relationships | Unique follows; block in either direction removes interaction visibility | Follow/mutual/block and blocked-content negatives checked |
| Meal plans | Own date and meal slot; visible recipe reference | Write/read/delete and account isolation checked |
| Groceries | Own records; atomic ingredient batches; normalized name aggregation | Batch rollback, aggregation, checkbox and deletion checked |
| Direct chat | Sender follows recipient at creation and every send; private member access | Real persistence, bidirectional realtime, idempotency and revoked-follow rejection checked |
| Group chat | Two to thirty other mutual cooks; only owner changes others | Create/list/add/remove/leave and nonowner/nonmember rejection checked |
| Conversation preferences | Own membership row for unread progress, pin, mute, draft and hidden state | Readback and protection of another member's unsent draft checked |
| Chat images | Private Storage path includes conversation and sender; actual object required | Upload/send, authorized signing, nonmember and forged/missing-object rejection checked |
| Account deletion | Verified-token identity; removes owned cloud media and cascaded business records | Three disposable accounts deleted through actual endpoint; old-token business calls rejected |

Drafts and wallet state on the device remain scoped to the original account. The native deletion path requests removal of only that account's private app files after server acknowledgement and reports local cleanup failures distinctly. Logout and deletion refuse to start during an active wallet update. These native paths were statically reviewed, not executed on an iPhone.

## Realtime and permissions

Messaging uses Postgres Changes for `messages`, `conversations` and `conversation_members`, added to the existing `supabase_realtime` publication. Receivers are registered before `subscribeWithError`; channel status is observed. Successful subscription and foreground/reconnect paths reconcile authorized database history. Stable server IDs deduplicate send acknowledgements and realtime echoes, while a fixed client ID deduplicates retried sends; conflicting retry content is rejected.

The Swift service publishes messages and conversation state on the main actor. Its account generation and original identity are checked before a request is transmitted and after a response. Explicit denied access and authoritative membership reconciliation clear active content through `inaccessibleConversationIDs`; transient network failures do not masquerade as revocation. The native conversation UI also reconciles access while visible.

Membership table reads expose only the requesting user's row, so other members cannot retrieve unsent drafts, mute preferences or hidden timestamps. Group member lists use a separate guarded server projection. Blocking any participant makes a shared group inaccessible to that blocked pair under the current conservative policy.

A member removed from a conversation cannot read or send new rows. Previously viewed material cannot be erased from another device. Private image URLs expire after 300 seconds; a URL already issued can remain usable until expiry, while blocked or removed users cannot obtain a new one. Postgres Changes is not a guarantee of background iOS execution or offline push delivery. No fabricated online presence, read receipts, auto-replies, RTC or remote notifications were added.

## Catalog and media evidence

The 12 recipe and 6 cooking-video source records are preserved in `docs/catalog-recipes.json` and `docs/catalog-videos.json`; `supabase/catalog-seed.sql` imports them idempotently without replacing later user records. Video credits identify the original filmmaker, not a registered cook or a live host. No Auth accounts were created for stock-photo subjects or editorial authors.

All 29 processed media objects from `Assets/PublishedMedia` and the two legal PDFs were uploaded to this project and then fetched without credentials. All 31 objects matched the expected SHA-256, length and MIME type: 12,083,347 bytes in total. See `media-upload-manifest.json` and the root media provenance records. These are actual inspected bytes, not silently substituted upstream originals. Public catalog objects use `toli-catalog`; agreements use `legal`; avatars and published recipe photos have separate owner-scoped upload policies; chat images remain private.

The temporary fixed-manifest import accepted only allowlisted object keys with exact byte counts and hashes and an expiring, temporary authorization. It was replaced by `catalog-ingest` version 2 returning HTTP 410; a real request confirmed closure. No maintenance token or service key is included in the app or repository.

## Legal documents

- Terms: https://hdapofqufmxlghmcrftg.supabase.co/storage/v1/object/public/legal/2026-11-03/terms.pdf
- Privacy: https://hdapofqufmxlghmcrftg.supabase.co/storage/v1/object/public/legal/2026-11-03/privacy.pdf

Both English, searchable, single-page PDFs were rendered and visually inspected, parsed, and anonymously downloaded with matching MIME and hashes. `legal/manifest.json` records sources, hashes, version and object paths. `support@toli.com` is proposed; activation is not confirmed. These are project documents, not a claim of legal review. After initial user delivery, only an explicit user request authorizes changing their content, sources, public objects, versions or links.

On November 6, 2026, the owner explicitly requested the Tilo name correction, synchronized documents/versions and unchanged links. Both PDFs were replaced at the two URLs above and independently downloaded with byte-for-byte matches. Their effective date is November 6, 2026. Only the version literal changed in the deployed private RPC implementation; its normalized definition matched the pre-update digest. All four historical consent rows retained the same count and content digest. Original source/PDF/manifest evidence is archived under `legal/history/2026-11-03-24e387172fe8/`; dated current-version cloud snapshots are also recorded in the current manifest. The original 31-object upload manifest remains initial-deployment evidence. See [legal update evidence](legal/update-2026-11-06/report.md) for current hashes and limits. Previously built apps with the old version must be rebuilt before new consent submissions can succeed. The updated PDF viewer bypasses its local cache while retaining the exact URLs.

## Verification and remaining dependencies

The latest user instruction explicitly replaced the earlier tely selection with the 139 organization. Current configuration, SDK publishable key, catalog references, Storage links and service evidence all bind to `hdapofqufmxlghmcrftg`. The 12 recipes and 6 corrected cooking-video records were compared in full, field for field, with the current source catalog. No old-project test was relabeled as a new-project result.

`backend-verification.json` records 70 passed finite backend assertions, including actual bidirectional WebSocket events through the official SDK, persistence, reconnect reconciliation and negative access checks. Three isolated, real anonymous Auth accounts with no personal data were used in the current 139 project. This proves the server authentication and app-equivalent service path; it does not prove that the uncompiled native interface runs correctly.

The earlier superseded tely deployment exposed two PL/pgSQL naming collisions (`body` versus the message column and `c` versus a table alias). Their fixes and the privacy/ownership hardening were incorporated into the current clean 139 migration, `20261103085904_toli_139_backend.sql`, before the current independent checks. Old migrations and results remain in `supabase/history/tely-20261103/` and `docs/BackendAPI/history/tely-20261103/`; they are not presented as current-project evidence. The old tely project was neither deleted nor paused, and its temporary maintenance endpoint was left closed at version 4.

Cleanup verified zero Auth users, profiles, messages and user-owned media. The 12 editorial recipes, 6 videos, 29 catalog objects and 2 agreement objects remained. The current security advisor returned 17 `Anonymous Access Policies` warnings because the selected product intentionally supports anonymous Auth identities with the authenticated role. Ownership and conversation membership restrictions remain enforced and were verified with those actual anonymous identities. See the [anonymous-access advisor explanation](https://supabase.com/docs/guides/database/database-advisors?queryGroups=lint&lint=0012_auth_allow_anonymous_sign_ins). A notice that named `realtime.messages` did not correspond to an actual policy in `pg_policies`; this application uses Postgres Changes and did not change that platform table. The remaining Auth notice is [disabled leaked-password protection](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection). Production exposes no password login UI, and the current checks used anonymous identities.

Uncompleted or unverified items are explicit:

1. Native compilation and UI execution were subsequently authorized on November 3, 2026. Current native results are tracked in ../runtime-acceptance/; StoreKit products and purchase verification remain unavailable.
2. APNs delivery, RTC, live broadcasting and AI are outside the implemented service set; no remote success is claimed.
3. Recharge products and store credentials are not inferred from any other app. Payment configuration and validation remain governed by the root payment record.

The source and deployed backend are ready for the remaining authorized checks. This record does not mark Stage A complete.

## Repeating deployment checks

The check scripts in `supabase/scripts/` require newly created isolated Auth sessions supplied through private temporary input files. Those files are not included in this repository. The sessions and maintenance nonce used for this run were removed after account cleanup and ingress closure; old bearer tokens must not be reused. The closed `catalog-ingest` function intentionally refuses subsequent uploads. Reopening maintenance requires a new explicit maintenance task and fresh short-lived authorization.

## Owner-managed legacy cleanup

On November 3, 2026, the owner first requested deletion of the superseded tely project, then explicitly chose to delete it manually. Codex stopped the deletion workflow; no project deletion was performed. The old project `lyotjdrnsdoernrcwwfd` is not an application dependency. Its historical migration and verification records remain archived for provenance.

A fresh read-only check confirmed the current 139 project `hdapofqufmxlghmcrftg` is ACTIVE_HEALTHY, with 12 recipes, 6 cooking videos, 29 catalog objects and 2 legal documents. The native configuration points to that same 139 origin. No iOS compilation, typechecking or runtime action was performed during this cleanup request.


## Subsequent authorized native acceptance

The owner subsequently authorized native compilation and runtime acceptance. Twenty distinct UI methods now have passing latest outcomes across focused batches on Tilo, iPhone 17 Pro / iOS 26.0.1. Real one-tap Keychain identity restoration, native text/photo chat, avatar and recipe publication/edit/delete were exercised. Runtime-specific test accounts and retained media/messages supersede the earlier zero-account cleanup count as current state; the historical finite deployment checks remain unchanged. See ../runtime-acceptance/report.md and its structured results. No B integration or StoreKit transaction was added. Product IDs remain empty and production release inputs remain unconfirmed.

## Recipe tutorial metadata update — November 5, 2026

The owner requested real online tutorial videos and a shorter recipe journey. Twelve distinct YouTube sources were verified using the official oEmbed response and attached to the existing twelve editorial recipe payloads under optional tutorial metadata. The guarded update in supabase/recipe-tutorials-update.sql only matched the known editorial IDs with owner_id IS NULL; no member recipe, image, steps, relationship, wallet or agreement was replaced. Readback confirmed 12 editorial recipes, 12 tutorial entries and 12 distinct video IDs. Current catalog JSON and the reproducible generator include the same metadata. No schema, RLS, authentication or Edge Function change was required. Publisher source records live in docs/recipe-tutorials.json and docs/recipe-tutorial-sources.md. Actual in-app playback is verified separately from oEmbed availability.

## Profile conflict feedback — November 5, 2026

The comprehensive native acceptance run reproduced a real HTTP 409 / PostgreSQL 23505 rejection for the existing profiles_username_key constraint. The native client now maps that specific updateProfile conflict to an actionable username-in-use message. Other database constraints are not exposed verbatim. This is client feedback handling only; authentication, schema, RLS, deployed functions and Stage A scope are unchanged. Red/green native evidence and final coverage are tracked in ../runtime-acceptance/full-test-2026-11-05-1816/.


## Repeatable room reactions — November 6, 2026

Migration `20261106021443_separate_repeatable_room_reactions.sql` adds append-only room applause on the existing 139 project. It does not change recipe like/bookmark storage, account identity or the Stage A boundary. The native client supplies a unique event UUID and its current authenticated profile ID, requests the inserted row, and verifies the exact returned UUID after checking the original account generation. No success is published for failed or unconfirmed requests.

RLS grants authenticated clients SELECT of their own rows and INSERT only for themselves and a published cooking video. Anonymous database role, UPDATE and DELETE are not granted. Foreign keys cascade with profile/video deletion, and both referencing fields are indexed. Supabase anonymous Auth members are authenticated identities by design; they are not the unauthenticated database anon role. Repeat applause has no once-per-video uniqueness rule and does not enter content_likes, profile recipe metrics or personal collections. The visible count describes acknowledgements during this room visit only, never an audience/global counter.

Focused UI acceptance update — November 6, 2026: The same simulator is now named Tilo UI Acceptance. Recipes toolbar search, direct compact personal collections and independent room applause have current native evidence in ../runtime-acceptance/personal-room-refinement-2026-11-06/report.md. Historical full-suite results keep their original device name and scope. Product IDs remain empty.

## Purchase catalog configuration — November 6, 2026

Nine owner-authorized consumables now replace the historical empty product mapping in the native client. This does not deploy a receipt verifier, server wallet, external authentication or Socket orders, and does not enter Stage B. Current quantities, exact IDs, test isolation and Apple-side dependencies are recorded in ../payment-configuration.md. Historical empty-ID statements above describe their original runs.


## Published-content safety — November 6, 2026

The dedicated 139 project adds public.toli_safety backed by a tightly checked private implementation. It resolves actual recipe/replay publishers and comment authors, accepts validated reports, blocks the content's actual author and manages per-account hidden recipe/replay rows. The public wrapper is security invoker; private execution validates Auth/profile existence, content visibility, self-action exclusions and reason length. Clients have own-row SELECT only on content_hides; guarded actions own all writes. Existing agreement validation is preserved while discovery uses the shared visibility predicates.

Recipe, video and comment read policies incorporate account blocks and hidden parents. cooking_videos.owner_id is optional, references actual profiles and cascades with account deletion; existing editorial credits do not become member accounts. Room applause inherits video RLS and cannot write against hidden/blocked replays. Unhiding does not require the content to remain visible or present, so stale preferences can still be removed. Raw grants, migrations and finite actual-service results are retained in supabase/migrations and content-safety-verification.json. UI/runtime evidence is tracked separately.


## Editorial publishers and follow-first direct messages — November 6, 2026

The owner explicitly authorized five persistent editorial kitchen identities after a concrete account-creation review. Their public, credential-free inventory is editorial-publishers.json. Trusted setup assigned the existing twelve recipe and six replay IDs only where ownership was null; all four existing ordinary profiles were preserved. Provisioning sessions were revoked and temporary credentials removed. No fake follows, likes, bookmarks, messages, online state, wallet credit or replies were seeded.

Migration 20261106055750_editorial_publishers_and_follow_to_message adds publisher_key and display_baseline to profiles, a private publisher projection, publisher DTOs on catalog JSON and the current one-way direct-message gate. Raw profile counts remain authoritative and separate from the owner's stable small illustrative baselines for these five editorial profiles. Clients have SELECT-only profile grants; ordinary profile updates cannot set the editorial fields. The recipe projection is now STABLE rather than IMMUTABLE because it reads publisher records. Recipe search also resolves publisher name and ingredient queries.

The current owner instruction supersedes the earlier mutual-follow direct-message rule: each sender must follow the recipient. Creation and every direct send check this relationship and existing block rules. Recipients retain authorized incoming history but must follow its sender to reply. Unfollow prevents new sends; block denies affected history/send access and publisher content. Group invitations retain their mutual-follow checks. Consent version, prior safety predicates, Stage A boundary, products, wallets and private member data were preserved.

With a separately authorized finite run, two temporary verification accounts exercised 27 actual-service assertions and were deleted with their test records. Current readback confirms five editorial profiles, four ordinary profiles, twelve owned recipes, six owned replays, zero editorial-outgoing follow rows and no retained verification messages/profile. See publisher-profile-verification.json and ../publisher-profile-design.md. Native results are tracked separately in ../runtime-acceptance/publisher-profiles-2026-11-06/report.md. The initial zero-owner/no-editorial-account statements above remain historical deployment evidence and are superseded for current catalog ownership.
