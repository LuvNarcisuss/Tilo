# Tilo nightly acceptance — November 9, 2026

## Outcome

The current build and five-root recovery check passed. Full runtime acceptance is incomplete after a host restart interrupted the main batch, removed temporary result files and shut down the designated simulator. The later attempt to open Tilo in Xcode timed out and lost the foreground application. Final Xcode Run with the local StoreKit fixture remains unconfirmed.

The run was triggered at 09:32 Asia/Shanghai. The current app built, installed and launched with scheme and target Tilo on Tilo UI Acceptance, iPhone 17 Pro / iOS 26.0.1 build 23A8464, device 26399755-5402-48C1-A2C9-CA26E57505AB. The installed recovery executable matched the freshly built package, with bundle com.toli.cooking and device family [1]. [Run context](run-context.json)

## Verified layers

| Layer | Actual result |
| --- | --- |
| Build and launch | Recovery build succeeded and the exact installed executable was verified before runtime checks. The main batch also reached a successful build and launch. |
| Archived native UI | One current five-root case passed in 66.237 seconds, with five actual screenshots retained and inspected. The standard dock, loaded cover images, publisher portraits and root controls were visible. |
| Native live log observations | Consent and profile persistence passed in 152.627 seconds, replay and linked recipe in 70.263 seconds, and recipe interactions in 88.003 seconds. The main batch's original log and bundle are unavailable after restart, so these are recorded separately from archived XCTest results. The Kitchen case had started at the last observation. |
| Static | 381 checks passed. |
| Backend | 77 core, 27 corrected publisher and 30 content safety checks passed in their final finite runs. The first core attempt recorded 46 passes and one missed authorized realtime delivery in a 15-second window. The retry observed delivery and reconciliation. The cause of the initial timeout is unconfirmed. |
| Public assets | All 31 distinct files matched the expected SHA-256, including the current terms and privacy PDFs at consent version 2026-11-06-99d6afcc3037. |
| Wallet | Nine configured products were inspected statically. The retained isolated wallet's hash, balance and five gift receipts match the pre-run baseline. The Apple wallet inventory is empty. No new purchase or gift debit was observed. |
| StoreKit | The planned isolated local and native purchase tests did not execute during this run. Apple sandbox, production and creator settlement remain unverified. |
| Diagnostics | No new Tilo crash report was found in the checked host directory. A complete simulator log scan was unavailable across the restart. |

[UI index](ui-results.json) · [Five roots](recovery-five-roots.jpg) · [Per-method coverage](coverage-matrix.md) · [Static result](static-verification.json) · [Core retry](backend-retry.json) · [Publisher result](publisher-backend-corrected.json) · [Safety result](safety-backend.json) · [Public files](public-all-artifacts.json)

The durable recovery build and test logs are tilo-nightly-20261109-recovery-build.log and tilo-nightly-20261109-recovery-test.log in this folder. The recovery bundle was originally /private/tmp/tilo-nightly-20261109-recovery.xcresult. The interrupted main test log and bundle were /private/tmp/toli-nightly-20261109-essentials-20261109-013828-test.log and /private/tmp/toli-nightly-20261109-essentials-20261109-013828.xcresult. Those temporary paths were absent after restart. The exported recovery attachments and structured summary survived in this folder.

## Acceptance changes

The runner now defaults to a 420-second per-method XCTest limit and accepts --evidence-dir. The recurring prompt directs future runs to write original logs, fingerprints and result bundles into each run's raw evidence subdirectory. The current limited recovery probe preceded the durable-path change. The new option received CLI help and static verification. An end-to-end run using the new path remains pending. The original 20:00 Asia/Shanghai recurrence, active state and current chat target were verified after the prompt update.

The retained gift history case now samples the existing receipt count and checks it after relaunch. The former exactly-one assertion depended on an older fixture. This updated UI case awaits execution. The publisher verification now uses memberIDs and verifies the exact mutual-follow denial. The corrected backend test passed against the current service. [Diagnosis record](diagnosis-notes.md)

## Remaining fixture cleanup

The finite backend suites removed their disposable accounts. The host restart removed the session file for one separately prepared native safety publisher. Read-only server checks confirmed its exact anonymous account, recipe and uploaded object before scoped cleanup. The recipe is unpublished and both comments created by that fixture were removed. Its Auth account, unpublished recipe and uploaded photo remain pending authorized storage and account cleanup. The supported delete-account function requires the missing verified session. The remaining object should be removed through Storage before deleting the account through Auth. [Fixture identity and state](safety-cleanup-state.json)

Native chat, maximum text, secondary routes, full wallet acceptance and final IDE launch need another run on the designated simulator. The evidence separates the interrupted attempt from the earlier historical reports. The actual outcome of methods that continued after the last observed log line is unknown.
