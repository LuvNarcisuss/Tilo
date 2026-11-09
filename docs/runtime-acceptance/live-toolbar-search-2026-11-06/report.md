# Live toolbar search

Date: November 6, 2026.

The owner requested removal of the persistent Live search field and a search button next to creation. The default page now has two generated raster toolbar actions: search on the left, creation on the right. Search expands/focuses the existing custom-font field; its action switches to Close search. Closing clears the query and restores the selected category. Query and field visibility persist across room entry and return. No media, backend, payment, identity or agreement change is included.

The existing focused room discovery case was adapted to check collapsed initial state, toolbar placement, open/search/room-return, collapse/clear and creation access. It also retains real cover and room playback checks. Test17's entry was adapted to the same toolbar route; that broader all-film method is not claimed as rerun unless separately recorded.

Authorized runtime target remains Toli UI Acceptance, iPhone 17 Pro / iOS 26.0.1, 26399755-5402-48C1-A2C9-CA26E57505AB. StoreKit IDs remain empty.

The first current-source run, /private/tmp/toli-live-toolbar-search-20261106-013102.xcresult, completed the search and room assertions but failed after opening creation because the test expected a Cancel button. Actual screenshot/hierarchy showed the iOS 26 anchored popover with a native PopoverDismissRegion instead. The focused case now follows the same native dismissal handling already used by test17; no menu behavior or service result was fabricated. This initial result is retained as a failed diagnostic, not a passing case.

## Passing focused acceptance

/private/tmp/toli-live-toolbar-search-final-20261106-014045.xcresult: test22LiveRoomCoversAndNavigation passed, 98.911 seconds, zero failures. This covers hidden initial field, adjacent toolbar actions, search opening, empty/results states, room playback/return with query retained, closing/clearing, cover restoration and native creation-menu dismissal. [Final collapsed toolbar](toolbar-search.png) was visually inspected; [expanded query](expanded-search.png) is retained. Static verification passed all 309 checks. No full-app suite, maximum-text rerun or purchase environment was exercised for this focused change.

Xcode rebuilt the latest Toli project with scheme Toli and destination Toli UI Acceptance, then visibly reported Running Toli on Toli UI Acceptance. The latest app was left running on the required named simulator.
