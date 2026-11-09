# Publisher profiles and follow-first messaging

## Current contract — November 6, 2026

Live and recipe covers show an independent portrait target that opens their actual publisher profile. The remaining cover opens its recorded room or recipe. Author UUIDs come from the server projection and remain stable across discovery, profile works, relationships, safety menus and conversation membership. Publisher avatars appear only on Live/Recipes home covers. Profile works, personal collections and other recipe selection grids omit the repeated publisher avatar while retaining ordinary recipe entry.

The profile contains a compact identity header; Likes, Saves, Following and Followers; Follow, Message, Block and Report; and a direct grid of authored recipes. Before following, Message is absent and Follow fills the primary action area. An acknowledged follow changes the label to Following, shortens it and reveals Message alongside it. Unfollow reverses that composition. There is no Rooms category or replay lookup on the profile; transient broadcasts are not persistent works. State changes after server acknowledgement. At accessibility sizes, statistics use two columns, primary actions stack and works use one column. Personal editing remains in Settings, and the personal page retains its existing wallet entry.

## Reference findings

Read-only inspection covered Bibi's actual CreatorController, profileActions and AppStore.statistics(for:). Bibi uses a portrait/name header, four metrics, compact relationship/message/block controls, safety access and filtered direct works. Its current direct-message rule requires mutual following. The owner's explicit Tilo request supersedes that rule: each sender must follow the recipient. A recipient may read an incoming conversation but must follow its sender before replying. Unfollowing revokes future sends. Group invitations retain the separate mutual-follow rule.

The native profile, direct contact picker, text/photo composer permissions and server createDirect/sendMessage checks use this same one-way rule. Rechecks preserve current-account identity and block restrictions. Messages remain real persisted records with stable server/client IDs; there are no automatic replies, fake delivery receipts or claimed online staff.

## Editorial publishers and statistics

The owner explicitly authorized five persistent app-owned editorial kitchen identities after reviewing their names, purpose, illustrative portraits and lack of automated replies. The public inventory in BackendAPI/editorial-publishers.json binds them to the existing twelve recipes and six films. The trusted assignment updated only the allowlisted catalog IDs with null ownership, preserved stable content IDs and original source credits, and did not reuse the four existing real/acceptance profiles. Provisioning sessions were globally revoked and private temporary credentials removed after setup. Future operator access requires the owner's normal Auth administration; no operator credential is included in the app.

The owner also requested small simulated metrics. Each authorized editorial profile has a randomly seeded, server-managed baseline from 12 through 26 for the four displayed metrics. Baselines persist once and are separate from raw actual likes, saves, follows and followers. The client adds the baseline only for editorial profiles. No fake engagement or relationship rows were created. Actual interactions add to real counts without changing the seed; ordinary new members retain actual zero initial metrics and zero wallet credit. Relationship lists expose actual relationships, not invented members matching display baselines.

Portraits chef-01 through chef-05 are previously inspected, licensed cooking photographs with their existing authors, hashes and source pages in media-inventory.md and Assets/SourceMedia/manifest.json. They illustrate labeled Tilo editorial collections. The people depicted are not claimed to be registered authors, operators or endorsers. Original filmmaker credits remain attached to each replay.

## Backend and reusable workflow

Migration 20261106055750_editorial_publishers_and_follow_to_message adds private publisher projections and server-managed profile fields while preserving existing consent validation, safety visibility predicates, Auth binding and group rules. Clients retain SELECT-only table grants for profiles; updateProfile cannot set editorial keys or baselines. The recipe JSON function is STABLE because it now reads the publisher table. The videos projection includes the same publisher DTO. Existing clients tolerate the added JSON fields, and optional native publisher/baseline properties tolerate older records.

The installed ios-app-bulid skill now reads references/social-product-defaults.md before new social app implementation. It includes independent avatar navigation, complete profiles/works/actions, explicit full-stack messaging policy, safety, complete StoreKit wallet states and toolbar search behavior in the first design and acceptance plan. Tilo's five identities, cuisine/theme, numeric seeds and payment identifiers are scoped project choices, never reusable app defaults.

Initial native and finite backend evidence is recorded in runtime-acceptance/publisher-profiles-2026-11-06/report.md. The latest hidden-Message, recipe-only works and home-only avatar presentation has current evidence in runtime-acceptance/profile-presentation-2026-11-06/report.md. These changes do not change signing, product IDs, existing Apple/local wallet ledgers, legal PDFs or the Stage A boundary.
