import XCTest
import StoreKit
import StoreKitTest
@testable import Tilo

final class TiloPurchaseTests: XCTestCase {
    private var directory: URL!
    private var ledgerURL: URL { directory.appendingPathComponent("wallet.json") }

    override func setUpWithError() throws {
        continueAfterFailure = false
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try FileManager.default.removeItem(at: directory)
    }

    func testStoreEnvironmentsHaveSeparateLedgersAndRejectCrossDelivery() throws {
        let account = UUID(uuidString: "12345678-1234-1234-1234-123456789abc")!
        let apple = TiloWalletStorageScope.apple.fileURL(in: directory, accountID: account)
        let local = TiloWalletStorageScope.localStoreKit.fileURL(in: directory, accountID: account)
        XCTAssertEqual(apple.lastPathComponent, "12345678-1234-1234-1234-123456789abc.json")
        XCTAssertEqual(apple.deletingLastPathComponent(), directory)
        XCTAssertNotEqual(apple, local)
        XCTAssertEqual(local.deletingLastPathComponent().lastPathComponent, "StoreKitTesting")
        XCTAssertTrue(TiloWalletStorageScope.apple.accepts(.production))
        XCTAssertTrue(TiloWalletStorageScope.apple.accepts(.sandbox))
        XCTAssertFalse(TiloWalletStorageScope.apple.accepts(.xcode))
        XCTAssertTrue(TiloWalletStorageScope.localStoreKit.accepts(.xcode))
        XCTAssertFalse(TiloWalletStorageScope.localStoreKit.accepts(.production))
        XCTAssertFalse(TiloWalletStorageScope.localStoreKit.accepts(.sandbox))
        try FileManager.default.createDirectory(at: local.deletingLastPathComponent(), withIntermediateDirectories: true)
        _ = try TiloWalletLedger().delivering(id: "same-id", productID: "zvoxmetxtpphulex", diamonds: 400, quantity: 1, date: Date(), to: local)
        XCTAssertFalse(FileManager.default.fileExists(atPath: apple.path))
        let real = try TiloWalletLedger().delivering(id: "same-id", productID: "zvoxmetxtpphulex", diamonds: 400, quantity: 1, date: Date(), to: apple)
        XCTAssertEqual(real.balance, 400)
    }

    func testDurableDeliveryAndDuplicateAfterReload() throws {
        let initial = TiloWalletLedger()
        let delivered = try initial.delivering(id: "101", productID: "zvoxmetxtpphulex", diamonds: 400, quantity: 2, date: Date(), to: ledgerURL)
        XCTAssertEqual(initial.balance, 0)
        XCTAssertEqual(delivered.balance, 800)
        let reloaded = try JSONDecoder().decode(TiloWalletLedger.self, from: Data(contentsOf: ledgerURL))
        let duplicate = try reloaded.delivering(id: "101", productID: "zvoxmetxtpphulex", diamonds: 400, quantity: 2, date: Date(), to: ledgerURL)
        XCTAssertEqual(duplicate.balance, 800)
        XCTAssertEqual(duplicate.activity.count, 1)
        XCTAssertEqual(duplicate.transactions, ["101"])
    }

    func testOverflowAndInvalidQuantityNeverPersist() throws {
        let initial = TiloWalletLedger()
        for quantity in [0, -1, Int.max] {
            XCTAssertThrowsError(try initial.delivering(id: "102", productID: "zvoxmetxtpphulex", diamonds: 400, quantity: quantity, date: Date(), to: ledgerURL))
            XCTAssertFalse(FileManager.default.fileExists(atPath: ledgerURL.path))
            XCTAssertEqual(initial.balance, 0)
        }
        var full = TiloWalletLedger()
        full.balance = Int.max
        XCTAssertThrowsError(try full.delivering(id: "103", productID: "zvoxmetxtpphulex", diamonds: 400, quantity: 1, date: Date(), to: ledgerURL))
    }

    func testSaveFailureDoesNotPublishAndCanRetry() throws {
        let initial = TiloWalletLedger()
        let blocked = directory.appendingPathComponent("missing/wallet.json")
        XCTAssertThrowsError(try initial.delivering(id: "104", productID: "zvoxmetxtpphulex", diamonds: 400, quantity: 1, date: Date(), to: blocked))
        XCTAssertEqual(initial.balance, 0)
        XCTAssertTrue(initial.transactions.isEmpty)
        let retried = try initial.delivering(id: "104", productID: "zvoxmetxtpphulex", diamonds: 400, quantity: 1, date: Date(), to: ledgerURL)
        XCTAssertEqual(retried.balance, 400)
    }

