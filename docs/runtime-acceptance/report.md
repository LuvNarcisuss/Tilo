# Toli native acceptance

Date: November 3, 2026. Workspace: `/Users/apple/Desktop/Tilo`.

## Outcome

The latest executed outcome of all **20 distinct UI acceptance cases is Passed**. Cases ran in focused batches, not one uninterrupted full-suite run. All earlier failures remain in the result history; they are not counted as passing executions. The final current-source build, installation, launch and five-root regression passed with **1 executed case / 0 failures**. Maximum Dynamic Type entry/navigation verification passed with **2 executed cases / 0 failures**, then the original `large` text size was restored and the default-size five-root regression was repeated.

The exact case and run records are in [results/index.json](results/index.json). The collector validates nonzero executed counts and the named device. Later runs retain SHA-256 source snapshots. Static inspection separately passed **279 checks / 0 failures** in `../static-verification.json`.

## Environment

- Xcode 26.0.1 (17A400), iOS Simulator 26.0.1 (23A8464).
- Simulator: **Toli UI Acceptance**, iPhone 17 Pro, `26399755-5402-48C1-A2C9-CA26E57505AB`.
- App/target/scheme: Toli; Bundle ID: `com.toli.cooking`; simulator ad hoc signing.
- Latest workspace source was built, installed and launched before every test batch. No Toti/Bibi simulator or old package substituted for this device.
- The app was launched in the named simulator after the final test session. Cold launch intentionally presents unchecked agreements and the ordinary one-tap entry.

## Verified behavior

- **Live:** real remote AVPlayer footage and advancing player time, stable paused time, sound controls, background pause, retry, comments, native sharing, linked recipe and explicit exits. Screenshots showed actual cooking imagery. Playback time is driven by AVPlayer, not a synthetic timer.
- **Recipes:** real search and empty results, portion scaling, saved/liked collections, all cook-along steps, real discussion writes, native food photo selection, publication, editing, deletion and server-search absence afterward.
- **Kitchen:** timer progression/pause/reset, planned meal selection, ingredients added to the server shopping list, a custom grocery item, checked state and reloaded persistence.
- **Chats:** real member search and follows, mutual direct messaging, actual incoming partner reply while open, exact draft restoration/clearing, pin/mute persistence, foreground retention, native photo upload/private rendering/reopened history, three-member group creation/text/removal/re-invitation, owner exit restrictions and acknowledged group exit.
- **Me:** profile text and avatar save/readback, collections, wallet disabled state, settings, actual PDF rendering, report acknowledgement, block-list readback and unblock.
- Five independent roots and dock remained accessible at default and maximum text sizes. Maximum-size content wraps and scrolls; this does not constitute a full VoiceOver audit.

![Final five-page screenshots](screenshots/five-pages.jpg)

## Corrections made

Native compilation exposed helper/member-name collisions and escaping-closure capture errors. Runtime work corrected the welcome action being below the initial viewport, keyboard viewport constraints, a stretched Live illustration, oversized introduction and initial Kitchen loading state, modal navigation/close actions, replay control accessibility and retry state, unnecessary inbox rebuilding that dismissed menus, and normal-send acknowledgement races caused by shared conversation refresh state. Inbox previews are bounded to two lines. Recipe editing now shows its current photo; draft status uses the bundled custom font instead of a system navigation prompt.

Chat initial failures expose a manual authorized retry. Pending sends persist their stable client ID and photo data/path before transmission, and acknowledgement cleanup uses the request's own authoritative conversation result. Normal text/photo send and reopening were exercised. Disconnection and acknowledgement-loss failure injection remain outside the executed coverage.

Test helpers were also corrected separately from product bugs: keyboard suggestion strips are excluded from page scrolling; short drags prevent overshooting fields; native text selection is checked before replacement; duplicate background buttons are excluded; Photos virtual image bounds are read from the current exact imported asset rather than reusing screen coordinates. Tests use ordinary production entry and the real 139 backend, without login bypasses or fabricated business responses.

