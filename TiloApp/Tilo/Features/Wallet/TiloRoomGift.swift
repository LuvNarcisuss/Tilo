import Foundation

struct TiloRoomGift: Equatable {
    let id: String
    let name: String
    let diamonds: Int

    static let all = [
        TiloRoomGift(id: "warm-thanks", name: "Warm thanks", diamonds: 10),
        TiloRoomGift(id: "kitchen-cheer", name: "Kitchen cheer", diamonds: 50),
        TiloRoomGift(id: "chefs-star", name: "Chef's star", diamonds: 100)
    ]

    func total(quantity: Int) throws -> Int {
        guard (1...99).contains(quantity) else { throw WalletError.invalidGift }
        let (value, overflow) = diamonds.multipliedReportingOverflow(by: quantity)
        guard !overflow, value > 0 else { throw WalletError.invalidGift }
        return value
    }
}

/// A device-wallet debit, not a remote recipient credit or payout receipt.
struct TiloGiftReceipt: Codable, Identifiable, Equatable {
    let id: UUID
    let giftID: String
    let giftName: String
    let unitDiamonds: Int
    let quantity: Int
    let diamonds: Int
    let roomID: String
    let recipientID: UUID
    let recipientName: String
    let date: Date

    var gift: TiloRoomGift? { TiloRoomGift.all.first { $0.id == giftID } }
    var isValid: Bool {
        guard (1...99).contains(quantity), unitDiamonds > 0, !giftID.isEmpty, !giftName.isEmpty else { return false }
        let (total, overflow) = unitDiamonds.multipliedReportingOverflow(by: quantity)
        return !overflow && total == diamonds && !roomID.isEmpty && !recipientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
