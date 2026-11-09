# Recipe overview, preparation and tutorial journey

Date: November 5, 2026.

## Implementation and references

The owner's request replaces the long recipe detail with a finished-dish overview, a dedicated ingredient-preparation page and one-step-at-a-time cooking. Current Bibi ChallengeDetailController inspiration-video routing and the historical Teto PhraseDetailController lesson section navigation were inspected. Retired template features, identity and content are not imported.

The overview keeps the finished photograph, recipe facts, summary, source-attributed tutorial and preparation entry. Start cooking stays pinned. Recipe options retains meal planning, discussion, edit/delete for owners and reporting otherwise. Preparation scales quantities, offers a temporary checklist and writes groceries through the existing protected backend. A shared in-memory session retains quantities, checklist and step while moving between these pages and the tutorial; it does not replace account state. Cooking retains the kitchen timer and persistent Previous/Next/Finish actions.

Twelve distinct source tutorials were verified against YouTube's official oEmbed title, author and embed response. Metadata was added only to the twelve existing editorial recipe rows with owner_id IS NULL; SQL readback confirmed 12 recipes, 12 tutorials and 12 unique videos. No private recipe, finished image, method, balance, payment ID or agreement changed. Sources and copyright/hosting scope are recorded in ../../recipe-tutorial-sources.md and ../../recipe-tutorials.json. Official embedding retains publisher controls and source links; videos were not downloaded or rehosted. Tutorial variations are disclosed in the product.

## Native environment and evidence

Named simulator: Toli UI Acceptance, iPhone 17 Pro / iOS 26.0.1, 26399755-5402-48C1-A2C9-CA26E57505AB. Latest workspace source was rebuilt, installed and launched for every batch.

- The first build found a next property name colliding with UIResponder.next; the local button property was renamed nextButton.
- /private/tmp/toli-recipe-tutorial-playback-20261105-075834.xcresult retained an unsuccessful UI attempt. The captured overview was in a transition to Cook along and subsequent attempts searched the Recipes root. A deterministic navigation-bar and visible-action wait was added before the tutorial tap. No playback success is claimed from that attempt, and its underlying transition trigger is not established.
- /private/tmp/toli-recipe-tutorial-navigation-20261105-080624.xcresult: test16RecipeTutorialAndPreparationJourney passed (75.625 seconds, zero failures). The official player reported Playing and real media time advanced by more than one second. Portion scaling, ingredient checking, step change, tutorial navigation and preserved state on return passed.

Inspected screenshots: [Overview](overview.png), [Actual publisher playback](tutorial-playing.png), [Preparation](preparation.png), [Preserved state](preserved-state.png).

## Verification limits

Official source metadata was checked for all twelve videos. Actual native playback and a representative visible frame were verified for the tomato-pasta tutorial, not continuously for all twelve tutorials or every geographic/network condition. Remaining publisher availability is not inferred from oEmbed alone. Maximum-text layout and full previous acceptance suite are not covered by the focused journey case. Payments, remote gift sending, live broadcasting and Stage B integration remain outside this change.

## Existing-feature regression

/private/tmp/toli-recipe-split-regression-20261105-081033.xcresult passed both cases with zero failures: test02RecipesSearchScaleCollectionsAndCookSteps (122.752 seconds) and test03KitchenMealGroceriesAndTimer (112.101 seconds). These exercised split-page portion scaling, saved/liked server collections, previous/next/finish cooking, actual shopping-list writes/readback and the kitchen timer. After inspecting the first preparation screenshots, ingredient rows were tightened and true outlined checkbox targets replaced the earlier plus-mark presentation. The final journey rerun records that presentation change separately.

## Final compact preparation verification

/private/tmp/toli-recipe-journey-final-20261105-081722.xcresult: test16RecipeTutorialAndPreparationJourney passed again (75.301 seconds, zero failures) after the compact checkbox-row change. The final overview, actual publisher playback and complete seven-ingredient preparation screenshots were visually inspected. The preparation screenshot shows the ingredients, shopping-list action and pinned Start cooking within the named iPhone screen. The linked overview, tutorial, preparation and preserved-state images above now come from this final run. Three distinct relevant test methods passed across the journey and existing-feature batches; the focused journey method was repeated after the final visual adjustment.

## Final delivery state

Xcode opened the current Toli.xcodeproj, rebuilt the Toli scheme and visibly reported Running Toli on Toli UI Acceptance. The latest app was left running on the required simulator. Final static verification completed 297 checks with zero failures. PurchaseProducts.json remains an empty object. No StoreKit test, Apple sandbox purchase or production transaction was performed.
