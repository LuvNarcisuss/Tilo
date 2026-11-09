import XCTest
import StoreKitTest

/// Uses ordinary account entry and an isolated ledger for actual local StoreKit purchases.
final class TiloWalletPurchaseUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws { continueAfterFailure = false }

    override func tearDownWithError() throws {
        if testRun?.failureCount ?? 0 > 0, let app {
            let hierarchy = XCTAttachment(string: app.debugDescription)
            hierarchy.lifetime = .keepAlways; add(hierarchy)
        }
    }

    @MainActor
    func testLocalCatalogAndBothCancellationPathsPreserveBalance() async throws {
        let fixture = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TiloDiamonds", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: fixture)
        session.resetToDefaultState()
        session.disableDialogs = false
        defer { session.resetToDefaultState() }
        try await openWallet()
        let balance = app.staticTexts["wallet.balance"]
        let before = try XCTUnwrap(balance.value as? String)
        let first = app.buttons["wallet.package.400"]
        let second = app.buttons["wallet.package.800"]
        let third = app.buttons["wallet.package.2450"]
        XCTAssertEqual(first.frame.minY, second.frame.minY, accuracy: 1, "The first three offers must share a grid row")
        XCTAssertEqual(second.frame.minY, third.frame.minY, accuracy: 1)
        XCTAssertLessThan(first.frame.maxX, second.frame.minX)
        XCTAssertLessThan(second.frame.maxX, third.frame.minX)
        XCTAssertLessThan(first.frame.width, app.frame.width * 0.4)
        let tiers: [(Int, String)] = [(400,"$0.99"),(800,"$1.99"),(2450,"$4.99"),(5150,"$9.99"),(10800,"$19.99"),(16800,"$29.99"),(29400,"$49.99"),(42000,"$69.99"),(63700,"$99.99")]
        for (amount, price) in tiers {
            let package = app.buttons["wallet.package.\(amount)"]
            reveal(package)
            XCTAssertTrue(package.isEnabled)
            XCTAssertTrue(package.label.contains(price), "Unexpected localized fixture price: " + package.label)
            if amount == 16800 || amount == 42000 { capture("New tier \(amount)") }
        }
        reveal(first); first.tap()
        let confirmation = app.alerts["400 Diamonds"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.buttons["Cancel"].tap()
        XCTAssertEqual(balance.value as? String, before)
        reveal(first); first.tap()
        confirmation.buttons["Continue"].tap()
        let systemUI = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let sheet = systemUI.otherElements["payment-sheet"]
        let dismiss = sheet.buttons["dismiss"]
        XCTAssertTrue(dismiss.waitForExistence(timeout: 25), "The actual native StoreKit sheet must appear")
        let systemEvidence = XCTAttachment(string: systemUI.debugDescription)
        systemEvidence.name = "Native StoreKit sheet hierarchy"; systemEvidence.lifetime = .keepAlways; add(systemEvidence)
        XCTAssertTrue(sheet.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "400 Diamonds")).firstMatch.exists)
        XCTAssertTrue(sheet.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "$0.99")).firstMatch.exists)
        capture("Native local StoreKit purchase sheet")
        dismiss.tap()
        let notice = app.staticTexts["wallet.purchase-status"]
        let canceled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "Purchase canceled"), object: notice)
        let cancellation = await XCTWaiter.fulfillment(of: [canceled], timeout: 25)
        XCTAssertEqual(cancellation, .completed)
        XCTAssertEqual(balance.value as? String, before)
        XCTAssertTrue(first.isEnabled)
        capture("Canceled purchase preserves the existing balance")
        app.terminate(); app.launch()
    }

    @MainActor
    func testAllNineGridPurchasesCreditAndSurviveRelaunch() async throws {
        let fixture = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TiloDiamonds", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: fixture)
        session.resetToDefaultState(); session.disableDialogs = true
        defer { session.resetToDefaultState() }
        try await openWallet()
        let mode = app.staticTexts["wallet.store-mode"]
        XCTAssertEqual(mode.value as? String, "local")
        let balance = app.staticTexts["wallet.balance"]
        var expected = try XCTUnwrap(Int(balance.value as? String ?? ""))
        let baseline = expected
        let initialPurchases = session.allTransactions().filter { $0.state == .purchased }.count
        let amounts = [400, 800, 2450, 5150, 10800, 16800, 29400, 42000, 63700]
        for (index, amount) in amounts.enumerated() {
            let offer = app.buttons["wallet.package.\(amount)"]
            XCTAssertGreaterThanOrEqual(offer.frame.width, 44)
            XCTAssertGreaterThanOrEqual(offer.frame.height, 44)
            if index % 3 != 0 {
                let prior = app.buttons["wallet.package.\(amounts[index - 1])"]
                XCTAssertEqual(offer.frame.minY, prior.frame.minY, accuracy: 1)
                XCTAssertGreaterThan(offer.frame.minX, prior.frame.maxX)
            }
            reveal(offer); offer.tap()
            let confirmation = app.alerts.firstMatch
            XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
            confirmation.buttons["Continue"].tap()
            expected += amount
            try await expectBalance(expected)
            let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: app.buttons["wallet.package.400"])
            let completed = await XCTWaiter.fulfillment(of: [enabled], timeout: 25)
            XCTAssertEqual(completed, .completed)
        }
        XCTAssertEqual(expected - baseline, 171500)
        XCTAssertEqual(session.allTransactions().filter { $0.state == .purchased }.count - initialPurchases, 9)
        capture("All nine grid offers credited through the app")
        if #available(iOS 17.0, *) {
            try await session.setSimulatedError(.generic(.userCancelled), forAPI: .purchase)
            let offer = app.buttons["wallet.package.400"]; reveal(offer); offer.tap()
            app.alerts.buttons["Continue"].tap()
            let canceled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label CONTAINS %@", "Purchase canceled"), object: app.staticTexts["wallet.purchase-status"])
            let result = await XCTWaiter.fulfillment(of: [canceled], timeout: 25)
            XCTAssertEqual(result, .completed)
            try await expectBalance(expected)
            try await session.setSimulatedError(nil, forAPI: .purchase)
        }
        app.terminate()
        try await openWallet()
        try await expectBalance(expected)
        capture("Grid wallet preserves purchases after relaunch")
    }

    @MainActor
    private func openWallet() async throws {
        app = XCUIApplication(bundleIdentifier: "com.toli.cooking")
        app.launchEnvironment["TILO_STOREKIT_MODE"] = "local"
        app.launch()
        let login = app.buttons["Log in"]
        if login.waitForExistence(timeout: 8) {
            let consent = app.buttons["I am 18+ and accept the agreements"]
            XCTAssertTrue(consent.waitForExistence(timeout: 5))
            if consent.value as? String != "Checked" { consent.tap() }
            login.tap()
        }
        let me = app.buttons["tab-me"]
        XCTAssertTrue(me.waitForExistence(timeout: 45)); me.tap()
        let wallet = app.buttons["My wallet"]
        XCTAssertTrue(wallet.waitForExistence(timeout: 20)); wallet.tap()
        let first = app.buttons["wallet.package.400"]
        let ready = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: first)
        let result = await XCTWaiter.fulfillment(of: [ready], timeout: 35)
        guard result == .completed else { XCTFail("The configured local catalog must enable real purchase controls"); throw NSError(domain: "TiloWalletPurchaseUITests", code: 1) }
    }

    @MainActor
    private func expectBalance(_ amount: Int) async throws {
        let expected = XCTNSPredicateExpectation(predicate: NSPredicate(format: "value == %@", String(amount)), object: app.staticTexts["wallet.balance"])
        let result = await XCTWaiter.fulfillment(of: [expected], timeout: 35)
        guard result == .completed else { XCTFail("The app did not persist the expected wallet balance"); throw NSError(domain: "TiloWalletPurchaseUITests", code: 2) }
    }

    private func reveal(_ element: XCUIElement) {
        for _ in 0..<15 {
            if element.exists && element.isHittable && element.frame.minY > 100 && element.frame.maxY < app.frame.maxY - 50 { return }
            if element.exists && element.frame.minY < 100 { app.swipeDown() }
            else { app.swipeUp() }
        }
        XCTAssertTrue(element.exists && element.isHittable)
    }
    private func capture(_ name: String) {
        let image = XCTAttachment(screenshot: app.screenshot())
        image.name = name; image.lifetime = .keepAlways; add(image)
    }
}
