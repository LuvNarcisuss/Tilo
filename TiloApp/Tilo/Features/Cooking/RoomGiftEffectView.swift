import UIKit

extension TiloRoomGift {
    var artwork: TiloIcon {
        switch id {
        case "warm-thanks": return .heart
        case "chefs-star": return .diamond
        default: return .gift
        }
    }
}

/// A transient visual receipt. It never creates a gift, changes a wallet or intercepts room controls.
final class RoomGiftEffectView: UIView {
    private let receipt: TiloGiftReceipt
    private let artwork = UIImageView()
    private let caption = UILabel()
    private var finished = false
    private var started = false
    private var completion: (() -> Void)?
    private var departure: Task<Void, Never>?

    init(receipt: TiloGiftReceipt) {
        self.receipt = receipt
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        clipsToBounds = true
        isAccessibilityElement = true
        accessibilityIdentifier = "room-gift-effect"
        accessibilityLabel = "Gift recorded: \(receipt.quantity) × \(receipt.giftName)"
        artwork.image = (receipt.gift?.artwork ?? .gift).image(112)
        artwork.contentMode = .scaleAspectFit
        artwork.layer.shadowColor = UIColor.black.cgColor
        artwork.layer.shadowOpacity = 0.35
        artwork.layer.shadowRadius = 12
        artwork.layer.shadowOffset = CGSize(width: 0, height: 4)
        addSubview(artwork)
        caption.text = "\(receipt.giftName) × \(receipt.quantity)"
        let face = TiloTheme.font(23, heading: true)
        caption.font = face.withSize(min(face.pointSize, 28))
        caption.textColor = .white
        caption.textAlignment = .center
        caption.numberOfLines = 2
        caption.layer.shadowColor = UIColor.black.cgColor
        caption.layer.shadowOpacity = 0.9
        caption.layer.shadowRadius = 4
        caption.layer.shadowOffset = CGSize(width: 0, height: 2)
        addSubview(caption)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    override func layoutSubviews() {
        super.layoutSubviews()
        let captionHeight = min(64, max(40, bounds.height * 0.28))
        let side = min(112, max(48, bounds.height - captionHeight - 12))
        let top = max(0, (bounds.height - side - captionHeight - 6) / 2)
        artwork.bounds = CGRect(x: 0, y: 0, width: side, height: side)
        artwork.center = CGPoint(x: bounds.midX, y: top + side / 2)
        caption.frame = CGRect(x: 12, y: artwork.frame.maxY + 6, width: bounds.width - 24, height: captionHeight)
    }
    func play(reduceMotion: Bool = UIAccessibility.isReduceMotionEnabled, completion: @escaping () -> Void) {
        guard !started else { return }
        started = true; self.completion = completion
        layoutIfNeeded()
        if reduceMotion {
            scheduleDeparture(after: 1.8, duration: 0.25, enlarges: false)
            return
        }
        artwork.transform = CGAffineTransform(scaleX: 0.25, y: 0.25).rotated(by: -0.18)
        artwork.alpha = 0
        caption.alpha = 0
        UIView.animate(withDuration: 0.65, delay: 0, usingSpringWithDamping: 0.58, initialSpringVelocity: 0.7, options: [.beginFromCurrentState], animations: { [weak self] in
            self?.artwork.transform = .identity; self?.artwork.alpha = 1; self?.caption.alpha = 1
        })
        let icon = receipt.gift?.artwork ?? .gift
        for index in 0..<12 {
            let sprite = UIImageView(image: (index.isMultiple(of: 3) ? TiloIcon.diamond : icon).image(30))
            sprite.contentMode = .scaleAspectFit
            sprite.bounds = CGRect(x: 0, y: 0, width: 24 + CGFloat(index % 3) * 6, height: 24 + CGFloat(index % 3) * 6)
            sprite.center = CGPoint(x: bounds.midX, y: bounds.height * 0.66)
            sprite.alpha = 0
            insertSubview(sprite, belowSubview: artwork)
            let angle = CGFloat(index) / 11 * .pi
            let travelX = cos(angle) * min(150, bounds.width * 0.43)
            let travelY = -sin(angle) * min(170, bounds.height * 0.7) - 18
            UIView.animate(withDuration: 1.1, delay: 0.1 + Double(index % 4) * 0.08, options: [.curveEaseOut], animations: {
                sprite.alpha = 1
                sprite.transform = CGAffineTransform(translationX: travelX, y: travelY).rotated(by: CGFloat(index - 6) * 0.2)
            }) { _ in UIView.animate(withDuration: 0.5) { sprite.alpha = 0 } }
        }
        scheduleDeparture(after: 2.1, duration: 0.45, enlarges: true)
    }
    private func scheduleDeparture(after delay: Double, duration: Double, enlarges: Bool) {
        departure = Task { [weak self] in
            do { try await Task.sleep(for: .seconds(delay)) } catch { return }
            guard let self, !finished else { return }
            UIView.animate(withDuration: duration, animations: { [weak self] in
                self?.alpha = 0
                if enlarges { self?.artwork.transform = CGAffineTransform(scaleX: 1.15, y: 1.15) }
            }) { [weak self] _ in self?.finish() }
        }
    }
    func cancel() {
        layer.removeAllAnimations()
        subviews.forEach { $0.layer.removeAllAnimations() }
        finish()
    }
    private func finish() {
        guard !finished else { return }
        finished = true
        departure?.cancel(); departure = nil
        removeFromSuperview()
        let callback = completion; completion = nil; callback?()
    }
    deinit { departure?.cancel() }
}
