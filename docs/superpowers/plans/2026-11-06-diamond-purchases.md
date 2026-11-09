# Tilo Diamond Purchases Implementation Plan

**Goal:** Configure the seven owner-supplied consumables and two delegated additions, preserving StoreKit 2, account ownership and atomic delivery.

**Architecture:** Keep the current wallet and device/account ledger format. Extract the ledger's durable delivery operation for isolated tests. Add bounded, generation-scoped catalog loading and unavailable-tier presentation. Keep Apple catalog and local StoreKit schemes separate.

**Constraints:** iOS 16+, Swift 5, UIKit, iPhone only, English artifacts. Preserve com.toli.cooking and all existing private data. No backend Stage B, signing/account changes or remote registration is authorized by a screenshot. Use only Tilo UI Acceptance, 26399755-5402-48C1-A2C9-CA26E57505AB, for native checks. Do not reset the device or acceptance account wallet.

## Tasks

- [x] Add isolated purchase tests for durable delivery, duplicate transaction handling, arithmetic rejection, persistence failure and StoreKit consumables. Compile/run on the authorized simulator and record the initial missing-feature result.
- [x] Add nine exact product mappings; choose 16,800 diamonds at USD 29.99 and 42,000 at USD 69.99 with unique 16-letter IDs. Create a matching local StoreKit fixture and an English registration comparison sheet.
- [x] Extract durable ledger delivery without changing serialized fields or data location. Keep verification, account token, consumable and revocation checks before delivery, and finish only after persistence.
- [x] Add a bounded catalog request with generation invalidation, partial/empty/error/timeout phases, usable returned consumables, explicit retry and disabled missing tiers. Keep offers' prices exclusively from StoreKit.
- [x] Add a local StoreKit scheme and isolated hosted purchase-test target; retain TiloAppStore without a fixture. Use temporary ledgers and random account tokens for completed test transactions.
- [x] Update stale unconfigured-product rules, static checks and current product/payment docs. Preserve historical reports.
- [x] Generate metadata; run static checks, build and focused purchase tests. Install/launch the latest package before any wallet UI check and leave Tilo running. Record local StoreKit separately from unverified Apple sandbox/production.

## Review focus

Account switch or logout during a load must discard stale responses. Missing products cannot start payment. A failed save cannot publish credit or finish a transaction. Duplicate IDs never double-credit, including after reload. Cancellation/pending/unverified/unmapped transactions cannot credit. Tests must not write the acceptance member's wallet.

## Execution decision

Implement directly in the current workspace because all existing project files are untracked and must be preserved; do not create a partial checkout or commit unrelated user work. The owner's explicit request supplies the seven tiers and delegates the two additions, superseding older empty-ID instructions. Local tests do not establish Apple registration, server wallet authority or production availability.

## Outcome

All seven isolated purchase tests and one focused wallet UI test passed on the authorized simulator. Static verification passed 350 checks. Earlier compile/runner failures, the review-driven session reservation corrections, screenshots and Apple-side limitations are recorded in docs/runtime-acceptance/purchases-2026-11-06/report.md. No commits were made because the entire workspace was pre-existing untracked work.