    @MainActor
    func testSessionEndReservationBlocksConcurrentStoreWorkAndCanRecover() async throws {
        let wallet = TiloWallet()
        try wallet.beginSessionEnd()
        XCTAssertTrue(wallet.endingSession)
        XCTAssertThrowsError(try wallet.beginSessionEnd())
        await wallet.load()
        XCTAssertEqual(wallet.catalogPhase, .idle)
        XCTAssertTrue(wallet.products.isEmpty)
        wallet.cancelSessionEnd()
        XCTAssertFalse(wallet.endingSession)
        try wallet.beginSessionEnd()
        wallet.endSession(preservingReservation: true)
        XCTAssertTrue(wallet.endingSession)
        await wallet.load()
        XCTAssertEqual(wallet.catalogPhase, .idle)
        wallet.endSession()
        XCTAssertFalse(wallet.endingSession)
    }

    @MainActor
    func testCatalogTimeoutReleasesWaiterAndIgnoresLateResult() async throws {
        let request = TiloProductRequest()
        do {
            _ = try await request.fetch(ids: ["zvoxmetxtpphulex"], timeout: 0.01) { _ in
                try await Task.sleep(nanoseconds: 2_000_000_000)
                return []
            }
            XCTFail("A catalog request must time out")
        } catch {
            XCTAssertEqual(error as? WalletError, .catalogTimedOut)
        }
        let next = TiloProductRequest()
        let result = try await next.fetch(ids: ["zvoxmetxtpphulex"]) { _ in [] }
        XCTAssertTrue(result.isEmpty)
    }

    @MainActor
    func testEndingCatalogRequestResumesWaiterOnce() async throws {
        let request = TiloProductRequest()
        let pending = Task {
            try await request.fetch(ids: ["zvoxmetxtpphulex"]) { _ in
                try await Task.sleep(nanoseconds: 2_000_000_000)
                return []
            }
        }
        await Task.yield()
        request.cancel()
        do {
            _ = try await pending.value
            XCTFail("An ended store session must not return products")
        } catch { XCTAssertTrue(error is CancellationError) }
    }

    @MainActor
    func testLocalStoreKitAllNineTiersAndDurableDelivery() async throws {
        let fixture = try XCTUnwrap(Bundle(for: Self.self).url(forResource: "TiloDiamonds", withExtension: "storekit"))
        let session = try SKTestSession(contentsOf: fixture)
        session.resetToDefaultState()
        session.disableDialogs = true
        let expected: [(String, Int, Decimal)] = [
            ("zvoxmetxtpphulex", 400, Decimal(string: "0.99")!),
            ("kkmbaosirntvbmst", 800, Decimal(string: "1.99")!),
            ("tvrtrputxdlcupaf", 2450, Decimal(string: "4.99")!),
            ("wdmsigccwqigfbuv", 5150, Decimal(string: "9.99")!),
            ("qyomdfvoxwmnwffd", 10800, Decimal(string: "19.99")!),
            ("mptqzvnrkdalxwce", 16800, Decimal(string: "29.99")!),
            ("zrailjkjqgtaanyw", 29400, Decimal(string: "49.99")!),
            ("hbxqfnrjvkwtcmza", 42000, Decimal(string: "69.99")!),
            ("bujuisktutcsnouo", 63700, Decimal(string: "99.99")!)
        ]
        let products = try await Product.products(for: expected.map { $0.0 })
        XCTAssertEqual(products.count, 9)
        let observer = Task { for await _ in Transaction.updates { if Task.isCancelled { return } } }
        defer { observer.cancel() }
        var ledger = TiloWalletLedger()
        let account = UUID()
        for (id, diamonds, price) in expected {
            let product = try XCTUnwrap(products.first { $0.id == id })
            XCTAssertEqual(product.price, price)
            XCTAssertEqual(product.type, .consumable)
            let result = try await product.purchase(options: [.appAccountToken(account)])
            guard case .success(.verified(let transaction)) = result else {
                XCTFail("Expected a locally verified consumable transaction for " + id)
                return
            }
            XCTAssertEqual(transaction.appAccountToken, account)
            XCTAssertEqual(transaction.productID, id)
            XCTAssertNil(transaction.revocationDate)
            let before = ledger.balance
            ledger = try ledger.delivering(id: String(transaction.id), productID: id, diamonds: diamonds, quantity: transaction.purchasedQuantity, date: transaction.purchaseDate, to: ledgerURL)
            XCTAssertEqual(ledger.balance, before + diamonds)
            await transaction.finish()
        }
        XCTAssertEqual(ledger.balance, 171500)
        XCTAssertEqual(ledger.activity.count, 9)
        let restored = try JSONDecoder().decode(TiloWalletLedger.self, from: Data(contentsOf: ledgerURL))
        XCTAssertEqual(restored.balance, 171500)
        XCTAssertEqual(restored.transactions.count, 9)
    }
}
