import UIKit

@MainActor
func socialStack(_ views: [UIView] = [], axis: NSLayoutConstraint.Axis = .vertical, spacing: CGFloat = 12) -> UIStackView {
    let stack = UIStackView(arrangedSubviews: views)
    stack.axis = axis
    stack.spacing = spacing
    return stack
}

@MainActor
func socialCard(_ views: [UIView], color: UIColor = .white) -> UIView {
    let stack = socialStack(views, spacing: 16)
    stack.isLayoutMarginsRelativeArrangement = true
    stack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 22, leading: 20, bottom: 22, trailing: 20)
    stack.backgroundColor = color
    stack.round(24)
    return stack
}

@MainActor
func socialField(_ placeholder: String, value: String = "") -> UITextField {
    let field = UITextField()
    field.text = value
    field.placeholder = placeholder
    field.accessibilityLabel = placeholder
    field.font = TiloTheme.font(16)
    field.adjustsFontForContentSizeCategory = true
    field.textColor = TiloTheme.ink
    field.backgroundColor = .white
    field.borderStyle = .roundedRect
    field.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
    return field
}

@MainActor
func socialPills(_ titles: [String], selected: Int, changed: @escaping (Int) -> Void) -> UIView {
    let scroll = UIScrollView()
    scroll.showsHorizontalScrollIndicator = false
    let stack = socialStack(axis: .horizontal, spacing: 8)
    for (index, title) in titles.enumerated() {
        let button = action(title, filled: index == selected) { changed(index) }
        button.accessibilityTraits = index == selected ? [.button, .selected] : [.button]
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        stack.addArrangedSubview(button)
    }
    scroll.addSubview(stack)
    stack.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor),
        stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor),
        stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor),
        stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor),
        stack.heightAnchor.constraint(equalTo: scroll.frameLayoutGuide.heightAnchor),
        scroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 48)
    ])
    return scroll
}

@MainActor
final class PublisherAvatarButton: UIButton {
    init(publisher: PublisherSummary, contentID: String) {
        super.init(frame: .zero)
        let avatar = SocialAvatar(url: publisher.avatarURL, size: 40)
        avatar.isUserInteractionEnabled = false
        addSubview(avatar)
        backgroundColor = TiloTheme.cream
        round(23)
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 2
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 46), heightAnchor.constraint(equalToConstant: 46),
            avatar.centerXAnchor.constraint(equalTo: centerXAnchor), avatar.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        accessibilityIdentifier = "publisher-avatar-" + contentID
        accessibilityLabel = "View " + publisher.displayName + " profile"
        accessibilityHint = "Opens the publisher's profile."
        addAction(UIAction { [weak self] _ in
            var responder: UIResponder? = self
            while let current = responder {
                if let controller = current as? UIViewController {
                    guard (controller as? CreatorController)?.userID != publisher.id else { return }
                    let profile = CreatorController(userID: publisher.id)
                    profile.hidesBottomBarWhenPushed = true
                    controller.navigationController?.pushViewController(profile, animated: true)
                    return
                }
                responder = current.next
            }
        }, for: .touchUpInside)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}

@MainActor
final class SocialAvatar: UIImageView {
    private var task: Task<Void, Never>?
    init(url: String?, size: CGFloat = 58, group: Bool = false) {
        super.init(frame: .zero)
        image = (group ? TiloIcon.group : TiloIcon.person).image(size * 0.62)
        contentMode = .scaleAspectFit
        backgroundColor = TiloTheme.cream
        round(size / 2)
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([widthAnchor.constraint(equalToConstant: size), heightAnchor.constraint(equalToConstant: size)])
        isAccessibilityElement = false
        guard let url, let remote = URL(string: url), remote.scheme == "https" else { return }
        task = Task { [weak self] in
            do {
                let (data, response) = try await URLSession.shared.data(from: remote)
                guard !Task.isCancelled, let response = response as? HTTPURLResponse, response.statusCode == 200, data.count <= 10_485_760,
                      let photo = UIImage(data: data) else { return }
                self?.image = photo
                self?.contentMode = .scaleAspectFill
            } catch { }
        }
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    deinit { task?.cancel() }
}

@MainActor
class SocialPage: TiloPage {
    private var working = false
    func perform(_ operation: @escaping () async throws -> Void) {
        guard !working else { return }
        working = true
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = TiloTheme.red
        spinner.startAnimating()
        let previous = navigationItem.rightBarButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: spinner)
        Task { [weak self] in
            defer {
                self?.working = false
                if self?.navigationItem.rightBarButtonItem?.customView === spinner {
                    self?.navigationItem.rightBarButtonItem = previous
                }
            }
            do { try await operation() }
            catch { self?.fail(error) }
        }
    }
    func confirm(_ title: String, detail: String, destructive: String, operation: @escaping () async throws -> Void) {
        let alert = UIAlertController(title: title, message: detail, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: destructive, style: .destructive) { [weak self] _ in self?.perform(operation) })
        present(alert, animated: true)
    }
    func clearContent() {
        content.arrangedSubviews.forEach { $0.removeFromSuperview() }
    }
    func empty(_ title: String, detail: String, icon: TiloIcon = .chats) -> UIView {
        let image = UIImageView(image: icon.image(88))
        image.contentMode = .scaleAspectFit
        image.fixedHeight(112)
        image.isAccessibilityElement = false
        let heading = text(title, 25, heading: true)
        heading.textAlignment = .center
        let caption = text(detail, 16, color: TiloTheme.muted)
        caption.textAlignment = .center
        return socialCard([image, heading, caption])
    }
}

@MainActor
func socialDate(_ value: String) -> String {
    let fractional = ISO8601DateFormatter()
    fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let date = fractional.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    guard let date else { return "" }
    let format = DateFormatter()
    format.locale = Locale(identifier: "en_US")
    format.dateStyle = Calendar.current.isDateInToday(date) ? .none : .short
    format.timeStyle = .short
    return format.string(from: date)
}

@MainActor
func styleSocialSearch(_ search: UISearchBar) {
    search.searchTextField.font = TiloTheme.font(16)
    search.searchTextField.adjustsFontForContentSizeCategory = true
    search.searchTextField.textColor = TiloTheme.ink
    search.searchTextField.attributedPlaceholder = NSAttributedString(
        string: search.placeholder ?? "Search", attributes: [.font: TiloTheme.font(16), .foregroundColor: TiloTheme.muted]
    )
    search.setImage(TiloIcon.search.image(20), for: .search, state: .normal)
    search.setImage(TiloIcon.close.image(20), for: .clear, state: .normal)
    search.setImage(TiloIcon.close.image(20), for: .clear, state: .highlighted)
    let cancel = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UISearchBar.self])
    for state in [UIControl.State.normal, .highlighted, .disabled] {
        cancel.setTitleTextAttributes([.font: TiloTheme.font(16), .foregroundColor: TiloTheme.olive], for: state)
    }
}
