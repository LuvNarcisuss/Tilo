# Nightly diagnosis

The November 6 suite recorded an XCTest snapshot timeout in the Recipes root and a 910.6-second idle-notification gap in replay. Its test log contains one reported pass and one reported failure. Its partial result bundle has no finalized Info.plist. A current-source rebuild on November 9 uses the same application inputs and completes the isolated five-root probe in 66.237 seconds. The previous delay did not reproduce in that probe. The host load and interrupted result tracking leave the original cause unconfirmed.

The first current finite backend run recorded successful acknowledged writes and stable-ID deduplication before the authorized Postgres Changes receiver missed its 15-second observation window. A second run with fresh isolated identities passed all 77 checks, including live events and history reconciliation. Both sets of three disposable accounts were deleted and stale access was denied. The initial failure remains preserved. Its cause remains unconfirmed.

The acceptance runner now applies a 420-second per-method XCTest limit by default. The gift-history case samples existing receipt count before relaunch and requires the same count after reopening. The authorized QA ledger contains five retained receipts. The earlier assertion of exactly one receipt was tied to a historical fixture state.
