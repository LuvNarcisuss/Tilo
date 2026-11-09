# Publisher profiles acceptance — November 6, 2026

## Delivered behavior

Live and recipe covers have independent publisher portrait targets. The portrait opens the same stable publisher profile; the cover keeps opening its room or recipe. Profiles show compact identity, four metrics, Follow/Message/Block/Report and direct Recipes/Rooms works. The report action survives asynchronous loading. Editing stays in Settings on the personal route.

The sender must follow the recipient before starting or sending a direct message. A reciprocal follow is unnecessary; each recipient follows the sender before replying. Native profile/contact/composer state and server create/send authorization agree. Unfollow prevents future sends; block removes affected content and private conversation access. Groups retain mutual-friend invitations.

The owner explicitly authorized five persistent editorial kitchen accounts and separately authorized two disposable verification accounts and two labeled verification messages. Twelve existing recipes and six replays were assigned to the five editorial accounts without changing content IDs, source media, original filmmaker credits or the four existing ordinary profiles. Illustrative portraits and editorial collections are labeled. Display baselines from 12 through 26 persist separately from actual counts and follow rows; ordinary member metrics and wallet credit are not seeded. Provisioning sessions were revoked and their temporary credential files removed. The two disposable accounts and their verification records were deleted.

## Environment and source

- Workspace: /Users/apple/Desktop/Tilo.
- Scheme/target: Tilo; bundle: com.toli.cooking; Debug, iPhone only.
- Simulator: **Tilo UI Acceptance**, iPhone 17 Pro, iOS 26.0.1; device 26399755-5402-48C1-A2C9-CA26E57505AB.
- Backend: dedicated 139 project hdapofqufmxlghmcrftg, Stage A.
- Every batch used the runner's current-workspace build, install and launch path. Final source matches the green/navigation source snapshots retained beside this record. No authentication bypass or account reset was added.

## Finite backend checks

All **27** assertions passed in ../../BackendAPI/publisher-profile-verification.json. They cover all 18 publisher projections, card/profile identity, stable bounded baselines, zero fabricated follow rows, ordinary-member zero statistics, protection of editorial fields, negative before-follow creation, one-way create/send, actual incoming history, reply gate, idempotent retry, unchanged group rules, unfollow denial, independent actual follower increments, publisher block filtering, blocked private access, restoration and publisher search.

Independent readback confirmed five editorial profiles, four ordinary profiles, twelve owned recipes, six owned replays, zero outgoing editorial follow rows, zero editorial provisioning sessions and no retained verification profile/messages. Profile table clients retain SELECT-only grants. Consent version 2026-11-06-99d6afcc3037 and group mutual-follow validation remain present. Security advisors returned zero errors and the same anonymous-Auth-policy/password-provider warning classes; current summary is ../../BackendAPI/publisher-profile-advisors.json. Permission guidance was checked against the official [Supabase column privileges documentation](https://supabase.com/docs/guides/database/postgres/column-level-security); the official changelog index was also reviewed. No TLS or security setting was weakened.

## Native results

The following focused methods have passing outcomes across the recorded batches. This is not a fresh full-suite or payment acceptance claim.

| Method | Passing source batch | Verified behavior |
| --- | --- | --- |
| test01ReplayPlaybackControlsAndLinkedRecipe | final / 062052 | Actual playback progress, repeat applause, gift sheet, foreground/retry and linked recipe |
| test24RecipeToolbarSearchAndCompactPersonalCollections | final / 062052 | Toolbar search open/close/query/category return and personal grids |
| test43EditorialContentHideAndRestore | green / 064439 | Latest UIView card entry, real hide and Settings restoration for recipe/replay |
| test45PublisherAvatarsOpenProfilesIndependently | navigation-confirmation / 065354 | Latest independent Live/recipe avatar routes, same profile, report form, block confirmation cancel and separate cover entry |
| test46PublisherProfileAccessibilityLayout | green / 064439 | Latest large-text identity, metrics and usable actions |
| test47PublisherFollowEnablesMessageAfterAcknowledgement | green / 064439 | Latest saved follow enables Message, actual follower delta, unfollow disables and original state survives reload |

The green and navigation-confirmation builds contain the final Swift source; their recorded file hashes match current source. The earlier replay/search regression build preceded the final profile text/concurrent-read refinements and UIView card container correction. The final hide and avatar methods re-exercised current card search/entry and profile behavior. No further broad suite was presented as passing.

Actual result bundles remain at:

- /private/tmp/toli-publisher-profile-ui-20261106-061447.xcresult
- /private/tmp/toli-publisher-profile-final-20261106-062052.xcresult
- /private/tmp/toli-publisher-profile-green-20261106-064439.xcresult
- /private/tmp/toli-publisher-profile-navigation-confirmation-20261106-065354.xcresult

Initial testing reproduced a missing Report button: SocialPage.perform restored a stale navigation item over the newly rendered action. It now restores only its own still-active spinner. A later search/card check exposed an accessibility activation failure with the composed UIControl container despite a visible valid frame. The container is now UIView with separate cover/avatar buttons, and the affected latest-source hide/entry check passed.

Two batch attempts also failed at ordinary login with the real native alert: “A TLS error caused the secure connection to fail.” Recorded OS errors include NSURLErrorDomain -1200 and stream -9816. Later ordinary login attempts passed without changing certificates, authentication or network settings. These intermittent transport failures remain an environment/service limitation; the mixed batches remain failed in the evidence, rather than being relabeled successful. Final targeted navigation executed one method with zero failures and exit 0.

Selected actual screenshots and initial/failure hierarchies are retained under screenshots/. They show stable statistics, Follow versus Following/Message state, distinct card targets, safety access and accessibility layout. Test follow state was restored, and hide preferences were restored through the ordinary app UI. No new private conversation or message was added by the profile UI methods.

## Static checks, skill and final launch

363 project static checks passed. The installed ios-app-bulid skill passes quick_validate.py. Its entrypoint now requires complete social product flows from the first build, including publisher profiles, full-stack relationship policy, safety, complete StoreKit wallet states and toolbar search. See /Users/apple/.codex/skills/ios-app-bulid/references/social-product-defaults.md. Bibi was inspected read-only; no Bibi source or identity was changed.

The final Xcode Run used the current Tilo project, scheme Tilo and destination Tilo UI Acceptance. The observed Xcode activity was **Running Tilo on Tilo UI Acceptance**. Tilo's existing Run configuration retains TiloDiamonds.storekit and TILO_STOREKIT_MODE=local. The latest app remains running from Xcode. No product ID, signing identity, existing wallet ledger, legal document or Stage B configuration was changed. StoreKit, Apple sandbox and production purchases were not retested in this profile task. Editorial inboxes have real server storage and no automated reply or promised human availability.
