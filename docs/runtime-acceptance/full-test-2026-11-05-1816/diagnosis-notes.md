# Acceptance diagnosis notes

## Native profile failure

The first batch executed 15 UI cases: 14 passed, one failed. The failed profile case attempted the globally fixed historical username toli_acceptance_cook. Its screenshot shows Home Cook / cook_d3ebe3e1149d489c9443 before editing and the save-error alert afterward. The public directory independently shows that toli_acceptance_cook is owned by historical account a2756376-964b-48d0-8863-295daaba6473. The currently used account is d3ebe3e1-149d-489c-9443-f5999e648b74, corroborated by its newly uploaded avatar and account-scoped draft directory. A fresh real RPC probe independently returned HTTP 409 / PostgreSQL 23505 for profiles_username_key; see username-conflict-response.json. No backend or app authentication bypass is introduced. The profile case now derives a stable distinct acceptance handle from a new guest handle and asserts a fresh unique biography after reopening. The actual rerun determines its outcome.

The historical account is preserved. Both real partner sessions now follow the current native account. A preparation-only secondary follow to the historical account was explicitly restored to its original unfollowed state. The first independent avatar read addressed the historical account and does not prove the new upload; a subsequent read of the current account verifies its actual JPEG bytes.

## Backend test expectation

The initial finite-backend probe required an error when another account tried to update a grocery. The current guarded RPC implements an owner-filtered no-op, leaving the protected row unchanged. The test was corrected to inspect the owning account's actual row and the other account's empty list, rather than requiring a particular error shape. The corrected independent run passed 69 checks. All three accounts from each run were deleted, and stale business access was rejected. The diagnostic result remains alongside the final result.

## UI test compilation

An added Live test used count on XCUIElement instead of XCUIElementQuery. Compilation exposed the mistake, which was corrected to buttons.matching(identifier:).count. No product implementation was changed for this issue. The next current-source build verifies the correction.

## Concurrent owner workflow

After the core batch ended, the existing owner workflow in the existing Toli implementation chat began testing new Live room covers on the same designated device. This run yields simulator control until that workflow finishes, then rebuilds current source and adds the new room-cover cases to its coverage. Earlier screenshots are evidence for their exact source snapshot, not proof of the later Live layout.

## Evidence limits

Two finite recipe observers captured no relevant publication/absence: the first targeted the historical native identity, and the later observation began too late. Neither is counted as independent publication proof. The native publication/edit/delete case itself passed. A correctly scoped observer may be rerun with a longer bounded duration.

The actual duplicate-username response also exposed a product feedback defect: the native client replaces this actionable conflict with a generic connection message. A focused native regression case was added before modifying production handling. Its red/green runs remain pending simulator availability.

The shared simulator workflow completed at 19:11 Asia/Shanghai. No xcodebuild/XCTest/acceptance runner remained, and simctl read back the restored large text category before this run resumed. Its two passing Live room-cover cases and seven screenshots were imported and independently reviewed. No cross-chat message was sent.

## Username feedback red/green

/private/tmp/toli-full-audit-username-red-20261105-111203.xcresult executed the occupied-username case and failed the actionable-feedback assertion in 42.579 seconds. Production handling then added a narrow updateProfile / 23505 / profiles_username_key mapping. In the subsequent current-source expanded batch, test21TakenUsernameHasActionableFeedback passed in 55.651 seconds, including the error text and original profile retention. test00ConsentFiveRootsAndProfilePersistence also passed in 86.388 seconds with the account-derived handle and fresh biography. The independent partner read in native-profile.json matches the current native account and saved biography.

## Native creation-menu selector

The expanded batch completed 8 cases with 7 passes and one test17 failure at its final Cancel selector. All six actual replay playback activities completed first. The retained failure hierarchy shows an adapted Popover/Sheet titled From your kitchen, with an observed PopoverDismissRegion / dismiss popup element and Write a recipe button; no Cancel button exists. The harness now dismisses the actual native region when Cancel is absent, asserts the menu disappears, then exercises the ordinary Live-to-recipe-editor route and returns. Product presentation code was not changed. The focused replay/social rerun determines the final outcome.

## Maximum-text visual defects

Visual review found character-level wrapping in the recipe social footer and profile Following/Followers labels despite earlier navigation assertions passing. The strengthened recipe case failed with a social-action width of 118 points against a full-width threshold of 301.5. The new profile metric case failed with an 87.67-point relationship button against a 120.6-point minimum. The red bundle is /private/tmp/toli-full-audit-word-layout-red-20261105-115526.xcresult. Production now gives recipe social actions full-width vertical placement and profile metrics two columns at accessibility categories, with trait-change updates. Standard text retains the existing horizontal compositions. The green and default-text regressions determine the final acceptance.

## Final outcome

All 32 distinct native methods have final passing outcomes. Twelve batches contain 46 executions (41 passed and five retained diagnostic failures). The final three-case standard functional batch and three-case maximum-text typography batch match the final application inputs. The installed executable hash equals the final built executable. The original large text category and unchanged nightly automation hash are recorded in final-state.json. The app remains running on the mandatory simulator. No further production changes followed the final build. Coverage and limits are consolidated in report.md.
