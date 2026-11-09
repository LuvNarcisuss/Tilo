# Profile presentation acceptance — November 6, 2026

## Current behavior

- Before following, Message is absent from the view and accessibility tree. Follow fills the primary action area beside Block.
- An acknowledged follow changes the label to Following, shortens the action at standard text sizes and reveals Message alongside it. Unfollow hides Message and restores the expanded Follow width. Accessibility sizes use stacked primary actions.
- Publisher works show only that user's published recipes, directly in a compact grid. There is no Rooms category, room player or video-list request in CreatorController.
- Publisher portraits remain on Live/Recipes home covers. Profile works, personal collections and recipe-selection grids omit repeated publisher portraits. The profile's identity portrait remains present.
- Block and Report remain available. Existing server follow checks, account data, wallet, legal configuration and media ownership are preserved.

This supersedes the earlier visible-disabled Message and Recipes/Rooms presentation in ../publisher-profiles-2026-11-06/report.md. That report remains historical evidence.

## Actual verification

Latest source built, installed and launched on **Tilo UI Acceptance**, iPhone 17 Pro / iOS 26.0.1, device 26399755-5402-48C1-A2C9-CA26E57505AB. Scheme/target Tilo; bundle com.toli.cooking. The retained source.json hashes match the tested current Swift/configuration files.

Three focused UI methods passed with zero failures, exit 0:

| Method | Coverage |
| --- | --- |
| test45PublisherAvatarsOpenProfilesIndependently | Home avatars retain separate entry; profile has only its owner's recipes, no room cards/category or repeated publisher avatar; Report and Block access remain; cover still opens recipe |
| test46PublisherProfileAccessibilityLayout | Large-text profile and actions remain reachable; Message presence matches following; no Rooms or repeated work-card avatars |
| test47PublisherFollowEnablesMessageAfterAcknowledgement | Real saved follow reveals Message and shrinks Following, actual follower increment, unfollow removes Message/restores width, original relationship/count survive profile reload |

Result bundle: /private/tmp/toli-profile-follow-visibility-20261106-071443.xcresult. Build/test logs and source snapshot use the same prefix. Actual screenshots under screenshots/ were exported from this result; expanded Follow, shortened Following/Message and avatar-free recipe works were visually inspected. The QA relationship was restored through the normal server-backed UI. No message, new account or wallet credit was created in this task.

363 static checks passed. The updated installed ios-app-bulid references pass quick_validate.py. Current project rules, product/profile design and skill guidance now describe these same presentation rules. No backend migration or payment test was performed for this presentation-only change.

Final Xcode activity was observed as **Running Tilo on Tilo UI Acceptance** after Run on the latest project. Scheme Tilo retains its existing local StoreKit fixture and environment; the app remains running from Xcode.
