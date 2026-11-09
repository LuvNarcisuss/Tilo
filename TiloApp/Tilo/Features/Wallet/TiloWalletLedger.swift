import Foundation

struct TiloWalletActivity: Codable, Identifiable {
    let id: String
    let amount: Int
    let date: Date
    let productID: String
}

/// Serialized names and the permanent transaction set preserve existing wallet compatibility.
struct TiloWalletLedger: Codable {
    var balance = 0
    var transactions: Set<String> = []
    var activity: [TiloWalletActivity] = []
    var gifts: [TiloGiftReceipt] = []

    init() {}

    private enum CodingKeys: String, CodingKey { case balance, transactions, activity, gifts }
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        balance = try values.decode(Int.self, forKey: .balance)
        transactions = try values.decode(Set<String>.self, forKey: .transactions)
        activity = try values.decode([TiloWalletActivity].self, forKey: .activity)
        gifts = try values.decodeIfPresent([TiloGiftReceipt].self, forKey: .gifts) ?? []
    }

    var isValid: Bool {
        balance >= 0 && activity.allSatisfy { transactions.contains($0.id) && $0.amount > 0 }
            && gifts.allSatisfy(\.isValid) && Set(gifts.map(\.id)).count == gifts.count
    }

    func spendingGift(_ receipt: TiloGiftReceipt, to url: URL) throws -> TiloWalletLedger {
        guard isValid, receipt.isValid else { throw WalletError.invalidGift }
        if let previous = gifts.first(where: { $0.id == receipt.id }) {
            guard previous == receipt else { throw WalletError.invalidGift }
            return self
        }
        guard let configured = TiloRoomGift.all.first(where: { $0.id == receipt.giftID }),
              configured.diamonds == receipt.unitDiamonds, configured.name == receipt.giftName else { throw WalletError.invalidGift }
        guard balance >= receipt.diamonds else { throw WalletError.insufficientBalance }
        var updated = self
        updated.balance -= receipt.diamonds
        updated.gifts.insert(receipt, at: 0)
        try JSONEncoder().encode(updated).write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return updated
    }

    /// Returns a deliverable state only after an atomic save; the caller publishes it before finishing StoreKit.
    func delivering(id: String, productID: String, diamonds: Int, quantity: Int, date: Date, to url: URL) throws -> TiloWalletLedger {
        guard isValid, !id.isEmpty, !productID.isEmpty, diamonds > 0, quantity > 0 else { throw WalletError.invalidLedger }
        if transactions.contains(id) { return self }
        let (credit, creditOverflow) = diamonds.multipliedReportingOverflow(by: quantity)
        let (total, balanceOverflow) = balance.addingReportingOverflow(credit)
        guard !creditOverflow, !balanceOverflow, credit > 0 else { throw WalletError.invalidLedger }
        var updated = self
        updated.balance = total
        updated.transactions.insert(id)
        updated.activity.insert(TiloWalletActivity(id: id, amount: credit, date: date, productID: productID), at: 0)
        let data = try JSONEncoder().encode(updated)
        try data.write(to: url, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        return updated
    }
}

enum WalletError: LocalizedError, Equatable {
    case invalidLedger, unverified, unmapped, accountMismatch, busy, catalogTimedOut, restricted, environmentMismatch
    case invalidGift, insufficientBalance, giftRecipientUnavailable
    var errorDescription: String? {
        switch self {
        case .busy: return "Wait for your wallet update to finish before leaving."
        case .invalidLedger: return "Your wallet could not be saved or read safely. Existing records have been kept."
        case .unverified: return "This transaction could not be verified. No diamonds were added."
        case .unmapped: return "A transaction needs reconciliation before diamonds can be added. It has not been discarded."
        case .accountMismatch: return "This purchase belongs to another saved account. It has not been credited to this account."
        case .catalogTimedOut: return "The App Store took too long to respond. Please refresh prices and try again."
        case .environmentMismatch: return "This transaction belongs to another store environment. It has not been added to this wallet."
        case .restricted: return "In-app purchases are not allowed on this device. Check your App Store restrictions."
        case .invalidGift: return "This gift could not be recorded safely. Your diamonds have not changed."
        case .insufficientBalance: return "You do not have enough diamonds for this gift. Open your wallet to add more."
        case .giftRecipientUnavailable: return "This kitchen cannot receive a gift right now. Your diamonds have not changed."
        }
    }
}
