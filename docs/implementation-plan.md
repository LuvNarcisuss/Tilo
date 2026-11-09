# Toli implementation plan

Historical plan recorded before the owner confirmed Tilo on November 6, 2026. Names and paths below describe the original implementation. Use README.md and AGENTS.md for the current project identity and layout.

**Goal:** Deliver the requested five-tab native cooking app with original shell artwork, real media and Supabase A services.

**Architecture:** UIKit navigation stacks, shared design components and typed asynchronous Supabase repositories. Catalog media is cloud-hosted; bundled assets are shell graphics and fonts.

**Spec:** docs/product-design.md

## Constraints

English project content; iOS 16+, Swift 5; iPhone only; owner authorization required for iOS build/typecheck/runtime tests. Preserve honest service boundaries and new-account empty state.

## Work packages

- [x] Create native project identity, shared UIKit design, entry and five-root navigation.
- [x] Generate, inspect and integrate raster icon atlas, app mark and paper backdrop; bundle licensed handwritten fonts.
- [x] Source and inspect real cooking videos and food photos, then upload all business media to dedicated Storage.
- [x] Deploy dedicated Supabase A schema, policies, anonymous Auth, realtime and legal PDFs; document exact deployment evidence.
- [x] Implement replay discovery/player, recipe detail/cook mode and Kitchen planning/groceries/timers.
- [x] Implement server-backed chat, profiles, safety, settings and configured-only wallet.
- [x] Generate Xcode metadata; inspect schema/permissions, resource references, English copy and whitespace. Record unperformed iOS validation.

## Review focus

Offline requests must preserve drafts without fabricating success. Blocking and membership changes must deny subsequent private access. Duplicate messages and purchases must not duplicate state. Large text/small screens must remain scrollable. Failed persistence must not publish balance or consent.

## Execution

Independent media, backend and social-screen tasks run in parallel as required by the dispatching-parallel-agents workflow. Root owns shared UI, cooking modules and final integration. iOS runtime tests are deferred by the owner's explicit global constraint; finite backend evidence and static inspection are not represented as app tests.

## Delivery boundary

Source, artwork, catalog/media deployment and finite backend checks are implemented. The current 139 Supabase service checks are recorded separately from the initial tely deployment; iOS build/runtime checks remain unauthorized. No Stage A completion or app runtime success is claimed. See verification.md and BackendAPI/integration.md for evidence.
