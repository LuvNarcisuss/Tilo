import XCTest
@testable import Tilo

final class TiloGiftLedgerTests: XCTestCase {
    private var directory: URL!
    private var url: URL { directory.appendingPathComponent("wallet.json") }
    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    override func tearDownWithError() throws { try FileManager.default.removeItem(at: directory) }
    private func receipt(id: UUID = UUID(), quantity: Int = 5, diamonds: Int = 50) -> TiloGiftReceipt {
        TiloGiftReceipt(id: id, giftID: "warm-thanks", giftName: "Warm thanks", unitDiamonds: 10,
                        quantity: quantity, diamonds: diamonds, roomID: "cooking-01", recipientID: UUID(), recipientName: "Tilo Pasta Table", date: Date())
    }
    private func funded() throws -> TiloWalletLedger {
        try TiloWalletLedger().delivering(id: "verified-isolated-credit", productID: "zvoxmetxtpphulex", diamonds: 400, quantity: 1, date: Date(), to: url)
    }
    func testGiftDebitSurvivesReloadAndRetryDoesNotDebitTwice() throws {
        let initial = try funded(), gift = receipt()
        let spent = try initial.spendingGift(gift, to: url)
        XCTAssertEqual(initial.balance, 400)
        XCTAssertEqual(spent.balance, 350)
        XCTAssertEqual(spent.gifts, [gift])
        let restored = try JSONDecoder().decode(TiloWalletLedger.self, from: Data(contentsOf: url))
        let repeated = try restored.spendingGift(gift, to: url)
        XCTAssertEqual(repeated.balance, 350)
        XCTAssertEqual(repeated.gifts.count, 1)
        XCTAssertEqual(repeated.transactions, initial.transactions)
        let creditRetry = try repeated.delivering(id: "verified-isolated-credit", productID: "zvoxmetxtpphulex", diamonds: 400, quantity: 1, date: Date(), to: url)
        XCTAssertEqual(creditRetry.balance, 350)
    }
    func testInsufficientFundsInvalidAmountsAndQuantityLeaveFileUnchanged() throws {
        let ledger = try funded(), before = try Data(contentsOf: url)
        let excessive = TiloGiftReceipt(id: UUID(), giftID: "chefs-star", giftName: "Chef's star", unitDiamonds: 100,
                                       quantity: 5, diamonds: 500, roomID: "cooking-01", recipientID: UUID(), recipientName: "Kitchen", date: Date())
        XCTAssertThrowsError(try ledger.spendingGift(excessive, to: url)) { XCTAssertEqual($0 as? WalletError, .insufficientBalance) }
        for gift in [receipt(quantity: 0, diamonds: 0), receipt(quantity: Int.max, diamonds: Int.max), receipt(diamonds: 1)] {
            XCTAssertThrowsError(try ledger.spendingGift(gift, to: url))
        }
        XCTAssertEqual(try Data(contentsOf: url), before)
        XCTAssertEqual(ledger.balance, 400)
        XCTAssertTrue(ledger.gifts.isEmpty)
    }
    func testSaveFailureAndConflictingRetryPreservePriorBalance() throws {
        let ledger = try funded(), gift = receipt()
        let missing = directory.appendingPathComponent("missing/wallet.json")
        XCTAssertThrowsError(try ledger.spendingGift(gift, to: missing))
        XCTAssertEqual(ledger.balance, 400)
        let spent = try ledger.spendingGift(gift, to: url)
        let conflict = receipt(id: gift.id, quantity: 1, diamonds: 10)
        XCTAssertThrowsError(try spent.spendingGift(conflict, to: url))
        XCTAssertEqual(try JSONDecoder().decode(TiloWalletLedger.self, from: Data(contentsOf: url)).balance, 350)
    }
    func testLegacyPurchaseLedgerDecodesWithoutGiftFields() throws {
        let data = Data("{\"balance\":400,\"transactions\":[\"101\"],\"activity\":[]}".utf8)
        let restored = try JSONDecoder().decode(TiloWalletLedger.self, from: data)
        XCTAssertTrue(restored.isValid)
        XCTAssertEqual(restored.balance, 400)
        XCTAssertEqual(restored.transactions, ["101"])
        XCTAssertTrue(restored.gifts.isEmpty)
        let spent = try restored.spendingGift(receipt(), to: url)
        XCTAssertEqual(spent.balance, 350)
        XCTAssertEqual(spent.transactions, restored.transactions)
    }
    func testHistoricalGiftPriceDoesNotInvalidateStoredWallet() throws {
        let historical = TiloGiftReceipt(id: UUID(), giftID: "retired-gift", giftName: "A past gift", unitDiamonds: 15,
                                        quantity: 2, diamonds: 30, roomID: "past-room", recipientID: UUID(), recipientName: "Past kitchen", date: Date())
        var ledger = TiloWalletLedger(); ledger.gifts = [historical]
        XCTAssertTrue(ledger.isValid)
        XCTAssertThrowsError(try TiloWalletLedger().spendingGift(historical, to: url))
    }
}
