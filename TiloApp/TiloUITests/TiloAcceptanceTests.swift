import XCTest

/// Uses the ordinary app entry and the real configured backend. No session reset or login bypass.
final class TiloAcceptanceTests: XCTestCase {
    private var app: XCUIApplication!
    private let recipeTitle = "Tomato & basil spaghetti"

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication(bundleIdentifier: "com.toli.cooking")
        // Routine acceptance uses the established QA testing ledger, never the Apple wallet.
        app.launchEnvironment["TILO_STOREKIT_MODE"] = "local"
        app.launch()
    }

    override func tearDownWithError() throws {
        if let run = testRun, run.failureCount > 0 {
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.name = "Failure accessibility hierarchy"
            hierarchy.lifetime = .keepAlways
            add(hierarchy)
            capture("Failure screen")
        }
        // The acceptance account, Keychain and foreground app remain available for inspection.
    }

    func test51HalfHeightGiftSheetKeepsVideoVisibleAndWalletReturnsCompact() {
        app.terminate(); app.launchEnvironment["TILO_STOREKIT_MODE"] = "local"; app.launch()
        enterHome(); selectTab("live")
        let room = app.buttons["live-room-card-cooking-01"]
        XCTAssertTrue(room.waitForExistence(timeout: 30)); reveal(room); room.tap(); tap("Send a gift")
        let panel = app.otherElements["gift-panel"], send = app.buttons["gift.send"]
        XCTAssertTrue(panel.waitForExistence(timeout: 15))
        waitUntil("Compact gift controls load", timeout: 25) { send.isEnabled }
        XCTAssertLessThanOrEqual(panel.frame.height, app.frame.height * 0.56)
        XCTAssertGreaterThanOrEqual(panel.frame.minY, app.frame.height * 0.44)
        XCTAssertTrue(send.isHittable)
        for id in ["warm-thanks", "kitchen-cheer", "chefs-star"] { XCTAssertTrue(app.buttons["gift.choice." + id].isHittable) }
        XCTAssertTrue(app.buttons["gift.quantity.10"].isHittable)
        XCTAssertFalse(app.otherElements["room-gift-effect"].exists)
        assertReplayAdvances()
        capture("Half-height gift panel leaves cooking video visible")
        let original = app.buttons["gift.balance"].value as? String
        let giftTop = app.navigationBars["Send a gift"].frame.minY
        app.buttons["gift.balance"].tap()
        XCTAssertTrue(app.navigationBars["Wallet"].waitForExistence(timeout: 15))
        waitUntil("Wallet expands for history and prices", timeout: 10) { self.app.navigationBars["Wallet"].frame.minY < giftTop - 100 }
        back()
        waitUntil("Returning to gifts restores half height", timeout: 10) { panel.exists && panel.frame.height <= self.app.frame.height * 0.56 }
        waitUntil("Gift recipient is revalidated", timeout: 25) { send.isEnabled }
        XCTAssertEqual(app.buttons["gift.balance"].value as? String, original)
        send.tap(); XCTAssertTrue(app.alerts["Send gift?"].waitForExistence(timeout: 5)); app.alerts.buttons["Cancel"].tap()
        XCTAssertFalse(app.otherElements["room-gift-effect"].exists)
        XCTAssertEqual(app.buttons["gift.balance"].value as? String, original)
        capture("Wallet return preserves compact gifts and cancellation has no effect")
    }

    func test52HalfHeightGiftSheetAccessibilityActionsRemainReachable() {
        app.terminate(); app.launchEnvironment["TILO_STOREKIT_MODE"] = "local"
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch(); enterHome(); selectTab("live")
        let room = app.buttons["live-room-card-cooking-01"]
        XCTAssertTrue(room.waitForExistence(timeout: 30)); reveal(room); room.tap(); tap("Send a gift")
        let send = app.buttons["gift.send"], panel = app.otherElements["gift-panel"]
        XCTAssertTrue(send.waitForExistence(timeout: 15)); waitUntil("Accessible send action loads", timeout: 25) { send.isEnabled }
        XCTAssertLessThanOrEqual(panel.frame.height, app.frame.height * 0.56)
        XCTAssertTrue(send.isHittable)
        let gift = app.buttons["gift.choice.chefs-star"]
        reveal(gift); gift.tap()
        XCTAssertEqual(gift.value as? String, "Selected")
        XCTAssertTrue(send.isHittable)
        capture("Accessible compact gift choices scroll above a retained send action")
        app.navigationBars.buttons["Close"].firstMatch.tap()
        app.terminate(); app.launchArguments = []; app.launch()
    }

    func test48RoomGiftSendingControlsAreAvailable() {
        app.terminate()
        app.launchEnvironment["TILO_STOREKIT_MODE"] = "local"
        app.launch()
        enterHome()
        selectTab("live")
        let room = app.buttons["live-room-card-cooking-01"]
        XCTAssertTrue(room.waitForExistence(timeout: 30)); reveal(room); room.tap()
        tap("Send a gift")
        XCTAssertTrue(app.navigationBars["Send a gift"].waitForExistence(timeout: 15))
        let send = app.buttons["Send gift"]
        XCTAssertTrue(send.waitForExistence(timeout: 15))
        waitUntil("Funded local wallet can send a cooking gift", timeout: 25) { send.isEnabled }
        let balance = app.buttons["gift.balance"].value as? String
        XCTAssertEqual(app.staticTexts["gift.total"].value as? String, "10")
        app.buttons["gift.quantity.5"].tap()
        XCTAssertEqual(app.staticTexts["gift.total"].value as? String, "50")
        XCTAssertEqual(app.buttons["gift.quantity.5"].value as? String, "Selected")
        app.buttons["gift.choice.kitchen-cheer"].tap()
        XCTAssertEqual(app.staticTexts["gift.total"].value as? String, "250")
        app.buttons["gift.send"].tap()
        let confirmation = app.alerts["Send gift?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Cancel"].tap()
        XCTAssertEqual(app.buttons["gift.balance"].value as? String, balance)
        capture("Room gift sending is available")
    }

    func test49LocalGiftDebitHistoryAndRelaunchPersistence() throws {
        #if TILO_GIFT_DEBIT_ACCEPTANCE
        let authorized = true
        #else
        let authorized = false
        #endif
        try XCTSkipUnless(authorized, "Requires explicit one-gift debit authorization and TILO_GIFT_DEBIT_ACCEPTANCE; routine suites must not spend existing credit.")
        app.terminate(); app.launchEnvironment["TILO_STOREKIT_MODE"] = "local"; app.launch()
        enterHome(); selectTab("live")
        let room = app.buttons["live-room-card-cooking-01"]
        XCTAssertTrue(room.waitForExistence(timeout: 30)); reveal(room); room.tap(); tap("Send a gift")
        let send = app.buttons["gift.send"]
        XCTAssertTrue(send.waitForExistence(timeout: 15))
        waitUntil("Gift recipient and local wallet are ready", timeout: 25) { send.isEnabled }
        XCTAssertEqual(app.staticTexts["gift.scope"].value as? String, "localStoreKit")
        let before = Int(app.buttons["gift.balance"].value as? String ?? "")!
        XCTAssertGreaterThanOrEqual(before, 10, "Use only the existing isolated StoreKit-testing credit")
        send.tap()
        let confirmation = app.alerts["Send gift?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5)); confirmation.buttons["Send"].tap()
        waitUntil("Gift saves one exact debit before displaying success", timeout: 25) {
            self.app.buttons["gift.balance"].value as? String == String(before - 10)
                && self.app.staticTexts["gift.status"].label.contains("Recorded 1 × Warm thanks")
        }
        capture("Recorded local gift updates the isolated wallet exactly once")
        tap("gift.balance")
        XCTAssertTrue(app.staticTexts["wallet.balance"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["wallet.balance"].value as? String, String(before - 10))
        let history = app.staticTexts["1 × Warm thanks · Tilo Pasta Table"].firstMatch
        reveal(history); XCTAssertTrue(history.exists)
        capture("Gift debit appears in persistent wallet history")
        back()
        let close = app.navigationBars.buttons["Close"].firstMatch
        XCTAssertTrue(close.waitForExistence(timeout: 5)); close.tap()
        XCTAssertTrue(app.staticTexts["room-status"].label.contains("Gift recorded"))
        assertReplayAdvances()
        app.terminate(); app.launch(); enterHome(); selectTab("live")
        XCTAssertTrue(room.waitForExistence(timeout: 30)); reveal(room); room.tap(); tap("Send a gift")
        XCTAssertTrue(app.buttons["gift.balance"].waitForExistence(timeout: 15))
        waitUntil("Gift balance survives process relaunch", timeout: 25) {
            self.app.buttons["gift.balance"].value as? String == String(before - 10)
        }
        capture("Gift spending survives relaunch without duplicate debit")
    }

    func test50RecordedGiftHistoryAndBalanceSurviveRelaunchWithoutSpending() {
        app.terminate(); app.launchEnvironment["TILO_STOREKIT_MODE"] = "local"; app.launch()
        enterHome(); selectTab("live")
        let room = app.buttons["live-room-card-cooking-01"]
        XCTAssertTrue(room.waitForExistence(timeout: 30)); reveal(room); room.tap(); tap("Send a gift")
        let balance = app.buttons["gift.balance"]
        XCTAssertTrue(balance.waitForExistence(timeout: 15))
        waitUntil("Previously funded gift wallet loads", timeout: 25) { (Int(balance.value as? String ?? "") ?? 0) > 0 }
        let recordedBalance = balance.value as? String
        assertReplayAdvances()
        balance.tap()
        XCTAssertTrue(app.staticTexts["wallet.balance"].waitForExistence(timeout: 15))
        XCTAssertEqual(app.staticTexts["wallet.balance"].value as? String, recordedBalance)
        let history = app.staticTexts["1 × Warm thanks · Tilo Pasta Table"].firstMatch
        reveal(history); XCTAssertTrue(history.exists)
        XCTAssertTrue(app.staticTexts["−10 Diamonds"].exists)
        let giftRows = app.otherElements.matching(NSPredicate(format: "identifier BEGINSWITH %@", "wallet.gift."))
        let recordedGiftCount = giftRows.count
        XCTAssertGreaterThan(recordedGiftCount, 0)
        capture("Latest gift debit is reachable in chronological wallet activity")
        back()
        app.navigationBars.buttons["Close"].firstMatch.tap()
        assertReplayAdvances()
        app.terminate(); app.launch(); enterHome(); selectTab("live")
        XCTAssertTrue(room.waitForExistence(timeout: 30)); reveal(room); room.tap(); tap("Send a gift")
        XCTAssertTrue(app.buttons["gift.balance"].waitForExistence(timeout: 15))
        waitUntil("Existing gift balance survives relaunch without another debit", timeout: 25) {
            self.app.buttons["gift.balance"].value as? String == recordedBalance
        }
        capture("Recorded gift balance persists without repeat spending")
        app.buttons["gift.balance"].tap()
        XCTAssertTrue(app.staticTexts["wallet.balance"].waitForExistence(timeout: 15))
        waitUntil("Previously recorded gift history reloads", timeout: 15) {
            giftRows.count == recordedGiftCount
        }
    }

    func test45PublisherAvatarsOpenProfilesIndependently() {
        enterHome()
        selectTab("live")
        let roomAvatar = app.buttons["publisher-avatar-cooking-01"]
        XCTAssertTrue(roomAvatar.waitForExistence(timeout: 30))
        capture("Live cards with publisher avatars")
        reveal(roomAvatar); roomAvatar.tap()
        XCTAssertTrue(app.staticTexts["Tilo Pasta Table"].waitForExistence(timeout: 25))
        XCTAssertFalse(app.textFields["Room message"].exists, "Avatar must open the profile rather than enter playback")
        XCTAssertTrue(app.buttons["profile-follow"].exists)
        XCTAssertEqual(app.buttons["profile-message"].exists, app.buttons["profile-follow"].label == "Following")
        XCTAssertFalse(app.buttons["Rooms"].exists)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "live-room-card-")).firstMatch.exists)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "publisher-avatar-")).firstMatch.exists)
        XCTAssertTrue(app.buttons["recipe-card-recipe-01"].exists)
        XCTAssertFalse(app.buttons["recipe-card-recipe-02"].exists, "Only this publisher's recipes belong in their works")
        XCTAssertTrue(app.buttons["Report profile"].exists)
        XCTAssertTrue(app.buttons["Block cook"].exists)
        capture("Publisher profile statistics and compact actions")
        tap("Report profile")
        XCTAssertTrue(app.navigationBars["Report profile"].waitForExistence(timeout: 10))
        capture("Publisher report form")
        back()
        tap("Block cook")
        XCTAssertTrue(app.alerts["Block this cook?"].waitForExistence(timeout: 10))
        app.alerts.buttons["Cancel"].tap()
        back()
        selectTab("recipes")
        let recipeAvatar = app.buttons["publisher-avatar-recipe-01"]
        XCTAssertTrue(recipeAvatar.waitForExistence(timeout: 30))
        capture("Recipe covers with independent publisher targets")
        reveal(recipeAvatar); recipeAvatar.tap()
        XCTAssertTrue(app.staticTexts["Tilo Pasta Table"].waitForExistence(timeout: 25))
        XCTAssertFalse(app.buttons["Start cooking"].exists)
        back()
        let cover = app.buttons["recipe-card-recipe-01"]
        reveal(cover); cover.tap()
        XCTAssertTrue(app.buttons["Start cooking"].waitForExistence(timeout: 30))
        capture("Recipe cover preserves content navigation")
        back()
    }

    func test47PublisherFollowEnablesMessageAfterAcknowledgement() {
        enterHome()
        selectTab("recipes")
        let avatar = app.buttons["publisher-avatar-recipe-01"]
        XCTAssertTrue(avatar.waitForExistence(timeout: 30)); reveal(avatar); avatar.tap()
        let follow = app.buttons["profile-follow"], message = app.buttons["profile-message"]
        XCTAssertTrue(follow.waitForExistence(timeout: 25))
        let wasFollowing = follow.label == "Following"
        let followers = app.buttons["profile-metric-followers"]
        let originalCount = Int(followers.label.components(separatedBy: " ").first ?? "")!
        if wasFollowing {
            follow.tap()
            waitUntil("Unfollow acknowledgement hides private messaging", timeout: 25) { !message.exists && follow.label == "Follow" }
        }
        XCTAssertFalse(message.exists)
        let expandedFollowWidth = follow.frame.width
        capture("Unfollowed profile has one expanded Follow action and no Message")
        follow.tap()
        waitUntil("Server follow acknowledgement reveals private messaging", timeout: 25) { message.exists && message.isEnabled && follow.label == "Following" }
        XCTAssertLessThan(follow.frame.width, expandedFollowWidth - 40, "Following shrinks to make room for Message")
        XCTAssertEqual(followers.label, "\(originalCount + (wasFollowing ? 0 : 1)) Followers")
        capture("Acknowledged follow enables Message and updates actual follower count")
        if !wasFollowing {
            follow.tap()
            waitUntil("Original relationship restored after acceptance", timeout: 25) { !message.exists && follow.label == "Follow" }
            XCTAssertEqual(follow.frame.width, expandedFollowWidth, accuracy: 1)
        }
        back()
        reveal(avatar); avatar.tap()
        XCTAssertTrue(app.buttons["profile-follow"].waitForExistence(timeout: 25))
        XCTAssertEqual(app.buttons["profile-message"].exists, wasFollowing)
        XCTAssertEqual(app.buttons["profile-metric-followers"].label, "\(originalCount) Followers")
        capture("Profile reload preserves stable metrics and original relationship")
        back()
    }

    func test46PublisherProfileAccessibilityLayout() {
        app.terminate()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        enterHome()
        selectTab("recipes")
        let avatar = app.buttons["publisher-avatar-recipe-01"]
        XCTAssertTrue(avatar.waitForExistence(timeout: 30))
        reveal(avatar); avatar.tap()
        XCTAssertTrue(app.staticTexts["Tilo Pasta Table"].waitForExistence(timeout: 25))
        capture("Accessible publisher identity and statistics")
        let follow = app.buttons["profile-follow"]
        reveal(follow)
        XCTAssertTrue(follow.isHittable)
        XCTAssertEqual(app.buttons["profile-message"].exists, follow.label == "Following")
        if app.buttons["profile-message"].exists {
            reveal(app.buttons["profile-message"])
            XCTAssertTrue(app.buttons["profile-message"].isHittable)
        }
        XCTAssertFalse(app.buttons["Rooms"].exists)
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "publisher-avatar-")).firstMatch.exists)
        capture("Accessible publisher actions")
        back()
        app.terminate()
        app.launchArguments = []
        app.launch()
    }

    func test00ConsentFiveRootsAndProfilePersistence() {
        enterHome(checkConsentGate: true)
        for tab in ["live", "recipes", "kitchen", "chats", "me"] {
            selectTab(tab)
            waitForRootContent(tab)
            capture("Root " + tab)
        }
        openProfileEditor()
        let name = app.textFields["Display name"]
        let usernameField = app.textFields["Username"]
        let previousUsername = inputValue(usernameField)
        let acceptanceUsername = previousUsername.hasPrefix("cook_")
            ? "toli_acceptance_" + previousUsername.dropFirst(5).prefix(8)
            : previousUsername
        let biography = "Toli acceptance profile " + UUID().uuidString.lowercased()
        replace(name, with: "Toli Acceptance Cook")
        replace(usernameField, with: acceptanceUsername)
        replace(app.textViews["About your kitchen"], with: biography)
        tap("Save profile")
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout:30))
        back()
        XCTAssertTrue(app.staticTexts["Toli Acceptance Cook"].waitForExistence(timeout: 30))
        capture("Saved acceptance profile")
        openProfileEditor()
        XCTAssertEqual(app.textFields["Display name"].value as? String, "Toli Acceptance Cook")
        XCTAssertEqual(app.textFields["Username"].value as? String, acceptanceUsername)
        XCTAssertEqual(app.textViews["About your kitchen"].value as? String, biography)
        back()
    }

    func test01ReplayPlaybackControlsAndLinkedRecipe() {
        enterHome()
        selectTab("live")
        let enter = app.buttons["Enter kitchen"].firstMatch
        XCTAssertTrue(enter.waitForExistence(timeout: 30))
        reveal(enter)
        enter.tap()
        XCTAssertTrue(app.buttons["Send a gift"].waitForExistence(timeout: 15))
        waitUntil("Replay leaves loading state", timeout: 30) {
            !self.app.staticTexts["Loading cooking replay…"].exists
        }
        XCTAssertFalse(app.staticTexts["Replay could not play. Open More to retry."].exists)
        assertReplayAdvances()
        capture("Cooking replay playback")
        let reaction = app.buttons["Like replay"]
        XCTAssertEqual(reaction.value as? String, "0 reactions this visit")
        for _ in 0..<6 { reaction.tap() }
        waitUntil("Every repeated room reaction is acknowledged", timeout:30) {
            reaction.value as? String == "6 reactions this visit"
        }
        XCTAssertFalse(app.buttons["Unlike replay"].exists)
        capture("Repeatable room hearts retain the shared dark control style")
        XCTAssertFalse(app.buttons["Pause"].exists)
        XCTAssertFalse(app.buttons["Play"].exists)
        XCTAssertFalse(app.buttons["Comments"].exists)
        XCTAssertTrue(app.textFields["Room message"].exists)
        tap("Send a gift")
        XCTAssertTrue(app.navigationBars["Send a gift"].waitForExistence(timeout:10))
        waitUntil("Gift controls become available for this publisher", timeout: 25) { self.app.buttons["gift.send"].isEnabled }
        assertReplayAdvances()
        capture("Gift selection while cooking continues")
        let closeGifts = app.navigationBars.buttons["Close"].firstMatch
        XCTAssertTrue(closeGifts.waitForExistence(timeout:5)); closeGifts.tap()
        backgroundAndReactivate()
        assertReplayAdvances()
        capture("Automatic cooking playback after foreground")
        tap("More")
        XCTAssertTrue(app.buttons["Retry playback"].waitForExistence(timeout: 5))
        capture("Replay actions")
        tap("Retry playback")
        waitUntil("Retried replay leaves loading state", timeout: 30) {
            !self.app.staticTexts["Loading cooking replay…"].exists
        }
        XCTAssertFalse(app.staticTexts["Replay could not play. Open More to retry."].exists)
        assertReplayAdvances()
        tap("More")
        tap("Recipe")
        XCTAssertTrue(app.buttons["Start cooking"].waitForExistence(timeout: 30))
        capture("Replay linked recipe")
        let recipeClose = app.navigationBars.buttons["Close"].firstMatch
        XCTAssertTrue(recipeClose.waitForExistence(timeout: 10))
        XCTAssertTrue(recipeClose.isHittable)
        recipeClose.tap()
        waitUntil("Linked recipe dismisses back to the replay controls", timeout: 10) {
            !self.app.buttons["Start cooking"].isHittable && self.app.buttons["Send a gift"].isHittable
        }
        tap("Close")
        XCTAssertTrue(app.buttons["tab-live"].waitForExistence(timeout: 10))
    }

    func test02RecipesSearchScaleCollectionsAndCookSteps() {
        enterHome()
        selectTab("recipes")
        openRecipeSearch()
        let search = app.searchFields["Search recipes or ingredients"]
        replace(search, with: "acceptance_missing_ingredient")
        dismissSearchKeyboard()
        XCTAssertTrue(app.staticTexts["A fresh start"].waitForExistence(timeout: 20))
        replace(search, with: "Tomato")
        dismissSearchKeyboard()
        let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", recipeTitle + ",")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 25))
        reveal(card)
        capture("Recipe search results")
        card.tap()
        tap("Ingredient prep")
        let servings = app.staticTexts["2 servings"]
        reveal(servings)
        XCTAssertTrue(servings.exists)
        tap("+")
        XCTAssertTrue(app.staticTexts["3 servings"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["300 g  Spaghetti"].exists)
        capture("Scaled recipe ingredients")
        tap("−")
        XCTAssertTrue(app.staticTexts["2 servings"].waitForExistence(timeout: 5))
        let save = app.buttons["Save"]
        if save.exists {
            tap("Save")
            XCTAssertTrue(app.buttons["Saved"].waitForExistence(timeout: 20))
        }
        XCTAssertTrue(app.buttons["Saved"].exists)
        let like = app.buttons["Like"]
        if like.exists {
            tap("Like")
            XCTAssertTrue(app.buttons["Liked"].waitForExistence(timeout: 20))
        }
        XCTAssertTrue(app.buttons["Liked"].exists)
        tap("Start cooking")
        XCTAssertTrue(app.staticTexts["STEP 1 OF 5"].waitForExistence(timeout: 10))
        tap("Next")
        XCTAssertTrue(app.staticTexts["STEP 2 OF 5"].waitForExistence(timeout: 5))
        tap("Previous")
        XCTAssertTrue(app.staticTexts["STEP 1 OF 5"].waitForExistence(timeout: 5))
        capture("Cook along first step")
        for step in 2...5 {
            tap("Next")
            XCTAssertTrue(app.staticTexts["STEP \(step) OF 5"].waitForExistence(timeout: 5))
        }
        tap("Finish")
        XCTAssertTrue(app.buttons["Start cooking"].waitForExistence(timeout: 5))
        back()
        selectTab("me")
        tap("Saved")
        XCTAssertTrue(card.waitForExistence(timeout: 25))
        capture("Server saved recipe collection")
        tap("Liked")
        XCTAssertTrue(card.waitForExistence(timeout: 25))
    }

    func test03KitchenMealGroceriesAndTimer() {
        enterHome()
        selectTab("kitchen")
        XCTAssertTrue(app.buttons["Kitchen timer"].waitForExistence(timeout: 25))
        tap("Kitchen timer")
        tap("Reset")
        XCTAssertTrue(app.staticTexts["10 minutes and 0 seconds remaining"].exists)
        tap("Start timer")
        waitUntil("Kitchen timer advances", timeout: 8) {
            self.app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "9 minutes and")).firstMatch.exists
        }
        tap("Pause")
        capture("Paused kitchen timer")
        tap("Reset")
        XCTAssertTrue(app.staticTexts["10 minutes and 0 seconds remaining"].exists)
        back()
        let choose = app.buttons["Choose a recipe"].firstMatch
        if choose.exists {
            reveal(choose)
            choose.tap()
            let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", recipeTitle + ",")).firstMatch
            XCTAssertTrue(card.waitForExistence(timeout: 25))
            reveal(card)
            card.tap()
            XCTAssertTrue(app.buttons["Open recipe"].firstMatch.waitForExistence(timeout: 20))
        }
        let open = app.buttons["Open recipe"].firstMatch
        reveal(open)
        open.tap()
        tap("Ingredient prep")
        tap("Add ingredients to shopping list")
        XCTAssertTrue(app.alerts["Shopping list updated"].waitForExistence(timeout: 20))
        tap("OK")
        back()
        tap("Add an item")
        let alert = app.alerts["Add to your list"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.textFields["Ingredient or item"].tap()
        alert.textFields["Ingredient or item"].typeText("Acceptance pantry lemons")
        alert.textFields["Quantity, such as 2 lemons"].tap()
        alert.textFields["Quantity, such as 2 lemons"].typeText("2 lemons")
        alert.buttons["Add"].tap()
        let lemons = app.staticTexts["Acceptance pantry lemons"]
        XCTAssertTrue(lemons.waitForExistence(timeout: 20))
        reveal(lemons)
        capture("Server shopping list and meal plan")
        let pickup = app.buttons["Pick up"].firstMatch
        reveal(pickup)
        pickup.tap()
        XCTAssertTrue(app.buttons["Done"].firstMatch.waitForExistence(timeout: 20))
        selectTab("live")
        selectTab("kitchen")
        XCTAssertTrue(lemons.waitForExistence(timeout: 25))
        reveal(lemons)
        capture("Reloaded shopping list")
    }

    func test04ChatsDirectoryWalletAndAgreements() {
        enterHome()
        selectTab("chats")
        XCTAssertTrue(app.staticTexts["Good food. Great company."].waitForExistence(timeout: 15))
        tap("New conversation")
        XCTAssertTrue(app.buttons["Find people"].waitForExistence(timeout: 5))
        capture("New conversation actions")
        tap("Find people")
        XCTAssertTrue(app.staticTexts["Make room at the table"].waitForExistence(timeout: 10))
        capture("Member directory")
        back()
        selectTab("me")
        tap("My wallet")
        let balance = app.staticTexts["wallet.balance"]
        XCTAssertTrue(balance.waitForExistence(timeout: 15))
        let originalBalance = balance.value as? String
        let firstPackage = app.buttons["wallet.package.400"]
        reveal(firstPackage)
        XCTAssertTrue(firstPackage.exists)
        let refresh = app.buttons["wallet.refresh"]
        reveal(refresh)
        waitUntil("Catalog finishes with an actionable result", timeout: 35) { refresh.isEnabled }
        XCTAssertTrue(app.buttons["wallet.package.63700"].exists)
        XCTAssertEqual(balance.value as? String, originalBalance, "Catalog inspection must not alter retained QA credit")
        capture("Configured wallet with actual App Store availability")
        back()
        tap("Settings")
        tap("Blocked cooks")
        XCTAssertTrue(app.staticTexts["A comfortable kitchen"].waitForExistence(timeout: 15))
        back()
        tap("Media credits")
        capture("Cooking media source credits")
        back()
        for title in ["Terms of Service", "Privacy Policy"] {
            tap(title)
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout: 10))
            waitUntil(title + " download finishes", timeout: 30) {
                !self.app.staticTexts["Loading agreement…"].exists
            }
            XCTAssertFalse(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "agreement could not")).firstMatch.exists)
            capture(title)
            back()
        }
        back()
        capture("Final Me root")
    }

    func test05ProfilePhotoPickerInspection() {
        enterHome()
        selectTab("me")
        openProfileEditor()
        tap("Choose profile photo")
        let cancel = app.buttons["Cancel"].firstMatch
        let picker = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in self.loadedPhotoPicker() != nil }, object: nil)
        let result = XCTWaiter.wait(for: [picker], timeout: 45)
        capturePhotoPickerHierarchies()
        captureHierarchy("Native profile photo picker hierarchy after bounded presentation wait")
        capture("Native profile photo picker after bounded presentation wait")
        XCTAssertEqual(result, .completed, "The native picker must expose the actual imported cooking image; a Cancel-only loading screen is not selection evidence")
        if cancel.exists && cancel.isHittable { cancel.tap() }
    }

    func test06RealReplayAndRecipeComments() {
        enterHome()
        selectTab("live")
        tap("Enter kitchen")
        let replayComment = "Kitchen note " + String(UUID().uuidString.prefix(8))
        replace(app.textFields["Room message"],with:replayComment)
        tap("Send room message")
        let roomLine = app.staticTexts.matching(NSPredicate(format:"label CONTAINS %@",replayComment)).firstMatch
        XCTAssertTrue(roomLine.waitForExistence(timeout:25))
        XCTAssertEqual(app.textFields["Room message"].value as? String,"Say something…")
        capture("Server acknowledged room message bubble")
        tap("Close")
        tap("Enter kitchen")
        XCTAssertTrue(roomLine.waitForExistence(timeout:25),"The real server message must survive closing and reopening the room")
        capture("Persisted room message after reopening")
        tap("Close")
        selectTab("recipes")
        let card = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", recipeTitle + ",")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 25))
        reveal(card)
        card.tap()
        tap("Recipe options")
        tap("Join the recipe conversation")
        let recipeComment = "Toli acceptance recipe comment " + UUID().uuidString.lowercased()
        replace(app.textViews["Your comment"], with: recipeComment)
        tap("Send comment")
        let recipeBody = app.staticTexts[recipeComment]
        XCTAssertTrue(recipeBody.waitForExistence(timeout: 25))
        reveal(recipeBody)
        capture("Server acknowledged real recipe comment")
        back()
        back()
    }

    func test07NativeReplayShareInspection() {
        enterHome()
        selectTab("live")
        tap("Enter kitchen")
        tap("Share this kitchen")
        let copy = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Copy")).firstMatch
        let cancel = app.buttons["Cancel"].firstMatch
        let share = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            (copy.exists && copy.isHittable) || (cancel.exists && cancel.isHittable)
        }, object: nil)
        let result = XCTWaiter.wait(for: [share], timeout: 20)
        captureHierarchy("Native replay share hierarchy after bounded presentation wait")
        capture("Native replay share sheet after bounded presentation wait")
        XCTAssertEqual(result, .completed, "The actual native share sheet must expose its controls; the background replay is not share evidence")
        if cancel.exists && cancel.isHittable { cancel.tap() }
    }

    func test08WelcomePrimaryActionVisible() {
        let login = app.buttons["Log in"]
        XCTAssertTrue(login.waitForExistence(timeout: 15))
        capture("Welcome before scrolling")
        XCTAssertTrue(app.frame.contains(login.frame), "The complete primary login action must be visible on ordinary cold launch without scrolling")
        XCTAssertTrue(login.isHittable)
        login.tap()
        XCTAssertTrue(app.alerts["Before we cook"].waitForExistence(timeout: 5))
        capture("Unchecked welcome agreement gate")
        app.alerts.buttons["Disagree"].tap()
        XCTAssertTrue(login.exists)
        XCTAssertFalse(app.buttons["tab-live"].exists)
    }

    /// May also run after the coordinator changes the dedicated simulator's Dynamic Type size.
    func test09AllRootsLayout() {
        enterHome()
        for name in ["live", "recipes", "kitchen", "chats", "me"] {
            selectTab(name)
            waitForRootContent(name)
            for dockName in ["live", "recipes", "kitchen", "chats", "me"] {
                let tab = app.buttons["tab-" + dockName]
                XCTAssertTrue(tab.exists && tab.isHittable)
                XCTAssertTrue(app.frame.contains(tab.frame), "Each root destination must remain fully inside the viewport")
            }
            capture("Root layout " + name)
        }
    }

    func test10RealProfilePhotoUpload() {
        enterHome()
        selectTab("me")
        openProfileEditor()
        tap("Choose profile photo")
        selectSeededCookingPhoto {
            self.app.images["profile-photo-preview"].value as? String == "Selected profile photo"
        }
        capture("Selected actual cooking profile photo")
        tap("Save profile")
        XCTAssertTrue(app.buttons["Edit profile"].waitForExistence(timeout: 30))
        capture("Server saved cooking profile photo")
        openProfileEditor()
        let preview = app.images["profile-photo-preview"]
        XCTAssertTrue(preview.waitForExistence(timeout: 10))
        XCTAssertEqual(preview.value as? String, "Current profile photo")
        capture("Reloaded server profile photo")
        back()
    }

    func test11RealChatPhotoUploadAndRender() {
        enterHome()
        openAcceptancePartner()
        tap("Message")
        let composer = app.textViews["Message"]
        let caption = "Toli acceptance cooking photo " + UUID().uuidString.lowercased()
        replace(composer, with: caption)
        tap("Attach photo")
        selectSeededCookingPhoto {
            self.app.images["Selected message photo"].exists
        }
        capture("Selected actual cooking message photo")
        tap("Send message")
        XCTAssertTrue(messageContaining(caption).waitForExistence(timeout: 30))
        waitUntil("Photo send acknowledgement clears composer and attachment", timeout: 25) {
            self.inputValue(composer).isEmpty && !self.app.images["Selected message photo"].exists
        }
        let photo = app.images["Photo attached to message"].firstMatch
        XCTAssertTrue(photo.waitForExistence(timeout: 30))
        reveal(photo)
        waitUntil("Private cooking message photo download finishes", timeout: 30) {
            !self.app.staticTexts["Loading photo…"].exists && !self.app.buttons["Retry photo"].exists
        }
        capture("Real private cooking message photo rendered")
        back()
        tap("Message")
        XCTAssertTrue(messageContaining(caption).waitForExistence(timeout: 30))
        XCTAssertTrue(photo.waitForExistence(timeout: 30))
        reveal(photo)
        capture("Reloaded real photo message history")
    }

    func test12RealRecipePhotoPublishEditAndDelete() {
        enterHome()
        selectTab("recipes")
        tap("Write a recipe")
        let title = "Toli acceptance pasta " + UUID().uuidString.prefix(8).lowercased()
        replace(app.textFields["Recipe name"], with: title)
        replace(app.textViews["Recipe introduction"], with: "A simple tomato pasta prepared for the isolated Toli acceptance kitchen.")
        replace(app.textFields["Ingredient name"].firstMatch, with: "Spaghetti")
        replace(app.textFields["Ingredient amount"].firstMatch, with: "200")
        replace(app.textFields["Ingredient unit"].firstMatch, with: "g")
        replace(app.textViews["Recipe method"], with: "Boil the spaghetti according to the packet instructions.\n\nDrain and toss with warm tomato sauce before serving.")
        tap("Choose a recipe photo")
        selectSeededCookingPhoto {
            self.app.images["recipe-photo-preview"].value as? String == "Selected recipe photo"
        }
        capture("Original acceptance recipe with chosen cooking photo")
        tap("Publish recipe")
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 40))
        XCTAssertTrue(app.buttons["Recipe options"].waitForExistence(timeout: 30))
        capture("Real server published photo recipe")
        tap("Recipe options")
        tap("Edit recipe")
        let revised = title + " revised"
        replace(app.textFields["Recipe name"], with: revised)
        tap("Save changes")
        XCTAssertTrue(app.staticTexts[revised].waitForExistence(timeout: 40))
        capture("Server updated owned recipe")
        tap("Recipe options")
        tap("Delete recipe")
        XCTAssertTrue(app.alerts["Delete this recipe?"].waitForExistence(timeout: 5))
        capture("Owned acceptance recipe deletion confirmation")
        app.alerts.buttons["Delete recipe"].tap()
        XCTAssertTrue(app.buttons["tab-recipes"].waitForExistence(timeout: 30))
        openRecipeSearch()
        replace(app.searchFields["Search recipes or ingredients"], with: revised)
        dismissSearchKeyboard()
        XCTAssertTrue(app.staticTexts["A fresh start"].waitForExistence(timeout: 25))
        capture("Deleted owned recipe absent from server search")
    }

    func test13WelcomeInlineAgreementLinksAndCheckbox() {
        let checkbox = app.buttons["welcome-consent-checkbox"]
        XCTAssertTrue(checkbox.waitForExistence(timeout:15))
        XCTAssertEqual(checkbox.value as? String,"Unchecked")
        XCTAssertEqual(checkbox.frame.width,44,accuracy:1)
        XCTAssertEqual(checkbox.frame.height,44,accuracy:1)
        let login = app.buttons["Log in"]
        let agreement = app.textViews["welcome-agreement-text"]
        XCTAssertTrue(login.isHittable)
        XCTAssertGreaterThanOrEqual(checkbox.frame.minY,login.frame.maxY + 12)
        XCTAssertGreaterThanOrEqual(agreement.frame.minY,login.frame.maxY + 12)
        XCTAssertTrue(app.frame.contains(agreement.frame))
        XCTAssertFalse(app.buttons["Terms"].exists)
        XCTAssertFalse(app.buttons["Privacy"].exists)
        for title in ["Terms of Service","Privacy Policy"] {
            let link = app.links[title].firstMatch
            XCTAssertTrue(link.waitForExistence(timeout:10))
            XCTAssertTrue(link.isHittable)
            XCTAssertTrue(app.frame.contains(link.frame))
            capture("Welcome inline " + title)
            link.tap()
            XCTAssertTrue(app.navigationBars[title].waitForExistence(timeout:10))
            back()
            XCTAssertEqual(checkbox.value as? String,"Unchecked","Viewing a document must not grant consent")
        }
        reveal(checkbox); checkbox.tap()
        XCTAssertEqual(checkbox.value as? String,"Checked")
        XCTAssertTrue(checkbox.isSelected)
        capture("Welcome with explicit checked agreement")
        checkbox.tap()
        XCTAssertEqual(checkbox.value as? String,"Unchecked")
        tap("Log in")
        XCTAssertTrue(app.alerts["Before we cook"].waitForExistence(timeout:5))
        app.alerts.buttons["Disagree"].tap()
        XCTAssertFalse(app.buttons["tab-live"].exists)
    }

    func test14RecipeHomeGridAndSingleResult() {
        enterHome()
        selectTab("recipes")
        let cards = app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","recipe-card-"))
        waitUntil("Recipe home loads both columns",timeout:30) { cards.count >= 2 }
        let left = cards.element(boundBy:0)
        let right = cards.element(boundBy:1)
        let originalWidth = left.frame.width
        reveal(left)
        XCTAssertEqual(left.frame.minY,right.frame.minY,accuracy:1)
        XCTAssertEqual(left.frame.width,right.frame.width,accuracy:1)
        XCTAssertEqual(right.frame.minX - left.frame.maxX,12,accuracy:1)
        XCTAssertLessThan(left.frame.width,app.frame.width * 0.5)
        capture("Recipes in two equal cover columns")
        openRecipeSearch()
        replace(app.searchFields["Search recipes or ingredients"],with:recipeTitle)
        dismissSearchKeyboard()
        waitUntil("Search leaves one matching recipe",timeout:25) { cards.count == 1 }
        let single = cards.firstMatch
        reveal(single)
        XCTAssertEqual(single.frame.width,originalWidth,accuracy:1)
        capture("Single recipe keeps the left half-width column")
        single.tap()
        XCTAssertTrue(app.buttons["Start cooking"].waitForExistence(timeout:20))
        back()
        XCTAssertEqual(app.searchFields["Search recipes or ingredients"].value as? String,recipeTitle)
    }

    func test16RecipeTutorialAndPreparationJourney() {
        enterHome()
        selectTab("recipes")
        let card = app.buttons.matching(NSPredicate(format:"label BEGINSWITH %@",recipeTitle + ",")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout:25)); reveal(card); card.tap()
        XCTAssertTrue(app.navigationBars["Recipe"].waitForExistence(timeout:10))
        XCTAssertFalse(app.buttons["Watch video tutorial"].exists)
        XCTAssertTrue(app.webViews["tutorial-player"].waitForExistence(timeout:20))
        let status = app.staticTexts["tutorial-status"]
        waitUntil("Inline publisher player leaves loading",timeout:40) { status.exists && status.label != "Loading tutorial…" }
        if status.label == "Tap Play to watch the tutorial." {
            let play = app.webViews.buttons["Play"].firstMatch
            if play.waitForExistence(timeout:10),play.isHittable { play.tap() }
        }
        XCTAssertTrue(app.staticTexts["Playing tutorial"].waitForExistence(timeout:30),status.label)
        let progress = app.staticTexts["tutorial-progress"]
        let initial = Double(progress.value as? String ?? "") ?? 0
        waitUntil("Inline tutorial advances",timeout:15) { (Double(progress.value as? String ?? "") ?? 0) > initial + 1 }
        capture("Inline recipe tutorial with compact categories")
        tap("Ingredient prep")
        tap("+")
        XCTAssertTrue(app.staticTexts["3 servings"].exists)
        tap("Prepare Spaghetti")
        XCTAssertEqual(app.buttons["Prepare Spaghetti"].value as? String,"Prepared")
        tap("Cooking steps")
        let first = app.staticTexts["recipe-step-1"]
        let last = app.staticTexts["recipe-step-5"]
        XCTAssertTrue(first.exists); reveal(last); XCTAssertTrue(last.isHittable)
        capture("Recipe steps displayed as individual rows")
        tap("Ingredient prep")
        XCTAssertTrue(app.staticTexts["3 servings"].exists)
        XCTAssertEqual(app.buttons["Prepare Spaghetti"].value as? String,"Prepared")
        capture("Ingredient checklist preserved across categories")
        let wasLiked = app.buttons["Liked"].exists
        tap(wasLiked ? "Liked" : "Like")
        let changed = app.buttons[wasLiked ? "Like" : "Liked"]
        XCTAssertTrue(changed.waitForExistence(timeout:20))
        XCTAssertEqual(changed.value as? String,wasLiked ? "Not liked" : "Liked")
        tap(wasLiked ? "Like" : "Liked")
        XCTAssertTrue(app.buttons[wasLiked ? "Liked" : "Like"].waitForExistence(timeout:20))
        XCTAssertEqual(app.buttons["Prepare Spaghetti"].value as? String,"Prepared")
        let wasSaved = app.buttons["Saved"].exists
        tap(wasSaved ? "Saved" : "Save")
        let changedSave = app.buttons[wasSaved ? "Save" : "Saved"]
        XCTAssertTrue(changedSave.waitForExistence(timeout:20))
        XCTAssertEqual(changedSave.value as? String,wasSaved ? "Not saved" : "Saved")
        capture("Recipe bookmark changed state")
        tap(wasSaved ? "Save" : "Saved")
        let restoredSave = app.buttons[wasSaved ? "Saved" : "Save"]
        XCTAssertTrue(restoredSave.waitForExistence(timeout:20))
        XCTAssertEqual(restoredSave.value as? String,wasSaved ? "Saved" : "Not saved")
        capture("Recipe bookmark restored state")
        XCTAssertEqual(app.buttons["Prepare Spaghetti"].value as? String,"Prepared")
        let start = app.buttons["Start cooking"]
        XCTAssertLessThan(start.frame.maxY,app.buttons["Share"].frame.minY)
        tap("Start cooking")
        XCTAssertTrue(app.staticTexts["STEP 1 OF 5"].waitForExistence(timeout:10))
        tap("Next")
        XCTAssertTrue(app.staticTexts["STEP 2 OF 5"].exists)
        back()
        XCTAssertTrue(app.staticTexts["3 servings"].exists)
        XCTAssertEqual(app.buttons["Prepare Spaghetti"].value as? String,"Prepared")
        capture("Inline recipe retains preparation after cook along")
    }

    /// Run only at an accessibility text category on the designated acceptance device.
    func test15AccessibilityRecipeHomeUsesOneColumn() {
        enterHome()
        selectTab("recipes")
        let cards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "recipe-card-"))
        waitUntil("Accessible recipe catalog loads", timeout: 30) { cards.count >= 2 }
        let first = cards.element(boundBy: 0)
        let second = cards.element(boundBy: 1)
        reveal(first)
        XCTAssertGreaterThan(first.frame.width, app.frame.width * 0.75)
        XCTAssertGreaterThanOrEqual(second.frame.minY, first.frame.maxY)
        capture("Accessible recipe home uses one full-width column")
        let tomato = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", recipeTitle + ",")).firstMatch
        reveal(tomato)
        tomato.tap()
        tap("Cooking steps")
        let last = app.staticTexts["recipe-step-5"]
        reveal(last)
        XCTAssertTrue(last.isHittable)
        capture("Accessible recipe final step remains reachable")
        let like = app.buttons["Liked"].exists ? app.buttons["Liked"] : app.buttons["Like"]
        let save = app.buttons["Saved"].exists ? app.buttons["Saved"] : app.buttons["Save"]
        let share = app.buttons["Share"]
        XCTAssertGreaterThan(like.frame.width, app.frame.width * 0.75, "Accessible social labels need a full-width action")
        XCTAssertGreaterThanOrEqual(save.frame.minY, like.frame.maxY)
        XCTAssertGreaterThanOrEqual(share.frame.minY, save.frame.maxY)
    }

    func test24AccessibilityProfileMetricsKeepWordsWhole() {
        enterHome()
        selectTab("me")
        let following = app.buttons.matching(NSPredicate(format: "label MATCHES %@", "[0-9]+ Following")).firstMatch
        let followers = app.buttons.matching(NSPredicate(format: "label MATCHES %@", "[0-9]+ Followers")).firstMatch
        XCTAssertTrue(following.waitForExistence(timeout: 20))
        reveal(following)
        capture("Accessible profile relationship metrics")
        XCTAssertGreaterThan(following.frame.width, app.frame.width * 0.3, "Following must have room for a whole word at accessibility size")
        XCTAssertGreaterThan(followers.frame.width, app.frame.width * 0.3)
        XCTAssertEqual(following.frame.minY, followers.frame.minY, accuracy: 1)
        XCTAssertGreaterThanOrEqual(followers.frame.minX, following.frame.maxX)
    }

    func test22LiveRoomCoversAndNavigation() {
        enterHome()
        selectTab("live")
        XCTAssertFalse(app.searchFields["Find a cooking film"].exists)
        let searchAction = app.navigationBars.buttons["Search cooking rooms"]
        let createAction = app.navigationBars.buttons["Create cooking content"]
        XCTAssertTrue(searchAction.exists && createAction.exists)
        XCTAssertLessThan(searchAction.frame.maxX,createAction.frame.maxX)
        let cards = app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","live-room-card-"))
        waitUntil("Six real room covers load",timeout:30) { cards.count == 6 }
        let first = cards.element(boundBy:0)
        let second = cards.element(boundBy:1)
        reveal(first)
        let originalWidth = first.frame.width
        XCTAssertEqual(first.frame.minY,second.frame.minY,accuracy:1)
        XCTAssertEqual(first.frame.width,second.frame.width,accuracy:1)
        XCTAssertLessThan(originalWidth,app.frame.width * 0.5)
        XCTAssertGreaterThan(first.frame.height,first.frame.width)
        XCTAssertTrue((first.value as? String ?? "").contains("Cooking room replay"))
        let cover = app.descendants(matching:.any)["room-cover-progress-cooking-01"]
        XCTAssertTrue(cover.waitForExistence(timeout:15))
        waitUntil("Visible cover advances through real muted video",timeout:35) { (Double(cover.value as? String ?? "") ?? 0) > 0.4 }
        capture("Two-column cooking room covers with actual video")
        tap("Pasta")
        XCTAssertEqual(cards.count,1)
        XCTAssertEqual(cards.firstMatch.frame.width,originalWidth,accuracy:1)
        capture("Filtered room retains half-width cover")
        tap("All")
        tap("Search cooking rooms")
        let search = app.searchFields["Find a cooking film"]
        XCTAssertTrue(search.waitForExistence(timeout:10))
        replace(search,with:"acceptance_no_such_room")
        dismissSearchKeyboard()
        XCTAssertTrue(app.staticTexts["Nothing on the stove yet"].waitForExistence(timeout:10))
        replace(search,with:"Tossing a fresh salad")
        dismissSearchKeyboard()
        XCTAssertEqual(cards.count,1)
        XCTAssertTrue(app.staticTexts["Tossing a fresh salad"].exists)
        capture("Cooking room search keeps the real source title")
        tap("Enter kitchen")
        XCTAssertTrue(app.buttons["Send a gift"].waitForExistence(timeout:15))
        assertReplayAdvances()
        capture("Whole cover opens the matching recorded room")
        tap("Close")
        XCTAssertEqual(search.value as? String,"Tossing a fresh salad")
        replace(search,with:"")
        dismissSearchKeyboard()
        selectTab("recipes")
        selectTab("live")
        XCTAssertEqual(cards.count,6)
        waitUntil("Visible cover resumes after returning to Live",timeout:25) { (Double(cover.value as? String ?? "") ?? 0) > 0.4 }
        backgroundAndReactivate()
        let initial = Double(cover.value as? String ?? "") ?? 0
        waitUntil("Room cover resumes after foreground",timeout:20) { (Double(cover.value as? String ?? "") ?? 0) > initial + 0.3 }
        capture("Room cover after tab and foreground restoration")
        tap("Close search")
        XCTAssertFalse(search.exists)
        XCTAssertEqual(cards.count,6)
        XCTAssertTrue(app.navigationBars.buttons["Search cooking rooms"].exists)
        capture("Live toolbar search collapsed beside creation")
        tap("Create cooking content")
        XCTAssertTrue(app.buttons["Write a recipe"].waitForExistence(timeout:5))
        let cancel = app.buttons["Cancel"].firstMatch
        if cancel.exists && cancel.isHittable { cancel.tap() }
        else {
            let dismissal = app.otherElements["PopoverDismissRegion"]
            XCTAssertTrue(dismissal.waitForExistence(timeout:5)); XCTAssertTrue(dismissal.isHittable); dismissal.tap()
        }
        waitUntil("Creation menu dismisses through its native control",timeout:5) { !self.app.sheets["From your kitchen"].exists }
    }

    func test23AccessibleLiveRoomCovers() {
        enterHome()
        selectTab("live")
        let cards = app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@","live-room-card-"))
        waitUntil("Accessible room covers load",timeout:30) { cards.count == 6 }
        let first = cards.element(boundBy:0)
        let second = cards.element(boundBy:1)
        reveal(first)
        XCTAssertGreaterThan(first.frame.width,app.frame.width * 0.75)
        XCTAssertGreaterThanOrEqual(second.frame.minY,first.frame.maxY)
        capture("Accessible room cover uses one full-width column")
        let last = cards.element(boundBy:5)
        reveal(last)
        XCTAssertTrue(last.isHittable)
        capture("Accessible final room cover remains reachable")
        last.tap()
        XCTAssertTrue(app.buttons["Send a gift"].waitForExistence(timeout:15))
        tap("Close")
    }

    func test17LiveSearchFiltersAndAllReplayPlayback() {
        enterHome()
        selectTab("live")
        tap("Search cooking rooms")
        let search = app.searchFields["Find a cooking film"]
        replace(search, with: "acceptance_no_such_film")
        dismissSearchKeyboard()
        XCTAssertTrue(app.staticTexts["Nothing on the stove yet"].waitForExistence(timeout: 10))
        capture("Live empty search")
        replace(search, with: "")
        dismissSearchKeyboard()
        tap("Pasta")
        XCTAssertEqual(app.buttons.matching(identifier: "Enter kitchen").count, 1)
        capture("Live pasta category")
        tap("All")
        for title in ["Skillet pasta", "Pancakes on the griddle", "Colorful skillet vegetables", "Seasoning grilled steak", "Kneading homemade dough", "Tossing a fresh salad"] {
            XCTContext.runActivity(named: "Actual replay playback: " + title) { _ in
                replace(search, with: title)
                dismissSearchKeyboard()
                XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 10))
                tap("Enter kitchen")
                XCTAssertTrue(app.buttons["More"].waitForExistence(timeout: 15))
                waitUntil("Replay finishes initial loading", timeout: 30) {
                    !self.app.staticTexts["Loading cooking replay…"].exists
                }
                XCTAssertFalse(app.staticTexts["Replay could not play. Open More to retry."].exists)
                assertReplayAdvances()
                capture("Actual cooking replay " + title)
                tap("More")
                if app.buttons["Sound on"].exists { tap("Sound on") } else { tap("Sound off") }
                tap("Close")
                XCTAssertTrue(search.waitForExistence(timeout: 10))
            }
        }
        replace(search, with: "")
        dismissSearchKeyboard()
        tap("Create cooking content")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Live broadcasting is not connected yet")).firstMatch.waitForExistence(timeout: 5))
        capture("Broadcast availability is stated honestly")
        let cancel = app.buttons["Cancel"].firstMatch
        if cancel.exists && cancel.isHittable {
            cancel.tap()
        } else {
            let dismissal = app.otherElements["PopoverDismissRegion"]
            XCTAssertTrue(dismissal.waitForExistence(timeout: 5))
            XCTAssertTrue(dismissal.isHittable)
            dismissal.tap()
        }
        waitUntil("Creation menu dismisses through its native control", timeout: 5) {
            !self.app.sheets["From your kitchen"].exists
        }
        tap("Create cooking content")
        tap("Write a recipe")
        XCTAssertTrue(app.navigationBars["Write a recipe"].waitForExistence(timeout: 10))
        capture("Live content creation opens the ordinary recipe editor")
        back()
        XCTAssertTrue(app.buttons["tab-live"].exists)
    }

    func test18ProfileValidationAndAccountActionCancellation() {
        enterHome()
        selectTab("me")
        openProfileEditor()
        let username = app.textFields["Username"]
        let original = inputValue(username)
        replace(username, with: "invalid handle!")
        tap("Save profile")
        XCTAssertTrue(app.navigationBars["Edit profile"].exists)
        let error = app.staticTexts["Check your profile"]
        reveal(error)
        XCTAssertTrue(error.exists)
        capture("Invalid username cannot be saved")
        replace(username, with: original)
        back()
        if !app.navigationBars["Settings"].exists { tap("Settings") }
        tap("Log out")
        XCTAssertTrue(app.alerts["Log out?"].waitForExistence(timeout: 5))
        capture("Guest logout warning")
        app.alerts.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].exists)
        tap("Delete account")
        XCTAssertTrue(app.alerts["Delete your account?"].waitForExistence(timeout: 5))
        capture("First account deletion confirmation")
        app.alerts.buttons["Keep account"].tap()
        tap("Delete account")
        app.alerts.buttons["Continue"].tap()
        XCTAssertTrue(app.alerts["Permanently delete account?"].waitForExistence(timeout: 5))
        capture("Final account deletion warning")
        app.alerts.buttons["Cancel"].tap()
        back()
        openProfileEditor()
        XCTAssertEqual(inputValue(app.textFields["Username"]), original)
        capture("Cancelled account actions retain the same profile")
        back()
    }

    func test19RecipeFiltersValidationAndDraftRestoration() {
        enterHome()
        selectTab("recipes")
        let cards = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "recipe-card-"))
        for cuisine in ["Italian", "American", "European"] {
            tap(cuisine)
            waitUntil("Filtered " + cuisine + " recipes load", timeout: 25) {
                cards.count > 0 && cards.allElementsBoundByIndex.allSatisfy { $0.label.contains(", " + cuisine + ",") }
            }
            XCTAssertTrue(app.buttons[cuisine].isSelected)
            capture("Recipe cuisine filter " + cuisine)
        }
        tap("All")
        tap("Write a recipe")
        let title = app.textFields["Recipe name"]
        XCTAssertTrue(title.waitForExistence(timeout: 10))
        let prior = inputValue(title)
        let draft = "Private acceptance draft " + String(UUID().uuidString.prefix(8))
        replace(title, with: draft)
        back()
        tap("Write a recipe")
        XCTAssertEqual(inputValue(title), draft)
        XCTAssertTrue(app.staticTexts["Private draft restored"].exists)
        capture("Private recipe draft restores without publication")
        replace(title, with: "")
        tap("Publish recipe")
        XCTAssertTrue(app.alerts["A few finishing touches"].waitForExistence(timeout: 5))
        capture("Incomplete recipe is rejected before upload or publication")
        app.alerts.buttons["OK"].tap()
        replace(title, with: prior)
        back()
    }

    func test20KitchenTimerSurvivesNavigationAndRelaunch() {
        enterHome()
        selectTab("kitchen")
        tap("Kitchen timer")
        tap("Reset")
        tap("Start timer")
        waitUntil("Timer begins counting down", timeout: 8) {
            self.app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "9 minutes and")).firstMatch.exists
        }
        backgroundAndReactivate()
        XCTAssertTrue(app.navigationBars["Kitchen timer"].exists)
        capture("Running kitchen timer after foreground")
        app.terminate()
        app.launch()
        enterHome()
        selectTab("kitchen")
        tap("Kitchen timer")
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "9 minutes and")).firstMatch.waitForExistence(timeout: 5))
        capture("Wall-clock kitchen timer restored after cold launch")
        tap("Pause")
        tap("Reset")
        XCTAssertTrue(app.staticTexts["10 minutes and 0 seconds remaining"].exists)
        back()
    }

    func test21TakenUsernameHasActionableFeedback() {
        enterHome()
        selectTab("me")
        openProfileEditor()
        let username = app.textFields["Username"]
        let original = inputValue(username)
        let taken = original == "toli_acceptance_cook" ? "acceptance_partner_09f8deb1" : "toli_acceptance_cook"
        replace(username, with: taken)
        tap("Save profile")
        XCTAssertTrue(app.alerts["Please try again"].waitForExistence(timeout: 25))
        capture("Taken username produces actual server feedback")
        XCTAssertTrue(app.alerts.staticTexts["That username is already in use. Choose another."].exists,
                      "A rejected username must identify the actionable conflict rather than report a connection problem")
        app.alerts.buttons["OK"].tap()
        replace(username, with: original)
        back()
        openProfileEditor()
        XCTAssertEqual(inputValue(username), original, "Rejected updates must preserve the original server profile")
        back()
    }

    /// Run before the partner follows this app account to verify mutual-follow gating.
    func test29FollowRealAcceptancePartner() {
        enterHome()
        for suffix in ["09f8deb1", "41540e52"] {
            openAcceptancePartner(suffix: suffix)
            if app.buttons["Follow"].exists { tap("Follow") }
            XCTAssertTrue(app.buttons["Following"].waitForExistence(timeout: 20))
            capture("Followed isolated real acceptance partner " + suffix)
            back()
            back()
        }
    }

    /// The fixture owner must first acknowledge the partner's reciprocal server follow.
    func test30RealChatSendDraftAndPreferences() {
        enterHome()
        openAcceptancePartner()
        XCTAssertTrue(app.buttons["Message"].waitForExistence(timeout: 25))
        tap("Message")
        let composer = app.textViews["Message"]
        XCTAssertTrue(composer.waitForExistence(timeout: 20))
        waitUntil("Real mutual conversation accepts messages", timeout: 25) { self.app.buttons["Attach photo"].isEnabled }
        replace(composer, with: "Toli acceptance hello")
        waitUntil("Send becomes available", timeout: 10) { self.app.buttons["Send message"].isEnabled }
        tap("Send message")
        XCTAssertTrue(messageContaining("Toli acceptance hello").waitForExistence(timeout: 25))
        waitUntil("Acknowledged message clears composer", timeout: 15) { (composer.value as? String ?? "").isEmpty }
        capture("Server acknowledged direct message")
        replace(composer, with: "Toli acceptance unsent draft")
        back()
        tap("Message")
        waitUntil("Draft restores after leaving conversation", timeout: 20) {
            (composer.value as? String) == "Toli acceptance unsent draft"
        }
        capture("Restored account scoped chat draft")
        replace(composer, with: "")
        back()
        back()
        back()
        selectTab("me")
        selectTab("chats")
        let manage = app.buttons["Manage conversation with Toli Acceptance Partner 09f8deb1"]
        XCTAssertTrue(manage.waitForExistence(timeout: 25))
        reveal(manage)
        manage.tap()
        if app.buttons["Unpin"].exists {
            tap("Unpin")
            waitUntil("Existing pin is removed", timeout: 20) {
                !self.app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "· Pinned")).firstMatch.exists
            }
            manage.tap()
        }
        tap("Pin")
        waitUntil("Pinned conversation readback", timeout: 20) {
            self.app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "· Pinned")).firstMatch.exists
        }
        manage.tap()
        if app.buttons["Unmute"].exists {
            tap("Unmute")
            waitUntil("Existing mute is removed", timeout: 20) {
                !self.app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Muted")).firstMatch.exists
            }
            manage.tap()
        }
        tap("Mute")
        waitUntil("Muted conversation readback", timeout: 20) {
            self.app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Muted")).firstMatch.exists
        }
        capture("Pinned and muted real conversation")
    }

    /// The fixture process watches the ready message, then sends the real reply while this view is open.
    func test31RealChatReceiveWhileOpen() {
        enterHome()
        openAcceptancePartner()
        tap("Message")
        let composer = app.textViews["Message"]
        XCTAssertTrue(composer.waitForExistence(timeout: 20))
        waitUntil("Existing chat history loads before incoming-message baseline", timeout: 25) {
            self.app.staticTexts["Conversation updated."].exists || self.app.staticTexts["Say hello and share what you are cooking."].exists
        }
        let connection = app.staticTexts["chat-connection"]
        XCTAssertTrue(connection.waitForExistence(timeout: 15))
        waitUntil("Real native chat WebSocket is connected before the ready message", timeout: 25) {
            connection.value as? String == "Connected"
        }
        captureHierarchy("Connected native conversation before realtime ready")
        let previousReadyCount = messageCount(containing: "Toli acceptance realtime ready")
        let previousReplyCount = messageCount(containing: "Toli acceptance partner reply")
        replace(composer, with: "Toli acceptance realtime ready")
        waitUntil("Send becomes available", timeout: 15) { self.app.buttons["Send message"].isEnabled }
        tap("Send message")
        waitUntil("Fresh ready message is acknowledged", timeout: 25) {
            self.messageCount(containing: "Toli acceptance realtime ready") > previousReadyCount && (composer.value as? String ?? "").isEmpty
        }
        waitUntil("A fresh real partner reply arrives in the open conversation", timeout: 20) {
            self.messageCount(containing: "Toli acceptance partner reply") > previousReplyCount
        }
        capture("Received real partner reply in open conversation")
    }

    func test32RealGroupCreationAndMemberManagement() {
        enterHome()
        selectTab("chats")
        tap("New conversation")
        tap("Create a group")
        replace(app.textFields["Group name"], with: "Toli Acceptance Cooking Group")
        XCTAssertFalse(app.buttons["Create group"].isEnabled, "A group requires at least two mutual friends")
        tap("Invite · Toli Acceptance Partner 09f8deb1")
        XCTAssertFalse(app.buttons["Create group"].isEnabled)
        tap("Invite · Toli Acceptance Partner 41540e52")
        XCTAssertTrue(app.buttons["Create group"].isEnabled)
        tap("Create group")
        let composer = app.textViews["Message"]
        XCTAssertTrue(composer.waitForExistence(timeout: 25))
        replace(composer, with: "Toli acceptance group hello")
        waitUntil("Group send becomes available", timeout: 20) { self.app.buttons["Send message"].isEnabled }
        tap("Send message")
        XCTAssertTrue(messageContaining("Toli acceptance group hello").waitForExistence(timeout: 25))
        capture("Server created three member group")
        tap("Conversation details")
        let remove = app.buttons["Remove Toli Acceptance Partner 41540e52"]
        XCTAssertTrue(remove.waitForExistence(timeout: 20))
        reveal(remove)
        remove.tap()
        XCTAssertTrue(app.alerts["Remove member?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Remove"].tap()
        waitUntil("Removed member disappears after server acknowledgement", timeout: 20) { !remove.exists }
        capture("Group member removed")
        tap("Add a cooking friend")
        tap("Invite Toli Acceptance Partner 41540e52")
        XCTAssertTrue(remove.waitForExistence(timeout: 20))
        capture("Group member restored")
        back()
        capture("Final real group conversation")
    }

    /// Run after independently recording test 32's real partner member/message readback.
    func test33RealGroupLeave() {
        enterHome()
        selectTab("chats")
        let group = app.staticTexts["Toli Acceptance Cooking Group"].firstMatch
        XCTAssertTrue(group.waitForExistence(timeout: 25))
        reveal(group)
        group.tap()
        tap("Conversation details")
        tap("Leave group")
        XCTAssertTrue(app.alerts["Manage your group first"].waitForExistence(timeout: 5))
        capture("Owner must remove other group members before leaving")
        app.alerts.buttons["OK"].tap()
        for suffix in ["09f8deb1", "41540e52"] {
            let remove = app.buttons["Remove Toli Acceptance Partner " + suffix]
            reveal(remove)
            remove.tap()
            XCTAssertTrue(app.alerts["Remove member?"].waitForExistence(timeout: 5))
            app.alerts.buttons["Remove"].tap()
            waitUntil("Other member is removed before owner leaves", timeout: 25) { !remove.exists }
        }
        tap("Leave group")
        XCTAssertTrue(app.alerts["Leave this group?"].waitForExistence(timeout: 5))
        capture("Leave isolated acceptance group confirmation")
        app.alerts.buttons["Leave group"].tap()
        XCTAssertTrue(app.buttons["tab-chats"].waitForExistence(timeout: 25))
        waitUntil("Left group disappears from the server refreshed inbox", timeout: 25) { !group.exists }
        capture("Inbox after acknowledged group leave")
    }

    func test34ChatBackgroundForegroundRetention() {
        enterHome()
        openAcceptancePartner()
        tap("Message")
        let composer = app.textViews["Message"]
        replace(composer, with: "Toli acceptance foreground draft")
        capture("Chat draft before background")
        backgroundAndReactivate()
        XCTAssertTrue(composer.waitForExistence(timeout: 15))
        XCTAssertEqual(composer.value as? String, "Toli acceptance foreground draft")
        XCTAssertTrue(messageContaining("Toli acceptance hello").exists)
        capture("Chat and draft retained after foreground")
        replace(composer, with: "")
    }

    /// Run last: blocking intentionally removes the isolated partner's mutual relationships.
    func test35ReportBlockAndUnblockIsolatedPartner() {
        enterHome()
        openAcceptancePartner(suffix: "41540e52")
        tap("Report profile")
        tap("Other")
        replace(app.textViews["Report details"], with: "Isolated acceptance report for Tilo native UI verification.")
        tap("Submit report")
        XCTAssertTrue(app.alerts["Report received"].waitForExistence(timeout: 25))
        capture("Real isolated profile report acknowledged")
        app.alerts.buttons["Done"].tap()
        tap("Block cook")
        XCTAssertTrue(app.alerts["Block this cook?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Block"].tap()
        XCTAssertTrue(app.navigationBars["Find people"].waitForExistence(timeout: 25))
        back()
        selectTab("me")
        tap("Settings")
        tap("Blocked cooks")
        XCTAssertTrue(app.staticTexts["Toli Acceptance Partner 41540e52"].waitForExistence(timeout: 25))
        capture("Blocked isolated partner server readback")
        tap("Unblock")
        XCTAssertTrue(app.alerts["Unblock Toli Acceptance Partner 41540e52?"].waitForExistence(timeout: 5))
        app.alerts.buttons["Unblock"].tap()
        XCTAssertTrue(app.staticTexts["A comfortable kitchen"].waitForExistence(timeout: 25))
        capture("Empty block list after server acknowledged unblock")
        back()
        back()
        capture("Final retained acceptance profile")
    }

    private func backgroundAndReactivate() {
        XCUIDevice.shared.press(.home)
        waitUntil("App enters the background", timeout: 10) {
            self.app.state == .runningBackground || self.app.state == .runningBackgroundSuspended
        }
        app.activate()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 15))
    }

    private func replaySeconds() -> Double? {
        guard let value = app.descendants(matching:.any)["replay-progress"].value as? String else { return nil }
        return Double(value)
    }

    private func assertReplayAdvances() {
        XCTAssertTrue(app.descendants(matching:.any)["replay-progress"].waitForExistence(timeout: 10))
        guard let initial = replaySeconds() else { XCTFail("Replay progress must expose numeric native player seconds"); return }
        var previous = initial
        var advanced = 0.0
        print("Replay playback probe starts at \(initial) seconds")
        waitUntil("Native AVPlayer advances more than one second across replay loops", timeout: 12) {
            guard let current = self.replaySeconds() else { return false }
            if current >= previous { advanced += current - previous }
            else { print("Replay timeline wrapped from \(previous) to \(current) seconds") }
            previous = current
            return advanced > 1
        }
    }

    private func assertReplayRemainsPaused() {
        guard let initial = replaySeconds() else { XCTFail("Paused replay must expose numeric native player seconds"); return }
        let moved = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard let current = self.replaySeconds() else { return true }
            return abs(current - initial) > 0.3
        }, object: nil)
        moved.isInverted = true
        XCTAssertEqual(XCTWaiter.wait(for: [moved], timeout: 3), .completed,
                       "Paused AVPlayer time must remain stable for three seconds")
    }

    private func photoPickerApplications() -> [XCUIApplication] {
        // Bundle identifiers were read from the installed iOS runtime Info.plist files.
        [XCUIApplication(bundleIdentifier: "com.apple.mobileslideshow.photospicker"),
         XCUIApplication(bundleIdentifier: "com.apple.Photos.PhotosUIService"), app]
    }

    private func seededCookingPhoto(in candidate: XCUIApplication) -> XCUIElement {
        candidate.images.matching(identifier: "PXGGridLayout-Info").matching(NSPredicate(format: "label ENDSWITH %@", "16:08")).firstMatch
    }

    private func loadedPhotoPicker() -> XCUIApplication? {
        for candidate in photoPickerApplications() where candidate.state != .notRunning {
            let photo = seededCookingPhoto(in: candidate)
            if photo.exists && photo.frame.width > 40 && photo.frame.height > 40 && app.frame.intersects(photo.frame) {
                return candidate
            }
        }
        return nil
    }

    private func capturePhotoPickerHierarchies() {
        for (index, candidate) in photoPickerApplications().enumerated() {
            let state = candidate.state
            let description = state == .notRunning ? "Photo picker process is not running." : candidate.debugDescription
            let attachment = XCTAttachment(string: description)
            attachment.name = "Photo picker process " + ["PhotosPicker", "PhotosUIService", "Tilo"][index]
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.state != .notRunning {
            let attachment = XCTAttachment(string: springboard.debugDescription)
            attachment.name = "System surface during photo picker"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }

    private func selectSeededCookingPhoto(afterSelection: @escaping () -> Bool) {
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in self.loadedPhotoPicker() != nil }, object: nil)
        let result = XCTWaiter.wait(for: [ready], timeout: 45)
        capturePhotoPickerHierarchies()
        capture("Loaded native cooking photo library before selection")
        XCTAssertEqual(result, .completed, "Actual native photo grid must finish loading")
        guard let picker = loadedPhotoPicker() else { return }
        // The observed native grid exposes Image elements, not collection cells. The one
        // imported cooking fixture has time 16:08; all six simulator stock photos have other dates/times.
        let photo = seededCookingPhoto(in: picker)
        XCTAssertTrue(photo.exists)
        XCTAssertGreaterThan(photo.frame.width, 40)
        XCTAssertGreaterThan(photo.frame.height, 40)
        XCTAssertTrue(app.frame.contains(photo.frame), "The exact imported image bounds must be fully inside the current screen")
        capture("Exact imported photo bounds before native selection")
        if photo.isHittable { photo.tap() }
        else {
            // Photos exposes virtual grid images with valid current AX bounds but no hittable point.
            // Derive this gesture from this exact identified image, never from a prior screen layout.
            photo.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        waitUntil("Selected real cooking photo returns through the native picker delegate", timeout: 30, condition: afterSelection)
    }

    private func openAcceptancePartner(suffix: String = "09f8deb1") {
        selectTab("chats")
        tap("New conversation")
        tap("Find people")
        replace(app.searchFields["Name or username"], with: "acceptance_partner_" + suffix)
        dismissSearchKeyboard()
        let person = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Toli Acceptance Partner " + suffix + ",")).firstMatch
        XCTAssertTrue(person.waitForExistence(timeout: 25))
        reveal(person)
        person.tap()
        XCTAssertTrue(app.staticTexts["Toli Acceptance Partner " + suffix].waitForExistence(timeout: 20))
    }

    private func messageCount(containing body: String) -> Int {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", body)).count
    }

    private func messageContaining(_ body: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", body)).firstMatch
    }

    private func enterHome(checkConsentGate: Bool = false) {
        let login = app.buttons["Log in"]
        waitUntil("Welcome or authenticated roots", timeout: 15) {
            login.exists || self.app.buttons["tab-live"].exists
        }
        if login.exists {
            if checkConsentGate {
                reveal(login)
                login.tap()
                XCTAssertTrue(app.alerts["Before we cook"].waitForExistence(timeout: 5))
                capture("Required agreement confirmation")
                app.alerts.buttons["Disagree"].tap()
            }
            let consent = app.buttons["I am 18+ and accept the agreements"]
            reveal(consent)
            consent.tap()
            XCTAssertTrue(app.buttons.matching(NSPredicate(format: "value == %@", "Checked")).firstMatch.exists)
            reveal(login)
            login.tap()
        }
        XCTAssertTrue(app.buttons["tab-live"].waitForExistence(timeout: 45), "Ordinary real guest login must reach the five roots")
    }

    func test24RecipeToolbarSearchAndCompactPersonalCollections() {
        enterHome()
        selectTab("recipes")
        let search = app.searchFields["Search recipes or ingredients"]
        XCTAssertFalse(search.exists)
        let searchAction = app.buttons["Search recipes"]
        let create = app.buttons["Write a recipe"]
        XCTAssertTrue(searchAction.exists && create.exists)
        XCTAssertLessThan(searchAction.frame.maxX, create.frame.maxX)
        capture("Recipe toolbar search beside creation")
        openRecipeSearch()
        replace(search, with:"acceptance_missing_ingredient")
        dismissSearchKeyboard()
        XCTAssertTrue(app.staticTexts["A fresh start"].waitForExistence(timeout:25))
        tap("Close search")
        XCTAssertFalse(search.exists)
        let cards = app.buttons.matching(NSPredicate(format:"identifier BEGINSWITH %@", "recipe-card-"))
        waitUntil("Closing search restores the catalog",timeout:25) { cards.count >= 2 }
        let identifiers = [cards.element(boundBy:0).identifier, cards.element(boundBy:1).identifier]
        var introducedLikes: [String] = []
        var introducedSaves: [String] = []
        for identifier in identifiers {
            tap(identifier)
            waitUntil("Recipe collection state is loaded before editing",timeout:25) {
                self.app.buttons["recipe-like"].isEnabled && self.app.buttons["recipe-save"].isEnabled
            }
            if app.buttons["Like"].exists {
                tap("Like"); XCTAssertTrue(app.buttons["Liked"].waitForExistence(timeout:25)); introducedLikes.append(identifier)
            }
            if app.buttons["Save"].exists {
                tap("Save"); XCTAssertTrue(app.buttons["Saved"].waitForExistence(timeout:25)); introducedSaves.append(identifier)
            }
            back()
        }
        selectTab("me")
        XCTAssertTrue(app.buttons["My wallet"].waitForExistence(timeout:25))
        XCTAssertFalse(app.buttons["Edit profile"].exists)
        for title in ["View works", "View liked", "View saved"] { XCTAssertFalse(app.buttons[title].exists) }
        tap("Works")
        capture("Compact personal homepage without redundant actions")
        for title in ["Liked", "Saved"] {
            tap(title)
            let first = app.buttons[identifiers[0]], second = app.buttons[identifiers[1]]
            XCTAssertTrue(first.waitForExistence(timeout:25)); XCTAssertTrue(second.waitForExistence(timeout:25))
            reveal(first)
            XCTAssertEqual(first.frame.minY,second.frame.minY,accuracy:1)
            XCTAssertEqual(first.frame.width,second.frame.width,accuracy:1)
            XCTAssertLessThan(first.frame.width,app.frame.width * 0.5)
            capture("Personal " + title + " uses two compact columns")
            first.tap()
            XCTAssertTrue(app.buttons["Start cooking"].waitForExistence(timeout:20))
            back()
        }
        tap("My wallet")
        XCTAssertTrue(app.navigationBars["Wallet"].waitForExistence(timeout:10))
        back()
        openProfileEditor()
        XCTAssertTrue(app.textFields["Display name"].waitForExistence(timeout:10))
        capture("Profile editing lives in Settings")
        back(); back()
        selectTab("recipes")
        for identifier in identifiers {
            tap(identifier)
            waitUntil("Original collection state is loaded before restoration",timeout:25) {
                self.app.buttons["recipe-like"].isEnabled && self.app.buttons["recipe-save"].isEnabled
            }
            if introducedLikes.contains(identifier) { tap("Liked"); XCTAssertTrue(app.buttons["Like"].waitForExistence(timeout:25)) }
            if introducedSaves.contains(identifier) { tap("Saved"); XCTAssertTrue(app.buttons["Save"].waitForExistence(timeout:25)) }
            back()
        }
    }

    func test40PublishedRecipeReportAndBlockAuthor() {
        enterHome()
        unblockSafetyCook(ifPresent:true)
        openSafetyRecipe("Safety acceptance recipe")
        tap("Recipe options"); tap("Report recipe")
        submitSafetyReport()
        tap("Recipe options"); tap("Report cook")
        XCTAssertTrue(app.navigationBars["Report profile"].waitForExistence(timeout:10))
        tap("Close")
        tap("Recipe options"); tap("Block cook")
        XCTAssertTrue(app.alerts["Block this cook?"].waitForExistence(timeout:5))
        capture("Published recipe exposes real author report and block")
        confirmSafetyBlock()
        XCTAssertTrue(app.staticTexts["A fresh start"].waitForExistence(timeout:30))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format:"label BEGINSWITH %@","Safety acceptance recipe,")).firstMatch.exists)
        capture("Blocked publisher disappears from recipe search")
        unblockSafetyCook()
    }

    func test41RecipeCommentAndRoomMessageSafety() {
        enterHome()
        unblockSafetyCook(ifPresent:true)
        openSafetyRecipe(recipeTitle)
        tap("Recipe options"); tap("Join the recipe conversation")
        tap("Comment options for Safety Acceptance Cook")
        XCTAssertTrue(app.buttons["Report comment"].waitForExistence(timeout:10))
        XCTAssertTrue(app.buttons["Block cook"].exists)
        capture("Recipe comment offers content and author safety")
        tap("Report comment"); submitSafetyReport()
        back(); back()
        selectTab("live")
        tap("Search cooking rooms")
        replace(app.searchFields["Find a cooking film"],with:"Skillet pasta")
        dismissSearchKeyboard()
        tap("Enter kitchen")
        let note = app.descendants(matching:.any).matching(NSPredicate(format:"identifier BEGINSWITH %@ AND label CONTAINS %@","room-message-","Safety acceptance room note")).firstMatch
        XCTAssertTrue(note.waitForExistence(timeout:20))
        note.press(forDuration:1.1)
        XCTAssertTrue(app.buttons["Report comment"].waitForExistence(timeout:10))
        XCTAssertTrue(app.buttons["Report cook"].exists)
        capture("Room message long press exposes safety without extra toolbar buttons")
        tap("Block cook")
        confirmSafetyBlock()
        waitUntil("Blocked room author disappears",timeout:20) { !note.exists }
        assertReplayAdvances()
        tap("Close")
        unblockSafetyCook()
    }

    func test42PublishedReplayReportAndBlockAuthor() {
        enterHome()
        unblockSafetyCook(ifPresent:true)
        selectTab("live")
        tap("Search cooking rooms")
        replace(app.searchFields["Find a cooking film"],with:"Safety acceptance replay")
        dismissSearchKeyboard()
        tap("Enter kitchen")
        tap("More")
        XCTAssertTrue(app.buttons["Report replay"].waitForExistence(timeout:10))
        XCTAssertTrue(app.buttons["Report cook"].exists)
        XCTAssertTrue(app.buttons["Block cook"].exists)
        capture("Member-owned replay exposes content and author safety")
        tap("Report replay"); submitSafetyReport()
        tap("More"); tap("Block cook")
        confirmSafetyBlock()
        XCTAssertTrue(app.staticTexts["Nothing on the stove yet"].waitForExistence(timeout:30))
        capture("Blocked replay publisher disappears from discovery")
        unblockSafetyCook()
    }

    func test43EditorialContentHideAndRestore() {
        enterHome()
        openSafetyRecipe(recipeTitle)
        tap("Recipe options")
        XCTAssertTrue(app.buttons["Report recipe"].waitForExistence(timeout:10))
        XCTAssertTrue(app.buttons["Block cook"].exists)
        tap("Hide recipe")
        confirmSafetyHide("recipe")
        XCTAssertTrue(app.staticTexts["A fresh start"].waitForExistence(timeout:30))
        restoreSafetyContent("recipe-recipe-01")
        selectTab("live")
        tap("Search cooking rooms")
        replace(app.searchFields["Find a cooking film"],with:"Skillet pasta")
        dismissSearchKeyboard()
        tap("Enter kitchen"); tap("More")
        XCTAssertTrue(app.buttons["Block cook"].exists)
        tap("Hide replay")
        confirmSafetyHide("replay")
        XCTAssertTrue(app.staticTexts["Nothing on the stove yet"].waitForExistence(timeout:30))
        capture("Editorial content can be hidden independently of blocking its authorized publisher")
        restoreSafetyContent("video-cooking-01")
    }

    func test44PublisherAttributionInSafetyMenus() {
        enterHome()
        unblockSafetyCook(ifPresent:true)
        openSafetyRecipe("Safety acceptance recipe")
        tap("Recipe options")
        let publisher = app.staticTexts.matching(NSPredicate(format:"label CONTAINS %@","Shared by Safety Acceptance Cook")).firstMatch
        XCTAssertTrue(publisher.waitForExistence(timeout:10))
        XCTAssertTrue(app.buttons["Report cook"].exists && app.buttons["Block cook"].exists)
        capture("Recipe safety menu identifies the actual publisher")
        dismissSafetyMenu(); back()
        selectTab("live"); tap("Search cooking rooms")
        replace(app.searchFields["Find a cooking film"],with:"Safety acceptance replay")
        dismissSearchKeyboard(); tap("Enter kitchen"); tap("More")
        XCTAssertTrue(publisher.waitForExistence(timeout:10))
        XCTAssertTrue(app.buttons["Report replay"].exists && app.buttons["Block cook"].exists)
        capture("Replay safety distinguishes filmmaker credit from the real publisher")
        dismissSafetyMenu(); tap("Close")
    }

    private func dismissSafetyMenu() {
        let cancel = app.buttons["Cancel"].firstMatch
        if cancel.exists && cancel.isHittable { cancel.tap() }
        else { let outside = app.otherElements["PopoverDismissRegion"].firstMatch; XCTAssertTrue(outside.waitForExistence(timeout:5)); outside.tap() }
    }

    private func openSafetyRecipe(_ title: String) {
        selectTab("recipes"); openRecipeSearch()
        replace(app.searchFields["Search recipes or ingredients"],with:title)
        dismissSearchKeyboard()
        let card = app.buttons.matching(NSPredicate(format:"label BEGINSWITH %@",title + ",")).firstMatch
        XCTAssertTrue(card.waitForExistence(timeout:25)); reveal(card); card.tap()
        XCTAssertTrue(app.buttons["Recipe options"].waitForExistence(timeout:10))
    }

    private func submitSafetyReport() {
        tap("Submit report")
        XCTAssertTrue(app.alerts["Report received"].waitForExistence(timeout:25))
        capture("Safety report acknowledged by the actual service")
        app.alerts.buttons["Done"].tap()
        waitUntil("Report form dismisses",timeout:10) {
            !self.app.navigationBars["Report content"].exists && !self.app.navigationBars["Report profile"].exists
        }
    }

    private func confirmSafetyBlock() {
        let confirmation = app.alerts["Block this cook?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout:5))
        waitUntil("Native block confirmation is ready",timeout:5) { confirmation.buttons["Block"].isHittable }
        tap("Block")
        waitUntil("Block confirmation dismisses",timeout:10) { !confirmation.exists }
    }

    private func confirmSafetyHide(_ kind: String) {
        let confirmation = app.alerts["Hide this " + kind + "?"]
        XCTAssertTrue(confirmation.waitForExistence(timeout:5))
        waitUntil("Native hide confirmation is ready",timeout:5) { confirmation.buttons["Hide"].isHittable }
        tap("Hide")
        waitUntil("Hide confirmation dismisses",timeout:10) { !confirmation.exists }
    }

    private func unblockSafetyCook(ifPresent: Bool = false) {
        selectTab("me"); tap("Settings"); tap("Blocked cooks")
        let unblock = app.buttons["Unblock Safety Acceptance Cook"]
        let exists = unblock.waitForExistence(timeout:ifPresent ? 3 : 25)
        if !ifPresent { XCTAssertTrue(exists) }
        if exists {
            tap("Unblock Safety Acceptance Cook")
            XCTAssertTrue(app.alerts["Unblock Safety Acceptance Cook?"].waitForExistence(timeout:5))
            app.alerts.buttons["Unblock"].tap()
            waitUntil("Only the isolated publisher is unblocked",timeout:25) { !unblock.exists }
        }
        back(); back()
    }

    private func restoreSafetyContent(_ identifier: String) {
        selectTab("me"); tap("Settings"); tap("Hidden content")
        let restore = app.buttons["show-hidden-" + identifier]
        tap("show-hidden-" + identifier)
        waitUntil("The isolated hidden record is restored",timeout:25) { !restore.exists }
        capture("Hidden content restored through Settings")
        back(); back()
    }

    private func openProfileEditor() {
        if !app.navigationBars["Settings"].exists { tap("Settings") }
        tap("Edit profile")
    }

    private func openRecipeSearch() {
        if !app.searchFields["Search recipes or ingredients"].exists { tap("Search recipes") }
        XCTAssertTrue(app.searchFields["Search recipes or ingredients"].waitForExistence(timeout:5))
    }

    private func selectTab(_ name: String) {
        let tab = app.buttons["tab-" + name]
        XCTAssertTrue(tab.waitForExistence(timeout: 10))
        tab.tap()
        XCTAssertTrue(tab.isSelected)
    }

    private func waitForRootContent(_ name: String) {
        let content: XCUIElement
        switch name {
        case "live": content = app.buttons["Enter kitchen"].firstMatch
        case "recipes": content = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", recipeTitle + ",")).firstMatch
        case "kitchen": content = app.buttons["Kitchen timer"]
        case "chats": content = app.staticTexts["Good food. Great company."]
        default: content = app.buttons["My wallet"]
        }
        XCTAssertTrue(content.waitForExistence(timeout: 30), "Root must expose its loaded content: " + name)
        reveal(content)
    }

    private func tap(_ title: String) {
        let buttons = app.buttons.matching(identifier: title)
        XCTAssertTrue(buttons.firstMatch.waitForExistence(timeout: 20), "Missing button: " + title)
        if let visible = buttons.allElementsBoundByIndex.first(where: { $0.isHittable }) {
            visible.tap()
            return
        }
        let button = buttons.firstMatch
        reveal(button)
        button.tap()
    }

    private func back() {
        let button = app.navigationBars.buttons["Back"].firstMatch
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
    }

    private func reveal(_ element: XCUIElement, fullyVisible: Bool = false, file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0..<24 {
            if !fullyVisible && element.exists && element.isHittable { return }
            guard let scroll = visiblePageScroll() else { break }
            var viewport = app.frame.intersection(scroll.frame)
            let keyboard = app.keyboards.firstMatch
            if keyboard.exists && keyboard.frame.intersects(viewport) {
                viewport.size.height = max(0, min(viewport.maxY, keyboard.frame.minY) - viewport.minY)
            }
            guard viewport.height > 100 else { break }
            if fullyVisible && element.exists && element.isHittable && viewport.insetBy(dx: 0, dy: 12).contains(element.frame) { return }
            let target = element.exists ? element.frame : CGRect.zero
            let downward: Bool
            let distance: CGFloat
            if element.exists && target.minY < viewport.minY + 12 {
                downward = true
                distance = viewport.minY + 12 - target.minY
            } else if !element.exists || target.maxY > viewport.maxY - 12 {
                downward = false
                distance = element.exists ? target.maxY - viewport.maxY + 12 : viewport.height
            } else {
                // A fully visible but inaccessible target has another occlusion or disabled state.
                // More scrolling would hide the evidence and can oscillate around keyboard edges.
                captureHierarchy("Target blocked inside current page viewport")
                capture("Target blocked inside current page viewport")
                break
            }
            let travel = min(viewport.height * 0.35, max(40, distance + 12))
            let x = viewport.maxX - max(6, viewport.width * 0.03)
            let startY = viewport.minY + viewport.height * (downward ? 0.4 : 0.75)
            let endY = startY + (downward ? travel : -travel)
            let origin = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            let start = origin.withOffset(CGVector(dx: x - scroll.frame.minX, dy: startY - scroll.frame.minY))
            let end = origin.withOffset(CGVector(dx: x - scroll.frame.minX, dy: endY - scroll.frame.minY))
            // The page gutter avoids dragging inside nested recipe-method or biography text views.
            start.press(forDuration: 0.05, thenDragTo: end)
        }
        XCTAssertTrue(element.exists && element.isHittable, "Element must be reachable: " + element.label, file: file, line: line)
    }

    private func visiblePageScroll() -> XCUIElement? {
        func isPageViewport(_ scroll: XCUIElement) -> Bool {
            guard scroll.exists, scroll.frame.height > 150 else { return false }
            return app.frame.intersection(scroll.frame).height > 150 && scroll.isHittable
        }
        for identifier in ["page-scroll", "chat-history"] {
            let scroll = app.scrollViews[identifier].firstMatch
            if isPageViewport(scroll) { return scroll }
        }
        // Horizontal filters and the keyboard suggestion strip are not page viewports.
        return app.scrollViews.allElementsBoundByIndex.first(where: isPageViewport)
    }

    private func replace(_ element: XCUIElement, with value: String) {
        XCTAssertTrue(element.waitForExistence(timeout: 10))
        if element.label == "Message" {
            waitUntil("Membership validation and draft restore enable the composer", timeout: 25) {
                self.app.buttons["Attach photo"].exists && self.app.buttons["Attach photo"].isEnabled
            }
        }
        reveal(element)
        element.tap()
        let current = inputValue(element)
        if current == value { return }
        if !current.isEmpty {
            let clear = element.buttons["Clear text"].firstMatch
            if clear.exists && clear.isHittable {
                clear.tap()
            } else {
                func chooseObservedSelectAll() -> Bool {
                    let menuItem = app.menuItems["Select All"].firstMatch
                    let menuButton = app.buttons["Select All"].firstMatch
                    let selectAll = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
                        menuItem.exists || menuButton.exists
                    }, object: nil)
                    guard XCTWaiter.wait(for: [selectAll], timeout: 2) == .completed else { return false }
                    if menuItem.exists { menuItem.tap() } else { menuButton.tap() }
                    return true
                }
                element.press(forDuration: 1.2)
                var selectedAll = chooseObservedSelectAll()
                if !selectedAll {
                    element.doubleTap()
                    selectedAll = chooseObservedSelectAll()
                }
                if !selectedAll {
                    // Triple tap selects a native paragraph. Verify complete removal below before
                    // typing; a partial selection can never silently concatenate old and new text.
                    element.tap(withNumberOfTaps: 3, numberOfTouches: 1)
                    _ = chooseObservedSelectAll()
                    captureHierarchy("Native paragraph selection fallback before replacement")
                }
                element.typeText(XCUIKeyboardKey.delete.rawValue)
            }
            guard inputValue(element).isEmpty else {
                captureHierarchy("Native clear did not remove the full old value")
                capture("Native clear did not remove the full old value")
                XCTFail("Native clear or selection must remove the complete previous value before typing")
                return
            }
        }
        if !value.isEmpty { element.typeText(value) }
        if inputValue(element) != value {
            captureHierarchy("Replacement value mismatch")
            capture("Replacement value mismatch")
        }
        XCTAssertEqual(inputValue(element), value, "Text replacement must preserve the exact requested value")
    }

    private func inputValue(_ element: XCUIElement) -> String {
        let value = element.value as? String ?? ""
        return value == element.placeholderValue ? "" : value
    }

    private func dismissSearchKeyboard() {
        let search = app.keyboards.buttons["Search"]
        if search.exists && search.isEnabled && search.isHittable { search.tap() }
    }

    private func waitUntil(_ description: String, timeout: TimeInterval, condition: @escaping () -> Bool) {
        let predicate = NSPredicate { _, _ in condition() }
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed, description)
    }

    private func captureHierarchy(_ name: String) {
        let attachment = XCTAttachment(string: app.debugDescription)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
