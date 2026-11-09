import UIKit

/// Bibi-style vertical purchase cards, using Tilo's raster artwork and typography.
final class TiloWalletPackageButton: UIButton {
    private let amountLabel: UILabel
    private let priceLabel: UILabel

    init(amount: Int, price: String, available: Bool, handler: @escaping () -> Void) {
        amountLabel = text(amount.formatted(), 22, heading: true, color: TiloTheme.ink)
        priceLabel = text(price, 16, color: available ? TiloTheme.red : TiloTheme.muted)
        super.init(frame: .zero)
        backgroundColor = UIColor.white.withAlphaComponent(0.95)
        layer.cornerRadius = 18; layer.borderWidth = 1.5
        layer.borderColor = (available ? TiloTheme.olive.withAlphaComponent(0.2) : TiloTheme.muted.withAlphaComponent(0.15)).cgColor
        let image = UIImageView(image: TiloIcon.diamond.image(30)); image.contentMode = .scaleAspectFit
        image.fixedHeight(30); image.isAccessibilityElement = false
        let unit = text("Diamonds", 12, color: TiloTheme.muted)
        let stack = column([image, amountLabel, unit, priceLabel], spacing: 3)
        stack.alignment = .fill; stack.isUserInteractionEnabled = false
        [amountLabel, unit, priceLabel].forEach { $0.textAlignment = .center }
        amountLabel.adjustsFontSizeToFitWidth = true; amountLabel.minimumScaleFactor = 0.7
        priceLabel.adjustsFontSizeToFitWidth = true; priceLabel.minimumScaleFactor = 0.75
        addSubview(stack); stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 6), stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -6),
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 10), stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 118), widthAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
        isEnabled = available; alpha = available ? 1 : 0.65
        isAccessibilityElement = true
        accessibilityLabel = "\(amount.formatted()) Diamonds, \(price)"
        accessibilityIdentifier = "wallet.package.\(amount)"
        addAction(UIAction { _ in handler() }, for: .touchUpInside)
    }
    override var isHighlighted: Bool {
        didSet { backgroundColor = isHighlighted ? TiloTheme.red.withAlphaComponent(0.12) : UIColor.white.withAlphaComponent(0.95) }
    }
    required init?(coder: NSCoder) { return nil }
}
