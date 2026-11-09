import UIKit
import StoreKit
import Combine
import OSLog

enum TiloCatalogPhase: String {
    case idle, loading, ready, partial, unavailable, failed, timedOut
}

/// Verified purchases are delivered once to the intended account's atomically saved device ledger.
@MainActor final class TiloWallet: ObservableObject {
    static let shared = TiloWallet()
    @Published private(set) var balance = 0
    @Published private(set) var activity: [TiloWalletActivity] = []
    @Published private(set) var gifts: [TiloGiftReceipt] = []
    @Published private(set) var products: [Product] = []
    @Published private(set) var busy = false
    @Published private(set) var endingSession = false
    @Published private(set) var notice: String?
    @Published private(set) var deliveryNotice: String?
    @Published private(set) var catalogPhase = TiloCatalogPhase.idle
    let storageScope = TiloWalletStorageScope.current
    private var ledger = TiloWalletLedger()
    private var owner: UUID?
    private var updates: Task<Void, Never>?
    private var catalogRequest: TiloProductRequest?
    private var generation = UUID()
    private let logger = Logger(subsystem: "com.toli.cooking", category: "InAppPurchase")
    let configuration: [String: Int] = {
        guard let url = Bundle.main.url(forResource: "PurchaseProducts", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let values = try? JSONDecoder().decode([String: Int].self, from: data) else { return [:] }
        return values.filter { !$0.key.isEmpty && $0.value > 0 }
    }()
    var isConfigured: Bool { !configuration.isEmpty }
    var canRecordGift: Bool { !busy && !endingSession && owner != nil && owner == TiloBackend.shared.userID }
    func loadGiftBalance() throws {
        guard !endingSession, let id = TiloBackend.shared.userID else { throw WalletError.busy }
        if owner == id { return }
        guard !busy else { throw WalletError.busy }
        let url = try location(id)
        let loaded = FileManager.default.fileExists(atPath: url.path)
            ? try JSONDecoder().decode(TiloWalletLedger.self, from: Data(contentsOf: url)) : TiloWalletLedger()
        guard loaded.isValid else { throw WalletError.invalidLedger }
        owner = id; ledger = loaded; publish()
    }
    var orderedProductIDs: [String] { configuration.keys.sorted { configuration[$0, default: 0] < configuration[$1, default: 0] } }
    func canPurchase(_ product: Product) -> Bool {
        !busy && !endingSession && AppStore.canMakePayments && owner != nil && owner == TiloBackend.shared.userID
            && product.type == .consumable && products.contains { $0.id == product.id }
    }
    private func location(_ id: UUID) throws -> URL {
        let root = URL.applicationSupportDirectory.appendingPathComponent("ToliWallet", isDirectory: true)
        let url = storageScope.fileURL(in: root, accountID: id)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        return url
    }
    var diagnostics: String {
        let requested = orderedProductIDs
        let returned = products.map(\.id).sorted()
        let missing = Set(requested).subtracting(returned).sorted()
        return "Tilo StoreKit 2\nBundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")\nMode: \(storageScope.rawValue)\nCatalog: \(catalogPhase.rawValue)\nPayments allowed: \(AppStore.canMakePayments)\nRequested: \(requested.joined(separator: ","))\nReturned: \(returned.joined(separator: ","))\nUnavailable: \(missing.joined(separator: ","))"
    }

