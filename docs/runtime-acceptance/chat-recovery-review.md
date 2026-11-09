# Chat recovery fixes

## Initial connection recovery

`ConversationController` exposes a manual **Retry connection** action after a transient initial membership, history, or relationship request fails. Retrying runs the same server authorization path with the composer disabled and history hidden until authorization succeeds. Explicit access denial and account changes still clear the conversation and do not expose a retry that bypasses authorization. Requests are user initiated; no automatic retry loop was introduced.

## Durable send identity

Pending sends use a separate account-scoped, conversation-scoped record through the existing atomic `ToliDraftStorage`. The record contains the fixed client ID, original composer text, transmitted body, optional photo token, prepared photo bytes, uploaded object path, and acknowledgement state. It is saved before upload; an uploaded path is saved before the message request. A persistence or decoding failure prevents a new message request.

Reopening restores an unresolved matching text/photo intent with the same client ID and uploaded path. Authorized history is checked for the client ID, and confirmed sends clear only the matching local text draft. Confirmed records retained after cleanup failures are reconciled without retransmission. If the message is outside the loaded history, retrying still uses the server's existing client-ID deduplication. Explicit photo removal or replacement clears its old retry record before changing the selected photo. Existing string-encoded text draft files remain unchanged and readable.

Acknowledgement reconciliation retains its durable tombstone while the existing draft writer finishes and fresh server preferences are loaded. A remote draft matching the acknowledged original text is cleared only through an acknowledged server write. A different remote draft is preserved, including in the composer and the last-synced value. Local cleanup removes only matching original text; a newer local draft survives. After every suspension, the account, access epoch, and saved pending client ID are checked before continuing, so an older operation does not remove a replacement pending record. Failed cloud cleanup leaves the tombstone available for explicit retry.

## Runtime reproduction and refresh correction

The root acceptance task reproduced a normal-send regression on the authorized `Toli UI Acceptance` simulator during the native chat test. The server accepted the message, but the composer remained populated and disabled with a reconciliation notice containing `Swift.CancellationError`. The app container retained an acknowledged pending record with client ID `00AB7A66-AFDC-45B4-8357-78D42B439E10`, matching that native send. This established that the pending identity had not changed or disappeared.

The failure came from reading shared `backend.conversations` after awaiting a refresh. Concurrent send/realtime refreshes could clear that shared array and supersede a request's publication. That request could then return normally while the shared array was still empty, causing the acknowledgement guard to mistake a missing shared snapshot for cancellation.

The root fix makes `refreshConversations` return its own `[Conversation]` result with `@discardableResult`. It no longer clears the published list before fetching. Only the latest request publishes to shared state, while each successful caller receives its own authoritative result; an account-generation change throws cancellation. Acknowledgement reconciliation and Chats reload consume that returned result rather than depending on shared publication timing.

## Validation boundary

The runtime failure above was observed by the root acceptance task; the correction has been inspected in source and still requires the root task's fresh compilation and native rerun. This document update did not compile, typecheck, launch, or operate a simulator, backend, legal object, or purchase configuration. The connection label and group-owner leaving guidance remain intact.

A disconnected initial open followed by network restoration and explicit retry, and acknowledgement-loss/reopen failure injection, remain untested. The normal-send regression and its retained acknowledged record do not establish those recovery scenarios. Final acceptance results belong in the root runtime test record.


## Subsequent executed regression

The root task subsequently compiled this correction. The connected incoming-message test passed in `toli-acknowledgement-and-picker-20261103-102051.xcresult`, normal text send/draft/pin/mute passed in `toli-corrected-major-flows-20261103-102426.xcresult`, and real photo upload, acknowledgement and reopened history passed in `toli-native-photo-flows-20261103-105047.xcresult`. The retained acknowledged record from the failing run was reconciled on ordinary entry. These actual normal-flow regressions supersede the earlier pending-rebuild status, while offline/lost-response fault injection remains unexecuted.
