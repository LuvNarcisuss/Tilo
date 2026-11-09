# Welcome inline agreement verification — November 4, 2026

The initial placement evidence below precedes the owner's subsequent instruction to place consent beneath Log in. The current placement and its separate regression evidence are recorded in [below-login update](below-login-update.md).

## Change and references

The welcome screen now presents one English agreement paragraph beside a separate, initially unchecked checkbox. Terms of Service and Privacy Policy are underlined inline hyperlinks, opening the existing Toli PDF reader. Reading either agreement does not grant consent. The existing unchecked login confirmation and real one-tap authentication remain in place.

The presentation follows the inspected native welcome implementations in TotiApplication.swift (Toti) and BibiApplication.swift (Bibi). Toli keeps its own document URLs, custom Comic Neue font and image-model check artwork. The checkbox has a 44-by-44-point touch target.

## Environment

- Simulator: Toli UI Acceptance, iPhone 17 Pro, iOS 26.0.1 (23A8464).
- Device ID: 26399755-5402-48C1-A2C9-CA26E57505AB.
- Xcode: 26.0.1 (17A400).
- Current workspace source was built, ad hoc signed, installed and launched before each batch.

## Default text results

Three focused UI methods passed, with zero failures:

- test08WelcomePrimaryActionVisible.
- test09AllRootsLayout, including ordinary real guest entry and all five roots.
- test13WelcomeInlineAgreementLinksAndCheckbox, covering both actual inline links, unchanged unchecked state after reading, checkbox selection and the unchecked login confirmation.

Result bundle: /private/tmp/toli-inline-consent-20261104-013346.xcresult.

## Maximum text investigation

The first maximum-text execution failed because XCTest considered a partly visible, wrapped link hittable and tapped its center underneath the fixed login footer. Its screenshot and accessibility hierarchy showed the partially occluded link. The focused test now requests full link visibility before tapping; application behavior was not changed for this test issue.

Original diagnostic result: /private/tmp/toli-inline-consent-maximum-text-20261104-013704.xcresult.

The corrected maximum-text execution passed test13WelcomeInlineAgreementLinksAndCheckbox with zero failures (38.008 seconds). Both links opened the corresponding in-app document, and explicit checkbox and unchecked-login checks passed. The inspected screenshot shows the wrapped links fully visible above the fixed login footer.

Passing result: /private/tmp/toli-inline-consent-maximum-text-fixed-20261104-014001.xcresult.

## Final state

Static verification completed 279 checks with zero failures. The simulator text category was restored to large, and the latest app was launched on the named simulator (process 64534). The final normal-size screenshot was inspected, showing the unchecked checkbox, one paragraph with both underlined links and the visible Log in action. No full-suite rerun was needed for the test-only visibility helper refinement.

Screenshots: [Unchecked welcome](welcome-unchecked.png), [Checked welcome](welcome-checked.png), [Maximum text](welcome-maximum-text.png).

## Scope

These focused results follow the historical November 3 major-feature report; they do not claim that the full twenty-method suite was rerun after this presentation change. PurchaseProducts.json remains empty. No StoreKit transaction, backend setting, agreement document or service binding was changed.
