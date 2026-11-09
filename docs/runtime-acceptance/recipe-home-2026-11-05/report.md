# Recipe home grid

Date: November 5, 2026.

## Reference study and implementation

The owner requested the Bibi post-home approach. Current Bibi CircleControllers.swift was inspected, including addTwoColumns, compact community cards, square covers, saved-post summary cards and whole-card navigation; the maintained two-column notes in docs/IMPLEMENTATION.md and docs/STATIC-AUDIT.md were also read. Bibi's single-column post detail is distinct from its compact home grid.

Toli's Recipes root now presents two equal card columns with a 12-point gutter, square real food photography, compact padding and short category/title/time metadata. A trailing unmatched result retains the left half-width slot. The large introduction is replaced by one short heading. Active cuisine filters have visible selected styling and accessibility selection state. The existing search, filter, pull-to-refresh and Write a recipe paths remain connected to the actual backend. Search/filter requests are still debounced/cancelled and generation-checked. Details and personal collection cards keep their single-column composition. Accessibility text categories switch the homepage to one column.

No Bibi content, identity, service configuration or fictional engagement is copied. Existing generated Toli background/icons and custom fonts are retained; no new artwork is required for this layout change.

## Environment

Latest workspace source built, ad hoc signed, installed and launched on Toli UI Acceptance, iPhone 17 Pro / iOS 26.0.1, device 26399755-5402-48C1-A2C9-CA26E57505AB. Build succeeded. Static resource/source/metadata verification passed 285 checks.

## Default-text functional batch

Result: /private/tmp/toli-recipe-home-grid-20261105-070411.xcresult.

- test02RecipesSearchScaleCollectionsAndCookSteps passed (150.470 seconds), including search/no-results, detail navigation, serving scaling, saved/liked collections and cook-along steps.
- The two-column geometry assertions in test14 passed: equal widths, aligned top edges, 12-point gutter and half-width cards. Its one-result fixture initially failed because "Tomato" actually matches three existing titles. The exported failure hierarchy confirmed recipe-01, recipe-10 and recipe-11; the test now uses the unique full recipe title. No product code was changed for that fixture correction.

The [two-column screenshot](two-columns.png) was visually inspected: square food covers, compact readable metadata and continuous title background.

## Single-result regression

Result: /private/tmp/toli-recipe-home-grid-single-result-20261105-071106.xcresult. test14RecipeHomeGridAndSingleResult passed with zero failures (43.841 seconds). It verified the two-column geometry, one uniquely matched recipe retaining its half-width slot, detail navigation and preserved query on return. The source was rebuilt, installed and launched before the rerun; no data was replaced or removed to force a single result.

The passing single-result screenshot was inspected: the sole card remains on the left at the original half width, with square photography and readable metadata.

## Maximum text regression

At accessibility-extra-extra-extra-large, test09AllRootsLayout passed with zero failures (107.822 seconds). Result: /private/tmp/toli-recipe-home-large-text-20261105-071327.xcresult. The [recipe screenshot](maximum-text.png) was inspected for the full-width single-column presentation and accessible bottom navigation. The category was restored to large after the batch.

The three relevant methods have passing latest outcomes across focused batches. The initial fixture failure remains recorded. No full major-feature-suite rerun, payment test, backend deployment, private-data reset or asset replacement was performed for this presentation change.

## Final Xcode run

Xcode opened the current Toli.xcodeproj with scheme Toli and destination Toli UI Acceptance. Run rebuilt the latest source and the activity explicitly reached "Running Toli on Toli UI Acceptance" with an active debug session. The final application remains running there at normal text size. PurchaseProducts.json remains empty.