    func load(forceReload: Bool = false) async {
        guard !busy, !endingSession, let id = TiloBackend.shared.userID else { return }
        if !forceReload, owner == id, catalogPhase == .ready || catalogPhase == .partial { return }
        let current = generation
        busy = true
        defer { if generation == current { busy = false; catalogRequest = nil } }
        do {
            let url = try location(id)
            let loaded = FileManager.default.fileExists(atPath: url.path)
                ? try JSONDecoder().decode(TiloWalletLedger.self, from: Data(contentsOf: url)) : TiloWalletLedger()
            guard loaded.isValid else { throw WalletError.invalidLedger }
            owner = id; ledger = loaded; publish()
            guard isConfigured else {
                products = []; catalogPhase = .unavailable
                notice = "Recharge is not available yet. Your balance has not changed."
                return
            }
            startObserving()
            deliveryNotice = nil
            for await transaction in Transaction.unfinished {
                guard current == generation, TiloBackend.shared.userID == id else { return }
                do { _ = try await deliver(transaction) }
                catch { deliveryNotice = error.localizedDescription }
            }
            guard current == generation, TiloBackend.shared.userID == id else { return }
            products = []; catalogPhase = .loading; notice = "Loading App Store prices…"
            let request = TiloProductRequest(); catalogRequest = request
            let returned = try await request.fetch(ids: orderedProductIDs)
            guard current == generation, TiloBackend.shared.userID == id else { return }
            products = returned.filter { configuration[$0.id] != nil && $0.type == .consumable }
                .sorted { configuration[$0.id, default: 0] < configuration[$1.id, default: 0] }
            let missing = Set(configuration.keys).subtracting(products.map(\.id))
            catalogPhase = products.isEmpty ? .unavailable : (missing.isEmpty ? .ready : .partial)
            notice = products.isEmpty ? "The App Store did not return any available packages. Refresh prices to try again."
                : (missing.isEmpty ? nil : "Some packages are unavailable. Available packages can still be purchased. Refresh prices to try again.")
            if !AppStore.canMakePayments { notice = WalletError.restricted.localizedDescription }
            logger.info("Catalog \(self.catalogPhase.rawValue, privacy: .public); requested \(self.configuration.count); returned \(self.products.count); unavailable \(missing.sorted().joined(separator: ","), privacy: .public)")
        } catch {
            guard current == generation, TiloBackend.shared.userID == id else { return }
            products = []
            catalogPhase = error as? WalletError == .catalogTimedOut ? .timedOut : .failed
            notice = error is CancellationError ? "The store request was canceled. Refresh prices to try again." : error.localizedDescription
            let value = error as NSError
            logger.error("Catalog failure \(value.domain, privacy: .public) / \(value.code)")
        }
    }

    private func startObserving() {
        guard updates == nil else { return }
        updates = Task { [weak self] in
            for await result in Transaction.updates {
                guard let self, !Task.isCancelled else { return }
                let current = self.generation
                do {
                    let credited = try await self.deliver(result)
                    if credited, self.generation == current {
                        self.deliveryNotice = "Your diamonds have been added to this device's wallet."
                    }
                } catch { if self.generation == current { self.deliveryNotice = error.localizedDescription } }
            }
        }
    }

    func buy(_ product: Product) async {
        guard canPurchase(product), let id = owner, configuration[product.id] != nil else { return }
        let current = generation
        busy = true; deliveryNotice = nil
        defer { if generation == current { busy = false } }
        do {
            let result = try await product.purchase(options: [.appAccountToken(id)])
            guard generation == current, owner == id, TiloBackend.shared.userID == id else { return }
            switch result {
            case .success(let verification):
                let credited = try await deliver(verification)
                guard generation == current else { return }
                deliveryNotice = credited ? "Your diamonds have been added to this device's wallet." : "This purchase has already been added to this device's wallet."
            case .pending: deliveryNotice = "Your purchase is waiting for approval. No diamonds have been added."
            case .userCancelled: deliveryNotice = "Purchase canceled. Your balance has not changed."
            @unknown default: deliveryNotice = "The purchase did not finish. Please check your App Store account."
            }
        } catch {
            if generation == current { deliveryNotice = error.localizedDescription }
        }
    }

