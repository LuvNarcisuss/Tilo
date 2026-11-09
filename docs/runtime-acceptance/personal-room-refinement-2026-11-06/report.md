# Tilo personal UI and room-reaction acceptance

Date: November 6, 2026. This work continues the owner's authorized native acceptance and direct-fix scope. The owner corrected the app name to Tilo in another task during this run, then clarified the full simulator name as Tilo UI Acceptance. The shortened Tilo name used during an intermediate test batch was temporary. Earlier evidence retains the historical Toli name.

## Delivered behavior

- Recipes uses a generated toolbar search icon beside creation. The default search field is hidden; opening focuses it, submitting dismisses the keyboard, returning from detail retains the query, and closing clears it while retaining the cuisine.
- Me puts Edit profile in Settings, retains a compact wallet action and removes the oversized wallet promotion, repeated category headings, View collection buttons and duplicate relationship actions. Works / Liked / Saved directly show all returned recipes in equal compact columns, with an odd final half-width card. Shared collection routes use the same layout; accessibility categories use one column.
- Room hearts use the existing generated red artwork on the same dark 44-point backing as send/gift/share. They remain repeatable after every tap, with no Unlike state or pale disk. Each gesture inserts a distinct authenticated server event; only a matching receipt advances visit feedback. These events never enter recipe likes/bookmarks or Me collections.
- Initial recipe Like/Save actions remain disabled until the original account's server collection state loads. This fixes a race where a default Like label could change to Liked while the user or test was about to act. More offers a contextual state retry on a failed initial load.
- The same iPhone simulator now has the exact name Tilo UI Acceptance, preserving its device ID and data. XcodeGen app/test targets now explicitly set the iPhone device family, preventing target presets from overriding project defaults.

## Environment and final build

- Simulator: Tilo UI Acceptance, formerly Toli UI Acceptance; iPhone 17 Pro / iOS 26.0.1.
- Device: `26399755-5402-48C1-A2C9-CA26E57505AB`.
- Current project/scheme: `TiloApp/Tilo.xcodeproj`, Tilo.
- Bundle ID remains `com.toli.cooking`; no account, Keychain or private-data reset.
- Final CLI build/install/launch succeeded: `/private/tmp/toli-tilo-iphone-final-20261106-024701-build.log`.
- CLI package: `/private/tmp/TiloAcceptanceDerivedData/Build/Products/Debug-iphonesimulator/Tilo.app`.
- Built display name/executable: Tilo. Built `UIDeviceFamily` is exactly `[1]`. The earlier universal-family result was corrected before this final package.
- CLI source hashes matched at installation. The later Xcode incremental run also compiled the concurrently updated Settings PDF cache policy; final Xcode source hashes match current inputs, and its Settings object is newer than the source. See [final Xcode source snapshot](final-xcode-source.json); see [final package verification](final-package-verification.json) and [source snapshot](final-build-source.json).
- PurchaseProducts.json remains `{}`. No StoreKit purchase was attempted.

## Native runtime evidence

All runs used the same device and ordinary real account entry. No authentication bypass or fake business data was added.

| Batch | Executed methods | Result |
| --- | --- | --- |
| Before naming correction, after collection-state fix | test14RecipeHomeGridAndSingleResult; test18ProfileValidationAndAccountActionCancellation; test24RecipeToolbarSearchAndCompactPersonalCollections | 3 passed, 0 failed, 276.792 seconds |
| Before naming correction, final smoke | test00ConsentFiveRootsAndProfilePersistence; test01ReplayPlaybackControlsAndLinkedRecipe | 2 passed, 0 failed, 162.988 seconds |
| Tilo app and renamed Tilo simulator | test01ReplayPlaybackControlsAndLinkedRecipe; test24RecipeToolbarSearchAndCompactPersonalCollections | 2 passed, 0 failed, 232.730 seconds |

Result bundles:

- `/private/tmp/toli-personal-room-refinement-final-20261106-022423.xcresult`
- `/private/tmp/toli-personal-room-final-smoke-20261106-023119.xcresult`
- `/private/tmp/toli-tilo-renamed-device-20261106-023923.xcresult`

The first diagnostic batch passed replay and recipe preparation/cook mode but exposed the initial Like-label race in the new collection test. That failure is preserved in `/private/tmp/toli-personal-room-refinement-20261106-021706.xcresult`; it is superseded by the passing fixed-state runs above. Temporary likes/saves introduced by the grid test were restored.

The renamed-device suite verifies six independently acknowledged room taps, continuing playback, gift-sheet playback, foreground recovery, linked recipe navigation, hidden/default toolbar search, empty-result clearing, equal-width personal columns, detail navigation, wallet access and Settings editing. Five-root entry and actual profile save/reopen passed before the naming-only correction. The final package additionally incorporates the device-family metadata correction and the concurrently updated current agreement configuration; these build/config changes are not presented as a new complete UI suite or legal acceptance audit.

Screenshots: [Recipes toolbar](recipes-toolbar.png), [Liked columns](profile-liked-columns.png), [Saved columns](profile-saved-columns.png), [Settings editor](settings-profile-editor.png), [consistent room hearts](repeatable-room-hearts.png). Native frame assertions verify two equal columns even where the captured scroll position shows only the upper card portions.

## Backend and skill evidence

The existing 139 project received migration `20261106021443_separate_repeatable_room_reactions.sql`. It adds own-row SELECT/INSERT RLS, published-video validation, indexed foreign keys and no client UPDATE/DELETE grants. Existing recipe favorites remain untouched. Fifteen finite real-service checks passed, including repeat events, receipts, duplicate UUID rejection, sender forgery/read isolation, unavailable-room rejection, unauthenticated rejection and unchanged liked recipes. Both disposable backend verification accounts were deleted through the actual endpoint. See [backend checks](../../BackendAPI/room-reactions-verification.json).

The security advisor output is preserved in [advisor evidence](../../BackendAPI/room-reactions-security-advisor.json). Its [anonymous Auth access notice](https://supabase.com/docs/guides/database/database-advisors?queryGroups=lint&lint=0012_auth_allow_anonymous_sign_ins) reflects this app's intentional authenticated guest accounts and own-row RLS. It also reports [password protection disabled](https://supabase.com/docs/guides/auth/password-security#password-strength-and-leaked-password-protection); this task did not alter Auth settings or add password login.

Final static inspection: 322 checks, no failures after final Xcode generation and the concurrent legal-resource update. Installed ios-app-bulid SKILL.md now routes to `references/tilo-ui-refinement-case.md`, covering all confirmed login, navigation, media, room, recipe, personal-page, service-truth and acceptance decisions. The official skill validator passed with a temporary PyYAML dependency, and the linked reference exists.

No local StoreKit, Apple sandbox or production payment validation was performed. This focused pass does not repeat the prior full chat suite, maximum Dynamic Type suite or all backend deployment checks.

## Final Xcode state

The final native Xcode accessibility state explicitly showed scheme Tilo, run destination Tilo UI Acceptance and `Running Tilo on Tilo UI Acceptance`. The app remains running on the original device. The temporary shortened simulator name has been superseded in the runner, project rules and installed skill. Renaming the same device did not require resetting its data or repeating unchanged UI cases.
