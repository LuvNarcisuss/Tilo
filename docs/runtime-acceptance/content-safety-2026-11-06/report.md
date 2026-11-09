# Tilo published-content safety acceptance

Date: November 6, 2026. Scope: content reporting, real-author reporting/blocking, editorial hide/restore and propagation to discovery, collections, comments and chat authorization.

## Delivered behavior

- Member-owned recipes and replays expose Report content, Report cook and Block cook in More. The menu identifies the actual publisher separately from the credited filmmaker. Ownership comes from the server; a nickname or source credit is never treated as an account ID.
- Recipe comments have a generated More action. Room messages expose report/comment-author/block actions through touch-and-hold and an accessibility action. The room retains its single compact bottom toolbar and continuous playback. Own content does not offer self-report/block actions.
- Editorial recipes and replays expose Report and Hide. They have no invented member profile. Settings / Hidden content restores hidden records; Settings / Blocked cooks manages actual account blocks.
- Server acknowledgements precede success UI. Blocks remove follows, filter the publisher's content/comments and reconcile affected chat access. Unrelated conversations are not permanently declared revoked. Existing likes/saves survive an unblock.
- Hidden/blocked content is excluded from protected direct reads as well as discovery. Hidden or blocked replays cannot receive room applause. Missing, unauthorized and self-action targets are rejected.

## Implementation and deployment

Existing 139 project: `hdapofqufmxlghmcrftg`. No project, provider, external authentication, Socket or payment pipeline was created.

- `20261106031821_content_safety_reports_blocks_and_hides.sql`: optional real video ownership; own-row hidden preferences; protected safety RPC; shared visibility and RLS changes. The discovery patch preserves the current agreement version and unrelated business actions.
- `20261106032739_correct_content_unhide_predicate.sql`: corrects the qualified local-variable predicate found by the first finite unhide check. The original failure and correction were not counted as passing checks.
- Shared native actions live in ContentSafety.swift. The backend resolves content ownership and records actual reports rather than returning a local success fallback.
- The acceptance runner now refuses to install/launch while another xcodebuild test is using the same simulator.

## Finite real-service evidence

[38 checks passed](../../BackendAPI/content-safety-verification.json): actual profile bootstrap, owned photo upload/recipe publication, recipe/replay/comment/profile report persistence, ownership resolution, self-action rejection, missing-target and unauthenticated rejection, direct-write isolation, account-scoped hide/restore, direct RLS filtering, replay-reaction denial, publisher-block propagation, follow removal, chat access revocation and preservation of prior favorites/saves after unblock.

The member-replay fixture reused licensed catalog footage with its original filmmaker credit and a real disposable publisher. Its ownership row used trusted, bounded test setup because in-app broadcasting/replay publishing remains unavailable. This verifies safety for an owned replay; it does not claim a new publishing or broadcasting service.

All disposable service-verification accounts were deleted through the actual account-deletion endpoint. The native fixture publisher was also deleted after UI verification. Readback confirmed its profile, recipe, replay, comments and block references were absent; the catalog returned to 12 recipes and 6 replays. The persistent isolated native acceptance account and its actual report audit records remain available. Private fixture credentials were removed from the temporary directory.

Security-advisor output is retained in [advisor evidence](../../BackendAPI/content-safety-advisor.json). The [anonymous Auth access notices](https://supabase.com/docs/guides/database/database-advisors?queryGroups=lint&lint=0012_auth_allow_anonymous_sign_ins) reflect the app's deliberate authenticated guest accounts, with own-row/visibility checks. The project also reports [password protection disabled](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection); this task did not change Auth settings or add password login.

## Native runtime evidence

Device: **Tilo UI Acceptance**, iPhone 17 Pro / iOS 26.0.1, `26399755-5402-48C1-A2C9-CA26E57505AB`. Project/scheme: Tilo. Bundle ID: `com.toli.cooking`. Latest source was compiled, installed and launched on this device for the focused batches.

| Method | Latest passing evidence | Duration |
| --- | --- | --- |
| test40PublishedRecipeReportAndBlockAuthor | content-safety-serial | 178.519 s |
| test42PublishedReplayReportAndBlockAuthor | content-safety-serial | 120.082 s |
| test43EditorialContentHideAndRestore | content-safety-confirmed | 114.688 s |
| test41RecipeCommentAndRoomMessageSafety | content-safety-final | 127.938 s |
| test44PublisherAttributionInSafetyMenus | content-safety-final | 86.813 s |

Result bundles:

- `/private/tmp/toli-content-safety-serial-20261106-035226.xcresult`
- `/private/tmp/toli-content-safety-confirmed-20261106-040616.xcresult`
- `/private/tmp/toli-content-safety-final-20261106-041256.xcresult`

These are the latest outcomes of five focused methods across batches, not one complete-suite pass. The final two-method batch passed with zero failures in 214.751 seconds. Earlier member report/block passes preceded only the publisher-caption refinement, which the final attribution method verifies explicitly.

The first combined run was interrupted when another purchase UI task used the same device and relaunched the app. Only this task's runner was stopped. Its raw log remains at `/private/tmp/toli-content-safety-ui-20261106-033213-test.log`; its unfinished result bundle is not passing evidence. Testing resumed after that task released the device.

Two later harness issues were diagnosed from native snapshots: interactive message labels are exposed as Buttons rather than StaticTexts, and immediate taps could precede the native confirmation's readiness. Tests now use stable message identifiers independent of role, wait for the exact confirmation and verify its dismissal before checking server effects. The failing artifacts remain in the earlier bundles; successful report/block/hide assertions were retained.

Screenshots inspected: [recipe publisher safety](recipe-safety-menu.png), [replay publisher safety](replay-safety-menu.png), [comment menu](recipe-comment-safety.png), [room long-press menu](room-message-safety.png), [hidden content restoration](hidden-content-restored.png), [blocked recipe discovery](blocked-recipe-discovery.png).

Final static inspection: **350 checks, no failures**. The compiled app's UIDeviceFamily is `[1]`. [Source hashes](source-snapshot.json) match the final current workspace; [verification metadata](verification.json) records package identity and cleanup.

## Boundaries

The installed ios-app-bulid reference includes the published-content safety decisions and actual simulator-concurrency caution. An unrelated attempt to synchronize historical purchase notes was rejected by automatic approval review for lacking direct authorization in this task and was abandoned. No product ID, price, purchase scheme or wallet delivery code was changed by this safety work; the parallel purchase task's changes were preserved.

No new purchase, maximum-Dynamic-Type, full chat or complete application regression suite was executed by this safety pass. Existing editorial media/license records and delivered legal PDFs were not changed.

Final Xcode confirmation: the active project was TiloApp/Tilo.xcodeproj, scheme Tilo, destination Tilo UI Acceptance; its observed activity was `Running Tilo on Tilo UI Acceptance`. The latest app remains running. Source hashes still match. The deleted publisher's Storage namespace also contained zero remaining objects.
