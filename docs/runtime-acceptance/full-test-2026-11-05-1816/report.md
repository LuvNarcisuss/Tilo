# Toli comprehensive acceptance

Date: November 5, 2026. Workspace: /Users/apple/Desktop/Tilo. Execution window: approximately 18:16–20:16 Asia/Shanghai.

## Outcome

The executed acceptance scope is complete. All 32 distinct native UI methods have a final passing outcome across focused batches. Three product defects were reproduced and corrected: misleading occupied-username feedback, character wrapping in maximum-text recipe actions, and character wrapping in maximum-text relationship metrics. This is bounded acceptance evidence, not proof of every application branch or production service.

The nightly automation was not changed. Its complete TOML SHA-256 remains 31ef76487935b1ed6032dedbec197ae8eaaa859eea2c315bab030f9d031db6d1 and it remains active at 20:00 daily. The latest built app is installed and running on the designated simulator. Installed and built executable hashes match and the original large text category is restored. See [final-state.json](final-state.json) and [final launch screenshot](final-launch.png). The app is left on its ordinary welcome screen; no authentication bypass was added.

## Evidence by layer

| Layer | Actual result | Evidence |
| --- | --- | --- |
| Build/install/launch | Current source built and installed on the required device | Per-batch build logs, source snapshots and final-state.json |
| Native UI | 32 distinct methods finally Passed; 46 executions across 12 batches: 41 passes, 5 retained diagnostic failures, zero skipped | [ui-results.json](ui-results.json) |
| Final current-source standard regression | Three passed: recipe interactions, five roots and inline tutorial/preparation journey | final-functional logs and attachments |
| Final current-source maximum-text regression | Three passed: five roots, recipe actions/final instruction and profile metric geometry | word-layout-green logs and attachments |
| Static inspection | 309 checks, zero failures | [static-verification.json](static-verification.json) |
| Finite real backend verification | 77 passed, zero failed in the complete run | [backend-acceptance-complete.json](backend-acceptance-complete.json) |
| Public media and agreements | 31 distinct files; 33 successful anonymous download/hash checks, including repeated agreement references | [public-artifacts.json](public-artifacts.json) |
| Visual review | All exported PNG evidence reviewed, including diagnostic failures and corrected layouts | [visual-review.md](visual-review.md), review/ and manifests |
| Crash/log inspection | No new Toli crash report found; bounded five-minute fatal/uncaught/constraint query completed with no matching entries | [runtime-diagnostic-scan.json](runtime-diagnostic-scan.json) |
| Payments | Product mapping remains empty; no transaction executed | run-context.json paymentStaticReview and final-state.json |

Every native batch identifies Toli UI Acceptance, iPhone 17 Pro / iOS 26.0.1, device 26399755-5402-48C1-A2C9-CA26E57505AB. No other device substitutes for it. The broad two-hour unified-log query timed out; a clean whole-session unified log is not claimed.

## Executed feature coverage

| Area | Observed behavior |
| --- | --- |
| Live | Search/categories, all six actual replay films advancing, sound/actions, truthful replay/source labeling and unavailable broadcast/gift delivery, real room comments, linked recipes/share, standard and maximum-text covers |
| Recipes | Search/cuisine filters, grid/single-result slots, scaling/checklists, cooking steps/cook-along, acknowledged likes/saves and collections, actual photo publish/edit/delete, invalid publication, private draft restoration, discussions/share, real inline publisher tutorial and retained preparation state |
| Kitchen | Real meal/grocery changes and readback, completion, timer pause/reset, navigation, background return and cold launch retention |
| Chats | Real reciprocal acceptance partners, direct text/photo, private image render/reload, history/draft, pinned/muted state, fresh incoming reply, groups/messages/member management/owner leave, background restoration, isolated report/block/unblock |
| Me and agreements | Fresh persisted profile/avatar, collections/counts, validation/occupied handle, settings/PDFs, zero wallet/unavailable purchases, consent/links, logout and both destructive account confirmation cancellation branches |
| Accessibility text | Welcome/agreements, all five roots, single-column discovery, reachable final instruction, full-width recipe actions and two-column profile metrics at maximum text |

## Corrections and regression evidence

