import UIKit
import Combine

final class RoomGiftsController: TiloPage {
    private let video: CookingVideo
    private let accountID = TiloBackend.shared.userID
    private let wallet = TiloWallet.shared
    private let onRecorded: (TiloGiftReceipt) -> Void
    private var selected = 0
    private var quantity = 1
    private var recipientID: UUID?
    private var recipientName: String?
    private var preparing = false
    private var sending = false
    private var issue: String?
    private var status: String?
    private var preparation: Task<Void, Never>?
    private var observation: AnyCancellable?
    private let sendFooter = UIStackView()

    init(video: CookingVideo, onRecorded: @escaping (TiloGiftReceipt) -> Void) {
        self.video = video; self.onRecorded = onRecorded
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad(); title = "Send a gift"
        view.accessibilityIdentifier = "gift-panel"
        content.spacing = 8
        sendFooter.axis = .vertical
        setFooter(sendFooter)
        observation = wallet.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.render() }
        }
        render()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); configureSheet(wallet: false); prepare() }
    private func configureSheet(wallet: Bool) {
        guard let sheet = navigationController?.sheetPresentationController else { return }
        sheet.animateChanges {
            sheet.detents = wallet ? [.large()] : [.medium()]
            sheet.selectedDetentIdentifier = wallet ? .large : .medium
            sheet.largestUndimmedDetentIdentifier = wallet ? nil : .medium
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersGrabberVisible = true
        }
    }
    private func openWallet() {
        guard !sending else { return }
        configureSheet(wallet: true)
        push(WalletController())
    }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if isViewLoaded, previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory { render() }
    }
    private func prepare() {
        guard !sending else { return }
        preparation?.cancel(); preparing = true; issue = nil; recipientID = nil; render()
        preparation = Task { [weak self] in
            guard let self else { return }
            do {
                try wallet.loadGiftBalance()
                let context = try await TiloBackend.shared.safetyContext(kind: "video", id: video.id)
                guard !Task.isCancelled, TiloBackend.shared.userID == accountID else { return }
                guard !context.isOwn, let id = context.authorID, let name = context.authorName else { throw WalletError.giftRecipientUnavailable }
                recipientID = id; recipientName = name
            } catch {
                guard !Task.isCancelled else { return }
                issue = error.localizedDescription
            }
            preparing = false; render()
        }
    }
    private func render() {
        guard isViewLoaded else { return }
        clear()
        sendFooter.arrangedSubviews.forEach { $0.removeFromSuperview() }
        let accessible = traitCollection.preferredContentSizeCategory.isAccessibilityCategory
        let balance = action(wallet.balance.formatted(), icon: .diamond) { [weak self] in self?.openWallet() }
        balance.accessibilityIdentifier = "gift.balance"; balance.accessibilityValue = String(wallet.balance)
        balance.accessibilityLabel = "\(wallet.balance.formatted()) Diamonds · My wallet"
        balance.isEnabled = !sending
        let recipient = text(recipientName.map { "For " + $0 } ?? (preparing ? "Loading this kitchen…" : "Choose a gift"), 13, color: TiloTheme.muted)
        let header = UIStackView(arrangedSubviews: [recipient, balance]); header.spacing = 8
        header.axis = accessible ? .vertical : .horizontal; header.alignment = .fill
        balance.setContentCompressionResistancePriority(.required, for: .horizontal)
        add(header)
        let grid = UIStackView(); grid.axis = accessible ? .vertical : .horizontal
        grid.distribution = .fillEqually; grid.spacing = 8
        for (index, gift) in TiloRoomGift.all.enumerated() {
            let button = UIButton(type: .custom)
            button.backgroundColor = UIColor.white.withAlphaComponent(0.85); button.round(16)
            let image = UIImageView(image: gift.artwork.image(28)); image.contentMode = .scaleAspectFit
            image.fixedHeight(28)
            let name = text(gift.name, 14); name.textAlignment = .center; name.numberOfLines = 2
            name.heightAnchor.constraint(equalToConstant: ceil(name.font.lineHeight * 2)).isActive = true
            let price = text("\(gift.diamonds) Diamonds", 12, color: TiloTheme.olive); price.textAlignment = .center
            let contents = column([image, name, price], spacing: 2)
            contents.isUserInteractionEnabled = false; button.addSubview(contents)
            contents.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                contents.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 6), contents.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -6),
                contents.topAnchor.constraint(equalTo: button.topAnchor, constant: 6), contents.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -6)
            ])
            button.addAction(UIAction { [weak self] _ in self?.selected = index; self?.status = nil; self?.render() }, for: .touchUpInside)
            button.accessibilityLabel = gift.name + ", \(gift.diamonds) Diamonds"
            button.accessibilityIdentifier = "gift.choice." + gift.id
            button.isSelected = selected == index
            button.accessibilityValue = selected == index ? "Selected" : "Not selected"
            button.layer.borderWidth = selected == index ? 2 : 0
            button.layer.borderColor = TiloTheme.red.cgColor
            button.isEnabled = !sending
            grid.addArrangedSubview(button)
        }
        add(grid)
        let quantities = UIStackView(); quantities.axis = accessible ? .vertical : .horizontal; quantities.spacing = 8; quantities.distribution = .fillEqually
        for count in [1, 5, 10] {
            let button = action("\(count) gift" + (count == 1 ? "" : "s"), filled: quantity == count) { [weak self] in self?.quantity = count; self?.status = nil; self?.render() }
            button.isSelected = quantity == count; button.accessibilityValue = quantity == count ? "Selected" : "Not selected"
            button.accessibilityIdentifier = "gift.quantity.\(count)"; button.isEnabled = !sending
            quantities.addArrangedSubview(button)
        }
        add(quantities)
        let gift = TiloRoomGift.all[selected]
        let total = (try? gift.total(quantity: quantity)) ?? 0
        let summary = text("\(total.formatted()) Diamonds", 17, heading: true)
        summary.accessibilityLabel = "Total: \(total.formatted()) Diamonds"
        summary.accessibilityIdentifier = "gift.total"; summary.accessibilityValue = String(total)
        if accessible { add(summary) }
        if let issue {
            add(text(issue, 15, color: TiloTheme.red))
            add(action("Try again", icon: .clock) { [weak self] in self?.prepare() })
        }
        if let status {
            let label = text(status, 16, color: TiloTheme.olive)
            label.accessibilityIdentifier = "gift.status"; add(label)
        }
        let send = action(sending ? "Recording gift…" : "Send gift", icon: .gift, filled: true) { [weak self] in self?.confirm() }
        send.accessibilityIdentifier = "gift.send"
        send.isEnabled = recipientID != nil && !preparing && !sending && wallet.canRecordGift
        if accessible { sendFooter.addArrangedSubview(send) }
        else {
            let controls = row([summary, send], spacing: 12)
            send.setContentCompressionResistancePriority(.required, for: .horizontal)
            send.widthAnchor.constraint(greaterThanOrEqualTo: controls.widthAnchor, multiplier: 0.5).isActive = true
            sendFooter.addArrangedSubview(controls)
        }
        let scope = wallet.storageScope == .localStoreKit ? "Local StoreKit wallet" : "Device wallet"
        let scopeLabel = text(scope + " · Recorded on this device.", 11, color: TiloTheme.muted)
        scopeLabel.accessibilityIdentifier = "gift.scope"; scopeLabel.accessibilityValue = wallet.storageScope.rawValue
        add(scopeLabel)
    }
    private func confirm() {
        guard let recipientID, let recipientName, wallet.canRecordGift, !sending, accountID == TiloBackend.shared.userID else { return }
        let gift = TiloRoomGift.all[selected], count = quantity
        guard let total = try? gift.total(quantity: count) else { return }
        guard wallet.balance >= total else {
            let alert = UIAlertController(title: "Not enough diamonds", message: "You need \((total - wallet.balance).formatted()) more Diamonds for this gift.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "My wallet", style: .default) { [weak self] _ in self?.openWallet() })
            present(alert, animated: true); return
        }
        let alert = UIAlertController(title: "Send gift?", message: "Record \(count) × \(gift.name) for \(recipientName) using \(total.formatted()) Diamonds from this wallet?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        let intent = UUID()
        alert.addAction(UIAlertAction(title: "Send", style: .default) { [weak self] _ in self?.send(id: intent, gift: gift, quantity: count, recipientID: recipientID) })
        present(alert, animated: true)
    }
    private func send(id: UUID, gift: TiloRoomGift, quantity: Int, recipientID: UUID) {
        guard !sending else { return }
        sending = true; issue = nil; status = nil; navigationController?.isModalInPresentation = true
        navigationItem.leftBarButtonItem?.isEnabled = false; render()
        Task { [weak self] in
            guard let self else { return }
            defer { sending = false; navigationController?.isModalInPresentation = false; navigationItem.leftBarButtonItem?.isEnabled = true; render() }
            do {
                let receipt = try await wallet.recordGift(id: id, gift: gift, quantity: quantity, roomID: video.id, recipientID: recipientID)
                guard accountID == TiloBackend.shared.userID else { return }
                status = "Recorded \(receipt.quantity) × \(gift.name) in this wallet."
                onRecorded(receipt)
                UIAccessibility.post(notification: .announcement, argument: status)
            } catch { issue = error.localizedDescription }
        }
    }
    deinit { preparation?.cancel() }
}
