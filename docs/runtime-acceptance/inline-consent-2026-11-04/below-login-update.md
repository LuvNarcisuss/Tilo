# Consent below the login action

Date: November 4, 2026.

The owner requested that the agreement declaration appear below Log in. The fixed welcome footer now stacks Log in, a 14-point gap and the checkbox with the complete inline agreement paragraph. The introduction scrolls above this footer. Custom fonts, generated check artwork, document destinations and explicit consent behavior are unchanged.

Validation uses the latest workspace source installed on Toli UI Acceptance (iPhone 17 Pro, iOS 26.0.1, device 26399755-5402-48C1-A2C9-CA26E57505AB). The existing agreement case checks that the checkbox and declaration follow the login button, the whole declaration is on screen, both inline links open their documents, reading does not grant consent, and unchecked login requires confirmation.

## Default text evidence

Build succeeded. Two focused methods passed with zero failures: test08WelcomePrimaryActionVisible (10.908 seconds), and test13WelcomeInlineAgreementLinksAndCheckbox (22.797 seconds).

Result: /private/tmp/toli-consent-below-login-20261104-014807.xcresult.

The [normal-size screenshot](welcome-below-login.png) was visually inspected: Log in appears above the complete checkbox/declaration row, both links are underlined, and all footer controls fit above the home indicator.

## Maximum text and final state

The largest accessibility text category passed test13WelcomeInlineAgreementLinksAndCheckbox with zero failures (28.186 seconds). Result: /private/tmp/toli-consent-below-login-maximum-text-20261104-014935.xcresult. The [maximum-text screenshot](welcome-below-login-maximum-text.png) was visually inspected: the full declaration remains beneath the login action and within the screen.

Static verification passed 279 checks. The simulator text category was restored to large and the latest application was launched (process 68158). Purchase product IDs remain empty. This placement-only update did not rerun the full feature suite or perform any payment validation.