1. ToliBackend recognizes the real updateProfile HTTP 409 / PostgreSQL 23505 profiles_username_key conflict and returns an actionable username-in-use message. The original profile remains unchanged. The focused native case failed before the fix and passed afterward; username-conflict-response.json retains the independent real response.
2. Recipe actions switch to separate full-width rows at accessibility sizes. Standard text retains its compact row. Trait changes update actions without replacing the tutorial player. The strengthened geometry assertion failed before the fix and passed afterward; whole-word labels were visually checked.
3. Me and creator relationship metrics use two columns at accessibility sizes and four at standard sizes. The strengthened width case failed before the fix and passed afterward. Standard and maximum-text regressions confirm the composition.

The test harness now derives an account-specific handle instead of reusing a retained historical account's occupied handle and checks a fresh biography. The first expanded Live test expected a Cancel button after successfully playing six films; the observed native popover uses a dismiss region. Its corrected selector passed. Initial maximum-text navigation assertions missed two visual defects; screenshot review triggered stronger assertions and the fixes above. All diagnostic failures remain in the result history.

## Real service evidence and data handling

The complete finite backend run used ordinary client credentials against dedicated Toli project hdapofqufmxlghmcrftg. It covered empty new-member state, identity refresh, ownership/RLS isolation, atomic groceries, real photo-backed recipe publish/edit/delete with independent observation, message deduplication/conflicting retries, WebSocket delivery, history reconciliation, private photos, groups, blocking and self-deletion. Foreign mutations may be denied or owner-filtered no-ops; the harness always verifies the protected record is unchanged. Earlier incorrect harness expectations are retained. All twelve disposable accounts created across four finite runs were deleted, stale business access was rejected and no cleanup failure remains.

The current native account is d3ebe3e1-149d-489c-9443-f5999e648b74, handle toli_acceptance_d3ebe3e1. Historical account a2756376-964b-48d0-8863-295daaba6473 and both existing real acceptance partners remain intact. Fresh profile/avatar, direct text/photo and partner reply evidence is retained. The private message image was independently downloaded with matching SHA-256. The real partner observed the fresh ready message and sent its response in 747 ms; the connected native screen received it within the test bound. Native UI evidence alone does not exclude every reconciliation/polling path. See native-service.json.

The isolated group was independently verified with three actual members and its stored message, then both other members were removed and the native owner left through ordinary UI. Former-member history/member requests were subsequently denied. The native test recipe was deleted normally. Account-scoped drafts, avatar, direct messages and QA kitchen/collection state remain for inspection. Wallet credit stays zero. Private credentials are outside repository evidence. No real user was contacted, starting credit granted or network success fabricated.

## Source provenance

Another owner workflow updated Live covers on this workspace and mandatory simulator after the core batch. This run yielded device control until that workflow completed and preserved its changes. Two completed cover batches were imported with their exact snapshots/device identity. Earlier fingerprints are not relabeled as current-source passes. See core-source-differences.json and diagnosis-notes.md.

Later targeted batches rebuilt the latest source before installation/launch. The final standard and typography batches match current application inputs. This is a sequence of diagnostics and focused regressions, not one uninterrupted 32-case suite on a single unchanged binary. No application source changed after the final functional build; subsequent changes finalize documentation/evidence.

## Verification limits

PurchaseProducts.json remains {}. Static payment review covers verified transactions, account ownership, deduplication, overflow checks, atomic persistence before balance publication and cancellation/pending handling. Local StoreKit Test, Apple sandbox and production transactions were not executed; owner-approved products/signing remain dependencies. The wallet is account/device-local and is not proven server-authoritative or cross-device.

No backend deployment, organization change, B integration, purchase configuration or real charge was performed. Broadcast/gift delivery remains unavailable as represented by the app. Native destructive logout/account-deletion success was not executed on retained identities; only cancellation/confirmation branches were covered. Actual self-deletion used disposable backend identities.

Physical devices, other runtimes/sizes, complete VoiceOver, sustained performance/leak profiling, exhaustive meal/date permutations, native interrupted-transport fault injection and individual playback of every publisher tutorial remain unexecuted. All six replays and one real publisher tutorial were exercised. Static checks, native tests, backend checks and production readiness are separate evidence categories.
