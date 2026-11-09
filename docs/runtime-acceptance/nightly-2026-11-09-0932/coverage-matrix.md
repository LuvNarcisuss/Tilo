# Tilo nightly scenario coverage

November 9, 2026, Asia/Shanghai.

| Method | Expected behavior | Actual outcome |
| --- | --- | --- |
| test00ConsentFiveRootsAndProfilePersistence | Consent gate, five destinations, valid profile save and fresh biography readback | Passed in live log, 152.627 s. Original bundle unavailable after restart. |
| test01ReplayPlaybackControlsAndLinkedRecipe | Replay progress, six acknowledged reactions, gift picker, foreground, retry and linked recipe return | Passed in live log, 70.263 s. Original bundle unavailable after restart. |
| test02RecipesSearchScaleCollectionsAndCookSteps | Recipe search, scaled ingredients, saved and liked state, cooking steps and readback | Passed in live log, 88.003 s. Original bundle unavailable after restart. |
| test03KitchenMealGroceriesAndTimer | Meal and grocery changes, completion, timer controls and persisted data | Started in live log. Outcome unavailable after restart. |
| test04ChatsDirectoryWalletAndAgreements | Directory, all configured wallet tiers, resolved catalog state, unchanged balance, settings and legal PDFs | Unverified in this run after the host restart. |
| test05ProfilePhotoPickerInspection | Actual cooking photo is accessible in native picker and cancel returns | Unverified in this run after the host restart. |
| test06RealReplayAndRecipeComments | Replay and recipe discussion acknowledge real comments | Unverified in this run after the host restart. |
| test07NativeReplayShareInspection | Native share sheet opens and can be dismissed | Unverified in this run after the host restart. |
| test08WelcomePrimaryActionVisible | Welcome primary action is reachable and unchecked consent gates entry | Unverified in this run after the host restart. |
| test09AllRootsLayout | Each loaded root has five reachable dock targets inside the viewport | Passed in bounded standard-size recovery, 66.237 s. Maximum-size run unverified after restart. |
| test10RealProfilePhotoUpload | Selected actual cooking photo uploads and reappears as the QA avatar | Unverified in this run after the host restart. |
| test11RealChatPhotoUploadAndRender | An actual JPEG chat attachment is delivered and rendered on reopen | Unverified in this run after the host restart. |
| test12RealRecipePhotoPublishEditAndDelete | QA photo recipe publishes, edits and deletes through ordinary routes | Unverified in this run after the host restart. |
| test13WelcomeInlineAgreementLinksAndCheckbox | Independent inline agreement links render without changing checkbox state | Unverified in this run after the host restart. |
| test14RecipeHomeGridAndSingleResult | Two-column default recipe cards and a half-width single result | Unverified in this run after the host restart. |
| test15AccessibilityRecipeHomeUsesOneColumn | Maximum text uses one recipe column and full-width recipe actions with reachable steps | Unverified in this run after the host restart. |
| test16RecipeTutorialAndPreparationJourney | Actual publisher tutorial and persisted ingredient/cook-along state | Unverified in this run after the host restart. |
| test17LiveSearchFiltersAndAllReplayPlayback | Search, categories, advancing footage in all six replays, sound and truthful creation availability | Unverified in this run after the host restart. |
| test18ProfileValidationAndAccountActionCancellation | Invalid profile and both destructive confirmations cancel without losing identity | Unverified in this run after the host restart. |
| test19RecipeFiltersValidationAndDraftRestoration | Cuisine filters and private draft restoration with incomplete publication rejected | Unverified in this run after the host restart. |
| test20KitchenTimerSurvivesNavigationAndRelaunch | Wall-clock timer resumes through navigation and relaunch, then resets | Unverified in this run after the host restart. |
| test21TakenUsernameHasActionableFeedback | A real occupied handle receives specific feedback and original profile survives | Unverified in this run after the host restart. |
| test22LiveRoomCoversAndNavigation | Distinct room covers advance and preserve search, category and lifecycle behavior | Unverified in this run after the host restart. |
| test23AccessibleLiveRoomCovers | Maximum text keeps room cards one column and final replay reachable | Unverified in this run after the host restart. |
| test24AccessibilityProfileMetricsKeepWordsWhole | Maximum text keeps following and follower metrics in two readable columns | Unverified in this run after the host restart. |
| test24RecipeToolbarSearchAndCompactPersonalCollections | Toolbar search clears and restores catalog, personal collections use compact columns and profile edits open from Settings | Unverified in this run after the host restart. |
| test29FollowRealAcceptancePartner | Both real isolated partners can be followed through acknowledged profile actions | Unverified in this run after the host restart. |
| test30RealChatSendDraftAndPreferences | Real send, private draft restore, pin and mute persist for QA chat | Unverified in this run after the host restart. |
| test31RealChatReceiveWhileOpen | A fresh independent partner reply arrives in the open connected conversation | Unverified in this run after the host restart. |
| test32RealGroupCreationAndMemberManagement | Two mutual invitations create a real three-member group and member removal/restoration is acknowledged | Unverified in this run after the host restart. |
| test33RealGroupLeave | Owner leave is gated until both other members are removed and the group disappears | Unverified in this run after the host restart. |
| test34ChatBackgroundForegroundRetention | Real history and unsent draft survive background and foreground | Unverified in this run after the host restart. |
| test35ReportBlockAndUnblockIsolatedPartner | Report, block and unblock only the named isolated partner | Unverified in this run after the host restart. |
| test40PublishedRecipeReportAndBlockAuthor | Owned QA recipe reports and publisher blocking remove the expected fixture content | Unverified in this run after the host restart. |
| test41RecipeCommentAndRoomMessageSafety | Actual QA comment and room message offer author safety and update after blocking | Unverified in this run after the host restart. |
| test42PublishedReplayReportAndBlockAuthor | An isolated member-owned replay can be reported and removed by author block | Blocked. The earlier member-replay fixture was removed and the native publishing route is unavailable. |
| test43EditorialContentHideAndRestore | Editorial recipe/replay hide and restore are account-scoped and acknowledged | Unverified in this run after the host restart. |
| test44PublisherAttributionInSafetyMenus | Menu attributes isolated member recipe/replay to the true publisher separately from media credit | Blocked. The earlier member-replay fixture was removed and the native publishing route is unavailable. |
| test45PublisherAvatarsOpenProfilesIndependently | Cover avatar opens the true publisher profile independently, with recipe-only works | Unverified in this run after the host restart. |
| test46PublisherProfileAccessibilityLayout | Maximum text keeps publisher identity and conditional actions reachable | Unverified in this run after the host restart. |
| test47PublisherFollowEnablesMessageAfterAcknowledgement | Acknowledged Follow reveals Message and narrow Following, then prior relationship restores | Unverified in this run after the host restart. |
| test48RoomGiftSendingControlsAreAvailable | Gift choices, quantities and confirmation work without spending | Unverified in this run after the host restart. |
| test49LocalGiftDebitHistoryAndRelaunchPersistence | Fresh scoped gift authorization records exactly one durable debit | Blocked. This run has no fresh authorization for a retained gift debit. |
| test50RecordedGiftHistoryAndBalanceSurviveRelaunchWithoutSpending | Existing gifts and balance survive relaunch without another debit | Unverified in this run after the host restart. |
| test51HalfHeightGiftSheetKeepsVideoVisibleAndWalletReturnsCompact | Half-height picker preserves advancing footage, Wallet expands, compact return and cancel preserve balance | Unverified in this run after the host restart. |
| test52HalfHeightGiftSheetAccessibilityActionsRemainReachable | Maximum text scrolls gift choices above the reachable Send action | Unverified in this run after the host restart. |
