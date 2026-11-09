# Toli Supabase Integration

Status: Stage A services and source implemented and deployed. A is not complete: anonymous sign-in is disabled on the project, and the user has not authorized an iOS build or runtime verification.

## Project and scope

- Project: `Toli-20261103`, reference `lyotjdrnsdoernrcwwfd`.
- Organization: `nccttwrxfnmntlyavtpt`, the user-selected tely account.
- Region: Singapore (`ap-southeast-1`). Creation quote: USD 0 per month. This is the quote returned for creation, not a promise about future usage charges.
- API origin: `https://lyotjdrnsdoernrcwwfd.supabase.co`.
- Application source: `ToliApp/Toli/Backend`. Migration and Edge source: `supabase/`.
- Production Swift dependency: official `supabase-swift`, exactly `2.55.6`, product `Supabase`. Static signatures were checked against that tagged source; no Swift compiler was run.
- Finite deployment-check dependency: official `@supabase/supabase-js`, exactly `2.80.0`, outside the iOS target, with its lockfile in `supabase/`.
- Selected workflow: `ios-swift-supabase-one-tap`, Stage A. No external B authentication, custom Socket, external web routing, remote purchase processing or AI service was added.

## One-tap account entry

The native welcome screen uses one login action after adulthood and agreement confirmation. The service restores and refreshes the existing Supabase identity from Keychain; only an absent identity creates a new anonymous account. A failed restoration does not create a replacement account. Auth access and refresh tokens use a custom `AuthLocalStorage` backed by Keychain with device-only accessibility.

The authenticated `bootstrap` Edge Function validates the user through Auth and invokes the guarded database bootstrap. Its Stage A response is `{ "code": 0, "message": "ok", "data": {} }`. The app then records adulthood and the exact content-derived agreement version `2026-11-03-ecd0a3abea14` before loading the profile. No external destination is encoded in this empty configuration.

A real `/auth/v1/signup` request returned HTTP 422, `anonymous_provider_disabled`. Consequently, the one-tap path cannot succeed until an authorized tely project administrator enables anonymous sign-ins. The connected database tools do not expose Auth configuration; the available Chrome session belongs to a different organization and cannot access this project. No password was requested, no login was fabricated, and no other project's identity or backend was reused.

## Data and actions

`public.toli_action(action, body)` is a security-invoker RPC wrapper. Its implementation lives in a non-exposed private schema, verifies `auth.uid()` against an existing Auth account, and applies explicit ownership, membership and visibility checks. Public tables have RLS; ordinary clients have read grants only, with writes routed through guarded business operations. Service keys remain in the Edge environment.

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
| Direct chat | Mutual follows checked at creation and every send; private member access | Real persistence, bidirectional realtime, idempotency and revoked-follow rejection checked |
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

All 29 processed media objects from `Assets/PublishedMedia` and the two legal PDFs were uploaded to this project and then fetched without credentials. All 31 objects matched the expected SHA-256, length and MIME type: 12,082,772 bytes in total. See `media-upload-manifest.json` and the root media provenance records. These are actual inspected bytes, not silently substituted upstream originals. Public catalog objects use `toli-catalog`; agreements use `legal`; avatars and published recipe photos have separate owner-scoped upload policies; chat images remain private.

The temporary fixed-manifest import accepted only allowlisted object keys with exact byte counts and hashes and an expiring, temporary authorization. It was replaced by `catalog-ingest` version 2 returning HTTP 410; a real request confirmed closure. No maintenance token or service key is included in the app or repository.

## Legal documents

- Terms: https://lyotjdrnsdoernrcwwfd.supabase.co/storage/v1/object/public/legal/2026-11-03/terms.pdf
- Privacy: https://lyotjdrnsdoernrcwwfd.supabase.co/storage/v1/object/public/legal/2026-11-03/privacy.pdf

Both English, searchable, single-page PDFs were rendered and visually inspected, parsed, and anonymously downloaded with matching MIME and hashes. `legal/manifest.json` records sources, hashes, version and object paths. `support@toli.com` is proposed; activation is not confirmed. These are project documents, not a claim of legal review. After A delivery, only an explicit user request authorizes changing their content, sources, public objects, versions or links.

## Verification and remaining dependencies

`backend-verification.json` records 70 passed finite backend assertions, including actual bidirectional WebSocket events through the official SDK, persistence, reconnect reconciliation and negative access checks. Three isolated Auth accounts with no personal data were used because anonymous sign-ins are disabled; these backend results do not prove that the native anonymous login works.

The actual checks found two PL/pgSQL naming collisions (`body` versus the message column and `c` versus a table alias); the deployed follow-up migrations correct their exact causes. Historical migrations are retained in remote deployment order, with local filenames matching the platform-assigned versions. The final migration is `20261103083508_toli_conversation_query_scope.sql`.

Cleanup verified zero Auth users, profiles, messages and user-owned media. The 12 editorial recipes, 6 videos, 29 catalog objects and 2 agreement objects remained. The security advisor reported no schema/RLS findings; it reported disabled leaked-password protection in Auth. Production exposes no password login UI, and disposable password-based verification accounts were deleted.

Uncompleted or unverified items are explicit:

1. Enable anonymous sign-ins in the authorized tely project and verify the real one-tap path.
2. No iOS compilation, typechecking, launch, simulator, Preview, UI or StoreKit runtime check was authorized or executed. Native integration is statically inspected only.
3. APNs delivery, RTC, live broadcasting and AI are outside the implemented service set; no remote success is claimed.
4. Recharge products and store credentials are not inferred from any other app. Payment configuration and validation remain governed by the root payment record.

The source and deployed backend are ready for the remaining authorized checks. This record does not mark Stage A complete.
