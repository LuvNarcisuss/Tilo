# Video preview acceptance

November 9, 2026, 11:51–12:02 Asia/Shanghai. This focused run covers the local video preview and its direct-chat entry.

The current workspace at `b5db2da` included uncommitted video preview changes. The Tilo scheme built successfully, and the new package was installed and launched on Tilo UI Acceptance, iPhone 17 Pro, iOS 26.0.1, `26399755-5402-48C1-A2C9-CA26E57505AB`. The ordinary build passed two hosted XCTest cases. Its server scenario skipped to preserve the existing session.

The server scenario ran on a separate temporary build of the same application source, with a unique Keychain service in the temporary copy. The test used two real disposable anonymous identities in the dedicated 139 Supabase project, `hdapofqufmxlghmcrftg`. The first attempt queried the navigation item before the test host had loaded the chat view. The corrected harness waited for presentation and passed on retry. A read-only server check found zero remaining Auth users, profiles, conversations and memberships for the four fixture identities created across both attempts.

| Scenario | Expected | Observed |
| --- | --- | --- |
| Direct chat before access validation and group chat | Direct entry disabled until validated; group entry absent | Passed on the ordinary build |
| Camera unavailable | Full-screen preview explains that the camera is unavailable; microphone and speaker indicators change from On to Off; End call dismisses | Passed on the ordinary build |
| Default and maximum accessibility text | Controls are visible or reachable by scrolling and remain at least 44 points high | Passed on the ordinary build. Reviewed all three screenshots |
| Authorized direct chat | Acknowledged sender follow enables the video button, opens the preview, and returns to the same conversation on hang-up | Passed with isolated real identities. The empty message history stayed empty |
| Unfollow | On reopening, the chat retains history and disables the video entry | Passed with isolated real identities. The interface displayed the follow requirement |
| Physical camera | Preview, front/back switching, permission prompt and actual capture lifecycle | Unverified. The designated simulator reported no camera |

The ordinary test log showed no Auto Layout conflict. The hosted integration retry logged a UIKit appearance-transition warning around its temporary window. The tested navigation assertions passed. The workspace project was then launched from Xcode with scheme Tilo. The installed bundle was verified as `com.toli.cooking`, iPhone-only, with the original Keychain service and without the temporary service.

The scope did not include a purchase or a wallet debit.

- [Ordinary build log](/private/tmp/tilo-video-acceptance.5CA7zNns/build.log)
- [Ordinary test result](/private/tmp/tilo-video-acceptance.5CA7zNns/VideoPreview.xcresult)
- [Isolated direct-chat test result](/private/tmp/tilo-video-acceptance.5CA7zNns/IsolatedVideoPreviewRetry.xcresult)
- [Default preview screenshot](/private/tmp/tilo-video-acceptance.5CA7zNns/screenshots/F1F2AC8A-774E-403A-A9C8-7919961ABAB3.png)
- [Maximum accessibility text controls](/private/tmp/tilo-video-acceptance.5CA7zNns/screenshots/4D9D2F77-ABF1-45D4-BDBD-96CE7511D6F4.png)
- [Disabled entry after unfollowing](/private/tmp/tilo-video-acceptance.5CA7zNns/isolated-screenshots/09454C58-1D23-416A-83D1-BEE3ED92E047.png)
