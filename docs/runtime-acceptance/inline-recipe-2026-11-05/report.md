# Inline tutorial and recipe categories

Date: November 5, 2026.

## Owner-directed composition

Discovery cards retain their licensed finished-dish photographs. Recipe details now begin with the existing official YouTube tutorial, with no separate Watch video tutorial entry. The compact Ingredient prep / Cooking steps control switches between checkable ingredient rows with scaling and numbered instruction rows. Start cooking sits above a background-free Like / Save / Share row. The unliked state uses a new generated hollow olive heart; the liked state uses the existing red filled heart. Both changes wait for server acknowledgement.

The player is retained independently from ingredient, tab and collection updates, avoiding video reloads during these interactions. It pauses when leaving the recipe or when the app resigns active. Cook-along mode, shopping-list writes, recipe options and source/reload actions remain available. Optional missing-video content shows an explicit unavailable message. No backend deployment, media source replacement, payment configuration, agreement or private-data migration was performed.

## Environment and test evidence

Toli UI Acceptance, iPhone 17 Pro / iOS 26.0.1, device 26399755-5402-48C1-A2C9-CA26E57505AB. The helper rebuilds current workspace source, installs that package and launches it before tests.

- /private/tmp/toli-inline-recipe-red-20261105-090859.xcresult: the revised journey case failed on the old Watch video tutorial button still being present, before implementation. This is expected failing coverage of the owner's requested change.
- /private/tmp/toli-inline-recipe-journey-20261105-091842-build.log: compilation exposed UIView.action shadowing the shared action helper after ingredient preparation moved into a view. Calls were qualified with the current Toli module. No runtime success is claimed from this build.

## Artwork

Built-in image_gen created the inactive heart from the existing raster reference. Original output is Assets/Generated/toli-heart-outline.png; the target consumes Resources/Assets.xcassets/icon-heartOutline.imageset/icon-heartOutline.png. Generated transparency was retained during proportional resizing. Prompts and source/runtime hashes are recorded in Assets/Generated/. No native symbol or original artwork replacement was introduced.

## Limits

Focused acceptance covers the affected recipe flows. Tutorial sources remain the previously verified twelve publisher links; native actual playback coverage is the tomato-pasta tutorial. This change does not establish all-video playback, maximum-text layout, full-app regression, StoreKit, Apple sandbox or production purchase availability. Product IDs remain empty.

## Passing inline journey

/private/tmp/toli-inline-recipe-journey-fixed-20261105-091932.xcresult: test16RecipeTutorialAndPreparationJourney passed, 83.323 seconds, zero failures. The inline official player reported Playing and actual media time advanced. Ingredient scaling/checking persisted across in-place category switches and cook-along return. The case reached the fifth instruction row, toggled a real server-backed like in both directions and restored the original state. It also checked Start cooking is above Share.

Visually inspected actual simulator screenshots: [Inline video and plain social actions](inline-video.png), [Numbered step rows](steps.png), [Ingredient checklist](ingredients.png), [Retained preparation](preserved-state.png). The category control remains a compact single rounded box; Like, Save and Share have no background panels. These images show the active filled heart; the inactive generated hollow heart was independently inspected for actual transparent interior and outer alpha.

## Existing-feature regression and static checks

/private/tmp/toli-inline-recipe-regression-20261105-092241.xcresult passed two cases with zero failures: test02RecipesSearchScaleCollectionsAndCookSteps (113.416 seconds) and test03KitchenMealGroceriesAndTimer (102.199 seconds). Current recipe search, serving scaling, saved/liked collections, all five cook-along steps/finish, meal-plan access, shopping-list writes/readback and kitchen timer were exercised. Together with the inline journey, three distinct relevant UI methods passed.

Final static verification completed 299 checks with zero failures. The generated icon count is 37 (original 36 plus the inactive heart). PurchaseProducts.json remains an empty object. The build emitted the standard App Intents metadata-skipped notice because the app has no AppIntents dependency; this is not a compiler error. No local StoreKit or Apple purchase test ran.

## Final Xcode run

Xcode rebuilt the current Toli project with scheme Toli and destination Toli UI Acceptance, then visibly reported Running Toli on Toli UI Acceptance. The latest app was left running on that named device after the tests.