    private func deliver(_ result: VerificationResult<Transaction>) async throws -> Bool {
        guard !endingSession else { throw WalletError.busy }
        guard case .verified(let transaction) = result else { throw WalletError.unverified }
        guard storageScope.accepts(transaction.environment) else { throw WalletError.environmentMismatch }
        guard let amount = configuration[transaction.productID], let token = transaction.appAccountToken else { throw WalletError.unmapped }
        guard token == owner, token == TiloBackend.shared.userID else { throw WalletError.accountMismatch }
        guard transaction.revocationDate == nil, transaction.productType == .consumable else { throw WalletError.unmapped }
        let transactionID = String(transaction.id)
        let credited = !ledger.transactions.contains(transactionID)
        ledger = try ledger.delivering(id: transactionID, productID: transaction.productID, diamonds: amount,
                                      quantity: transaction.purchasedQuantity, date: transaction.purchaseDate, to: location(token))
        publish()
        await transaction.finish()
        return credited
    }
    func recordGift(id: UUID, gift: TiloRoomGift, quantity: Int, roomID: String, recipientID: UUID) async throws -> TiloGiftReceipt {
        guard canRecordGift, let account = owner else { throw WalletError.busy }
        guard let configured = TiloRoomGift.all.first(where: { $0 == gift }) else { throw WalletError.invalidGift }
        let amount = try configured.total(quantity: quantity)
        let epoch = generation
        busy = true
        defer { if generation == epoch { busy = false } }
        let context = try await TiloBackend.shared.safetyContext(kind: "video", id: roomID)
        guard epoch == generation, owner == account, TiloBackend.shared.userID == account, !endingSession else { throw WalletError.accountMismatch }
        guard !context.isOwn, context.authorID == recipientID, let name = context.authorName else { throw WalletError.giftRecipientUnavailable }
        let receipt = ledger.gifts.first(where: { $0.id == id }) ?? TiloGiftReceipt(id: id, giftID: gift.id, giftName: gift.name, unitDiamonds: gift.diamonds, quantity: quantity, diamonds: amount,
            roomID: roomID, recipientID: recipientID, recipientName: name, date: Date())
        guard receipt.giftID == gift.id, receipt.quantity == quantity, receipt.roomID == roomID, receipt.recipientID == recipientID else { throw WalletError.invalidGift }
        ledger = try ledger.spendingGift(receipt, to: location(account))
        publish()
        return receipt
    }
    private func publish() { balance = ledger.balance; activity = ledger.activity; gifts = ledger.gifts }

    /// Reserve the session synchronously before logout/deletion performs its first network await.
    func beginSessionEnd() throws {
        guard !busy, !endingSession else { throw WalletError.busy }
        endingSession = true
    }
    func cancelSessionEnd() { endingSession = false }

    func deleteLocalAccount(_ accountID: UUID) throws {
        guard !busy else { throw WalletError.busy }
        let root = URL.applicationSupportDirectory.appendingPathComponent("ToliWallet", isDirectory: true)
        for scope in [TiloWalletStorageScope.apple, .localStoreKit] {
            let path = scope.fileURL(in: root, accountID: accountID)
            if FileManager.default.fileExists(atPath: path.path) { try FileManager.default.removeItem(at: path) }
        }
        if owner == accountID { endSession(preservingReservation: true) }
    }
    func endSession(preservingReservation: Bool = false) {
        let reservation = preservingReservation && endingSession
        generation = UUID(); catalogRequest?.cancel(); catalogRequest = nil
        updates?.cancel(); updates = nil; owner = nil; products = []; busy = false; endingSession = reservation
        notice = nil; deliveryNotice = nil; catalogPhase = .idle
        ledger = TiloWalletLedger(); publish()
    }
    deinit { updates?.cancel() }
}

