# Runtime acceptance fixes

Environment: Xcode 26.0.1, iPhone 17 Pro, iOS 26.0.1. Simulator: Toli UI Acceptance, 26399755-5402-48C1-A2C9-CA26E57505AB. Current workspace source is built, ad hoc signed, installed and launched before each test batch. PurchaseProducts.json remains an empty object.

## Reproduced compiler errors

The first native build exposed unqualified helper names shadowed by UIView/UITableViewCell members, escaping-closure explicit self requirements, and a shadowed error property in backend reconciliation. These were corrected. The subsequent named-device app build and UI-test target compiled and linked successfully.

## Reproduced UI issues

- The welcome primary action fell below the initial viewport. It is now a pinned footer, with a compact introduction and scrollable consent/legal content. The initial failing test is retained in the temporary keyboard-and-entry-baseline result bundle.
- Profile editing did not constrain the page viewport above the software keyboard. The page now follows keyboardLayoutGuide. The first test-helper revision incorrectly swiped the keyboard suggestion strip; the corrected helper targets the identified page-scroll viewport and excludes short horizontal scroll views. The actual profile save/readback and five-root test passed, 1 executed / 0 failures, in profile-layout-result.json.
- The Live header illustration stretched to fill its horizontal stack and the introduction pushed cooking imagery down. The illustration now has a square aspect-fit frame and the introduction is shorter.
- Kitchen displayed an empty page during its first backend request. It now displays its loading state until the meal plan and shopping list arrive.
- Replay play/sound controls changed visible titles while retaining their initial accessibility labels. They now update both. The accessible elapsed-time label is driven by AVPlayer time, permitting actual time progression and pause checks. Retry preserves sound state and releases the previous periodic observer.
- The base modal page replaced the discussion controller close action during view appearance. It preserves a controller-owned close action and replaces the base root Back action with a modal Close; root Back also dismisses safely. A first-wave UI test reproduced the missing Close discussion action before this correction.

## Current evidence boundary

The latest outcomes of all 20 distinct cases passed across focused batches. See report.md and results/index.json for exact executions and remaining validation gaps. Earlier failed runs remain diagnostic evidence and are not counted as successful acceptance.
