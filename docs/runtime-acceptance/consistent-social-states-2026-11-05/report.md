# Consistent reaction, save and completion states

Date: November 5, 2026.

## Scope

Recipe bookmarks now switch between the hollow olive outlined ribbon and a generated golden-yellow filled ribbon. Shared ToliIcon.likeState/saveState selectors centralize the two-state artwork. Recipe social controls stay background-free and retain server-acknowledged changes. The recipe save control now exposes Saved / Not saved accessibility values as well as selected state.

The same audit found replay reactions always used a filled heart. They now share the outlined/filled pair used by recipes, with a light compact backing for contrast over video. Grocery completion had the same check icon before and after completion; pending items now use the existing grocery-bag artwork and completed items use the check artwork, with matching text and accessibility state. Existing checkbox preparation, filter selection, follow plus/check, gift selection and chat pinned/muted text were inspected. Destination icons in profile collections remain navigation labels, not per-item save controls.

No authentication, database, agreement, purchase or media-source change is included. Test toggles restore the original recipe/replay state. Product IDs remain empty.

## Artwork

Built-in image_gen edited the existing bookmark reference into its owner-selected solid yellow counterpart and a separate transparent-interior outline. Sources: Assets/Generated/toli-bookmark-filled-yellow.png and toli-bookmark-outline.png. Runtime: ToliApp/Toli/Resources/Assets.xcassets/icon-bookmarkFilled.imageset/icon-bookmarkFilled.png. The original generic bookmark artwork was preserved for navigation; item state uses the new matched pair. Proportional resizing retains generated alpha; prompts and hashes are recorded in Assets/Generated/prompts.md and asset-manifest.json.

## Verification environment

Only Toli UI Acceptance, iPhone 17 Pro / iOS 26.0.1, device 26399755-5402-48C1-A2C9-CA26E57505AB. Current-source packages are rebuilt, installed and launched for the focused acceptance batches. This record does not claim a full-app regression, maximum-font review or any StoreKit/Apple payment test.

## First diagnostic batch

/private/tmp/toli-consistent-social-states-20261105-094812.xcresult: the recipe journey, including both directions of saving and restoration, passed in 84.103 seconds before the owner's yellow-color correction. The replay method failed its foreground playback assertion in 59.886 seconds; its actual like/unlike operations and screenshots completed first. This batch is not reported as fully passing. The failure hierarchy exposed real AVPlayer time 11.75 seconds and a noninitial cooking frame. The original helper required time to remain above the starting value plus one second, which cannot work when a looping clip resets near the end. The revised probe sums only observed positive native time deltas and logs backward resets; a reset alone cannot satisfy it. Production playback code was not changed for this diagnostic. Final-color and playback results are recorded separately below.

The later explicit owner instruction selects a hollow outlined inactive bookmark and solid yellow active bookmark. The red prototype was superseded before final delivery.

The final playback rerun explicitly observed the probe begin at 19.75 seconds, then the loop reset from 19.75 to 0.75 seconds. Forward playback continued and test01ReplayPlaybackControlsAndLinkedRecipe passed in 72.164 seconds. This confirms the monotonic-time assumption was inappropriate for the looping replay. Both actual reaction directions and restored state were also captured in that passing method.

## Final-color functional batch

/private/tmp/toli-yellow-bookmark-final-20261105-095543.xcresult passed three distinct UI methods with zero failures: test01ReplayPlaybackControlsAndLinkedRecipe (72.164 seconds), test03KitchenMealGroceriesAndTimer (121.003 seconds) and test16RecipeTutorialAndPreparationJourney (84.100 seconds). This includes real like/unlike and save/unsave requests with original state restored, playback across background/foreground and looping, actual inline publisher playback, prepared-item state retention, shopping-list mutation/readback and the kitchen timer.

The matched yellow/outline screenshots were inspected. Their generated alpha contained nearly transparent peripheral pixels that made the runtime ribbon smaller than intended. The final asset-only refinement crops to alpha >= 32 before proportional fitting; the original edge alpha remains intact. A focused recipe rerun records that size refinement separately. [Grocery pending/completed states](grocery-states.png) were visually inspected. [Replay changed state](replay-state-changed.png) and [restored state](replay-state-restored.png) are retained from the passing batch.

## Final visual-size verification

/private/tmp/toli-yellow-bookmark-size-final-20261105-100359.xcresult: test16RecipeTutorialAndPreparationJourney passed again after the asset-only sizing refinement, 82.147 seconds, zero failures. [Inactive outline](bookmark-outline.png) and [active yellow fill](bookmark-yellow.png) were visually inspected at final runtime size. Three distinct affected UI methods passed across the final-color batch, with the recipe method repeated for the final resources. Static verification passed all 303 checks. PurchaseProducts.json remains empty.

## Final Xcode state

Xcode rebuilt the final current Toli project using scheme Toli and destination Toli UI Acceptance, then visibly reported Running Toli on Toli UI Acceptance. The latest app was left running on that named simulator. No StoreKit transaction, product configuration or backend deployment was performed.