final class WalletController: TiloPage {
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Wallet"
        TiloWallet.shared.objectWillChange.receive(on: DispatchQueue.main).sink { [weak self] _ in
            Task { @MainActor in self?.render() }
        }.store(in: &observations)
        render(); Task { await TiloWallet.shared.load() }
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if isViewLoaded, previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory { render() }
    }
    private func render() {
        clear(); content.spacing = 14
        let wallet = TiloWallet.shared
        let gem = UIImageView(image: TiloIcon.diamond.image(52)); gem.contentMode = .scaleAspectFit
        gem.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([gem.widthAnchor.constraint(equalToConstant: 52), gem.heightAnchor.constraint(equalToConstant: 52)])
        let balance = text("\(wallet.balance.formatted()) Diamonds", 28, heading: true, color: TiloTheme.red)
        balance.accessibilityIdentifier = "wallet.balance"; balance.accessibilityValue = String(wallet.balance)
        add(panel([row([gem, column([text("Your balance", 16, color: TiloTheme.muted), balance], spacing: 2)], spacing: 16)]))
        if wallet.storageScope == .localStoreKit {
            let mode = text("StoreKit testing · No real charges", 14, color: TiloTheme.olive)
            mode.accessibilityIdentifier = "wallet.store-mode"; mode.accessibilityValue = "local"
            add(mode)
        }
        add(text("Recharge", 26, heading: true))
        if let notice = wallet.notice { add(panel([text(notice, 15)])) }
        if let notice = wallet.deliveryNotice {
            let label = text(notice, 16); label.accessibilityIdentifier = "wallet.purchase-status"; add(panel([label]))
        }
        let grid = column([], spacing: 10); grid.accessibilityIdentifier = "wallet.grid"
        let ids = wallet.orderedProductIDs
        let columns = traitCollection.preferredContentSizeCategory.isAccessibilityCategory ? 1 : 3
        for start in stride(from: 0, to: ids.count, by: columns) {
            let line = row([], spacing: 10); line.distribution = .fillEqually; line.alignment = .fill
            for id in ids[start..<min(start + columns, ids.count)] {
                let quantity = wallet.configuration[id, default: 0]
                let product = wallet.products.first { $0.id == id }
                let price = product?.displayPrice ?? (wallet.catalogPhase == .loading ? "Loading…" : "Unavailable")
                let tile = TiloWalletPackageButton(amount: quantity, price: price, available: product.map { wallet.canPurchase($0) } ?? false) { [weak self] in
                    if let product { self?.confirm(product) }
                }
                line.addArrangedSubview(tile)
            }
            grid.addArrangedSubview(line)
        }
        add(grid)
        let refresh = action("Refresh prices", icon: .diamond) { Task { await TiloWallet.shared.load(forceReload: true) } }
        refresh.accessibilityIdentifier = "wallet.refresh"; refresh.isEnabled = !wallet.busy && !wallet.endingSession
        refresh.accessibilityValue = wallet.catalogPhase.rawValue; add(refresh)
        #if DEBUG
        if wallet.catalogPhase != .ready && wallet.catalogPhase != .loading {
            add(action("Copy Store Diagnostics") { UIPasteboard.general.string = wallet.diagnostics })
        }
        #endif
        add(text("Wallet activity", 25, heading: true))
        if wallet.activity.isEmpty && wallet.gifts.isEmpty { add(text("No transactions yet.", 16, color: TiloTheme.muted)) }
        var entries: [(Date, String, UIView)] = []
        for item in wallet.activity {
            let entry = panel([text("+\(item.amount.formatted()) Diamonds", 20, heading: true), text(walletDate(item.date), 14, color: TiloTheme.muted)])
            entry.accessibilityIdentifier = "wallet.transaction.\(item.id)"; entries.append((item.date, item.id, entry))
        }
        for gift in wallet.gifts {
            let entry = panel([text("−\(gift.diamonds.formatted()) Diamonds", 20, heading: true),
                text("\(gift.quantity) × \(gift.giftName) · \(gift.recipientName)", 15),
                text(walletDate(gift.date), 14, color: TiloTheme.muted)])
            entry.accessibilityIdentifier = "wallet.gift.\(gift.id.uuidString.lowercased())"
            entries.append((gift.date, gift.id.uuidString, entry))
        }
        for entry in entries.sorted(by: { $0.0 == $1.0 ? $0.1 < $1.1 : $0.0 > $1.0 }) { add(entry.2) }
        let detail = wallet.storageScope == .localStoreKit
            ? "These purchases use Xcode's StoreKit environment and an isolated wallet. Your App Store wallet is unchanged."
            : "Diamonds are consumables purchased through the App Store. This wallet is saved with this device and account. Cross-device recovery and transfers are not available."
        add(text(detail, 14, color: TiloTheme.muted))
    }
    private func confirm(_ product: Product) {
        let wallet = TiloWallet.shared
        guard wallet.canPurchase(product), let amount = wallet.configuration[product.id] else { return }
        let alert = UIAlertController(title: "\(amount.formatted()) Diamonds", message: "Purchase for \(product.displayPrice)? Apple will ask you to confirm.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in Task { await TiloWallet.shared.buy(product) } })
        present(alert, animated: true)
    }
}

private func walletDate(_ date: Date) -> String {
    let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US"); formatter.dateStyle = .medium; formatter.timeStyle = .short
    return formatter.string(from: date)
}