## Independent service evidence

[chat-service-evidence.json](chat-service-evidence.json) contains 25 isolated authenticated service records: exact native/partner message IDs, an actual WebSocket-triggered partner RPC reply, real group membership and later access denial, avatar bytes and private chat-image download MIME/length/SHA-256. Signed URLs and tokens are not retained in evidence. The partner independently observed the published recipe and owner/photo relationship, then its absence from both search and the author's works. It did not observe the intermediate revised projection; native edit/save/readback is proven by its UI case and screenshots, not mislabeled as partner evidence.

Main test identity: `Toli Acceptance Cook` / `toli_acceptance_cook`. The two isolated partners, main guest, avatar and direct chat records are retained for inspection. The isolated group was exited; the published acceptance recipe was deleted. Only project-owned cooking media was added to this simulator. No personal Photos originals or tely project were deleted.

## Explicit limits

- `PurchaseProducts.json` remains `{}`. Wallet zero-balance/unavailable-recharge UI was tested. No local StoreKit transaction, native payment sheet, Apple sandbox or production purchase was run; no credit or product availability is invented.
- Production Bundle ID registration, team/signing and owner-confirmed products remain external release inputs.
- Only this named iPhone 17 Pro / iOS 26.0.1 simulator was exercised. Physical devices, other OS versions, smaller devices, full VoiceOver, sustained performance/leak profiling, offline transport/reconnect and lost-response fault injection were not validated.
- Supabase Swift 2.55.6 emits its documented legacy initial-session advisory in test results. The native entry performs explicit session/bootstrap/server checks; an expired-token fault-injection audit was not performed. The build also reports skipped App Intents metadata extraction because this app has no App Intents dependency. Neither is reported as a clean-warning build.
- Replays are recorded films. Broadcasting, RTC, APNs and cross-device/server wallet authority are not represented as working services.

## Case outcomes

| Executed case | Latest result |
| --- | --- |
| test00ConsentFiveRootsAndProfilePersistence | Passed |
| test01ReplayPlaybackControlsAndLinkedRecipe | Passed |
| test02RecipesSearchScaleCollectionsAndCookSteps | Passed |
| test03KitchenMealGroceriesAndTimer | Passed |
| test04ChatsDirectoryWalletAndAgreements | Passed |
| test05ProfilePhotoPickerInspection | Passed |
| test06RealReplayAndRecipeComments | Passed |
| test07NativeReplayShareInspection | Passed |
| test08WelcomePrimaryActionVisible | Passed |
| test09AllRootsLayout | Passed |
| test10RealProfilePhotoUpload | Passed |
| test11RealChatPhotoUploadAndRender | Passed |
| test12RealRecipePhotoPublishEditAndDelete | Passed |
| test29FollowRealAcceptancePartner | Passed |
| test30RealChatSendDraftAndPreferences | Passed |
| test31RealChatReceiveWhileOpen | Passed |
| test32RealGroupCreationAndMemberManagement | Passed |
| test33RealGroupLeave | Passed |
| test34ChatBackgroundForegroundRetention | Passed |
| test35ReportBlockAndUnblockIsolatedPartner | Passed |

## Reproduction and artifacts

Use `scripts/run_acceptance.py` with exact methods from `ToliAcceptanceTests.swift`; real partner choreography is in [test-matrix.md](test-matrix.md). Do not run all fixture-dependent cases against unrelated accounts. `scripts/collect_acceptance.py` reads completed `.xcresult` bundles and retains diagnostic history. Original result-bundle and build-log paths are recorded in the JSON files under `results/` and remain in `/private/tmp`.

Selected actual screenshots: [chat photo](screenshots/chat-photo.png), [profile photo](screenshots/profile-photo.png), [published recipe](screenshots/published-recipe.png), [edited recipe](screenshots/edited-recipe.png), [deleted recipe](screenshots/deleted-recipe.png), [wallet and PDFs](screenshots/wallet-and-agreements.jpg), [maximum text](screenshots/maximum-text-me.png).
