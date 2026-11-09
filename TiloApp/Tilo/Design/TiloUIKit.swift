import UIKit
import Combine

enum TiloTheme {
    static let cream = UIColor(red: 1, green: 0.975, blue: 0.93, alpha: 1)
    static let ink = UIColor(red: 0.18, green: 0.22, blue: 0.15, alpha: 1)
    static let red = UIColor(red: 0.74, green: 0.18, blue: 0.12, alpha: 1)
    static let olive = UIColor(red: 0.28, green: 0.36, blue: 0.15, alpha: 1)
    static let muted = UIColor(red: 0.40, green: 0.42, blue: 0.34, alpha: 1)
    static func font(_ size: CGFloat = 16, heading: Bool = false) -> UIFont {
        let face = UIFont(name: heading ? "Kalam-Bold" : "ComicNeue-Regular", size: size)!
        return UIFontMetrics(forTextStyle: heading ? .title2 : .body).scaledFont(for: face)
    }
}

enum TiloIcon: String, CaseIterable {
    case live, recipes, kitchen, chats, me, search, back, close, plus, more, heart, bookmark
    case heartOutline, bookmarkFilled, bookmarkOutline
    case send, gift, diamond, share, settings, bell, camera, microphone, video, speaker, play, pause
    case shield, flag, person, group, trash, pencil, check, clock, calendar, list, info, cutlery
    static func likeState(_ active:Bool) -> TiloIcon { active ? .heart : .heartOutline }
    static func saveState(_ active:Bool) -> TiloIcon { active ? .bookmarkFilled : .bookmarkOutline }
    func image(_ size: CGFloat = 26) -> UIImage {
        guard let original = UIImage(named: "icon-" + rawValue) else { return UIImage() }
        let format = UIGraphicsImageRendererFormat()
        format.opaque = false
        return UIGraphicsImageRenderer(size: CGSize(width: size, height: size), format: format).image { _ in
            original.draw(in: CGRect(x: 0, y: 0, width: size, height: size))
        }.withRenderingMode(.alwaysOriginal)
    }
}

extension UIView {
    func round(_ radius: CGFloat = 22) { layer.cornerRadius = radius; layer.cornerCurve = .continuous; clipsToBounds = true }
    func fixedHeight(_ value: CGFloat) { heightAnchor.constraint(equalToConstant: value).isActive = true }
    func fill(_ parent: UIView) {
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([leadingAnchor.constraint(equalTo: parent.leadingAnchor), trailingAnchor.constraint(equalTo: parent.trailingAnchor), topAnchor.constraint(equalTo: parent.topAnchor), bottomAnchor.constraint(equalTo: parent.bottomAnchor)])
    }
}

@MainActor func text(_ value: String, _ size: CGFloat = 16, heading: Bool = false, color: UIColor = TiloTheme.ink) -> UILabel {
    let label = UILabel(); label.text = value; label.font = TiloTheme.font(size, heading: heading)
    label.textColor = color; label.numberOfLines = 0; label.adjustsFontForContentSizeCategory = true
    if heading { label.accessibilityTraits = .header }
    return label
}

@MainActor func action(_ title: String, icon: TiloIcon? = nil, filled: Bool = false, _ handler: @escaping () -> Void) -> UIButton {
    var config = UIButton.Configuration.plain()
    config.title = title; config.titleLineBreakMode = .byWordWrapping; config.image = icon?.image(); config.imagePadding = 10
    config.baseForegroundColor = filled ? .white : TiloTheme.olive
    config.background.backgroundColor = filled ? TiloTheme.red : UIColor.white.withAlphaComponent(0.84)
    config.background.cornerRadius = 18
    config.contentInsets = NSDirectionalEdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 14)
    config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attrs in
        var result = attrs; result.font = TiloTheme.font(17, heading: false); return result
    }
    let button = UIButton(configuration: config, primaryAction: UIAction { _ in handler() })
    button.titleLabel?.numberOfLines = 0; button.titleLabel?.adjustsFontForContentSizeCategory = true
    button.accessibilityLabel = title; button.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
    return button
}

@MainActor func column(_ views: [UIView], spacing: CGFloat = 12) -> UIStackView {
    let stack = UIStackView(arrangedSubviews: views); stack.axis = .vertical; stack.spacing = spacing; return stack
}
@MainActor func row(_ views: [UIView], spacing: CGFloat = 10) -> UIStackView {
    let stack = UIStackView(arrangedSubviews: views); stack.axis = .horizontal; stack.spacing = spacing; stack.alignment = .center; return stack
}
@MainActor func panel(_ views: [UIView], color: UIColor = .white) -> UIView {
    let wrapper = UIView(); wrapper.backgroundColor = color.withAlphaComponent(0.94); wrapper.round()
    let contents = column(views, spacing: 12); wrapper.addSubview(contents); contents.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([contents.leadingAnchor.constraint(equalTo: wrapper.leadingAnchor, constant: 18), contents.trailingAnchor.constraint(equalTo: wrapper.trailingAnchor, constant: -18), contents.topAnchor.constraint(equalTo: wrapper.topAnchor, constant: 18), contents.bottomAnchor.constraint(equalTo: wrapper.bottomAnchor, constant: -18)])
    return wrapper
}

final class RemotePhoto: UIImageView {
    private static let cache = NSCache<NSURL, UIImage>()
    private var request: Task<Void, Never>?
    init(_ url: String?, height: CGFloat? = 190, aspectRatio: CGFloat? = nil) {
        super.init(frame: .zero); contentMode = .scaleAspectFill; clipsToBounds = true; backgroundColor = TiloTheme.cream; round(18)
        if let aspectRatio { heightAnchor.constraint(equalTo:widthAnchor,multiplier:aspectRatio).isActive = true }
        else if let height { fixedHeight(height) }
        setURL(url)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    func setURL(_ value: String?) {
        request?.cancel(); image = nil
        guard let value, let url = URL(string: value), url.scheme == "https" else { return }
        if let cached = Self.cache.object(forKey: url as NSURL) { image = cached; return }
        request = Task { [weak self] in
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                guard !Task.isCancelled, (response as? HTTPURLResponse)?.statusCode == 200,
                      data.count < 15_000_000, let photo = UIImage(data: data) else { return }
                Self.cache.setObject(photo, forKey: url as NSURL); self?.image = photo
            } catch { self?.accessibilityLabel = "Photo could not load" }
        }
    }
    deinit { request?.cancel() }
}

class TiloPage: UIViewController {
    var backgroundArtwork: UIImage? { UIImage(named: "TiloBackground") }
    let scroll = UIScrollView()
    let content = UIStackView()
    var observations = Set<AnyCancellable>()
    private var scrollBottomConstraint: NSLayoutConstraint?
    override func viewDidLoad() {
        super.viewDidLoad(); overrideUserInterfaceStyle = .light
        view.backgroundColor = TiloTheme.cream
        if let backgroundArtwork {
            let background = UIImageView(image: backgroundArtwork)
            background.contentMode = .scaleAspectFill
            background.isUserInteractionEnabled = false
            view.addSubview(background)
            background.fill(view)
        }
        view.addSubview(scroll); scroll.translatesAutoresizingMaskIntoConstraints = false; scroll.keyboardDismissMode = .interactive; scroll.accessibilityIdentifier = "page-scroll"
        content.axis = .vertical; content.spacing = 18; scroll.addSubview(content); content.translatesAutoresizingMaskIntoConstraints = false
        let bottom = scroll.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor); scrollBottomConstraint = bottom
        NSLayoutConstraint.activate([scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor), scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor), scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), bottom, content.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 20), content.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -20), content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16), content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24), content.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -40)])
        if navigationController?.viewControllers.first !== self {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image: TiloIcon.back.image(), style: .plain, target: self, action: #selector(goBack))
            navigationItem.leftBarButtonItem?.accessibilityLabel = "Back"
        }
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if navigationController?.viewControllers.first === self, navigationController?.presentingViewController != nil, (navigationItem.leftBarButtonItem == nil || navigationItem.leftBarButtonItem?.accessibilityLabel == "Back") {
            navigationItem.leftBarButtonItem = UIBarButtonItem(image:TiloIcon.close.image(),style:.plain,target:self,action:#selector(closeModal))
            navigationItem.leftBarButtonItem?.accessibilityLabel = "Close"
        }
    }
    @objc private func closeModal() { dismiss(animated:true) }
    @objc private func goBack() {
        if navigationController?.viewControllers.first === self, navigationController?.presentingViewController != nil { dismiss(animated:true) }
        else { navigationController?.popViewController(animated:true) }
    }
    func setFooter(_ footer: UIView) {
        scrollBottomConstraint?.isActive = false
        view.addSubview(footer); footer.translatesAutoresizingMaskIntoConstraints = false
        let bottom = scroll.bottomAnchor.constraint(equalTo: footer.topAnchor, constant: -12)
        scrollBottomConstraint = bottom
        NSLayoutConstraint.activate([footer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20), footer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20), footer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor, constant: -12), bottom])
    }
    func add(_ view: UIView) { content.addArrangedSubview(view) }
    func clear() { content.arrangedSubviews.forEach { $0.removeFromSuperview() } }
    func message(_ title: String, _ detail: String) { add(panel([text(title, 23, heading: true), text(detail, 17, color: TiloTheme.muted)])) }
    func push(_ controller: UIViewController) { controller.hidesBottomBarWhenPushed = true; navigationController?.pushViewController(controller, animated: true) }
    func fail(_ error: Error) { showNotice("Please try again", error.localizedDescription) }
    func showNotice(_ title: String, _ detail: String) {
        let alert = UIAlertController(title: title, message: detail, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default)); present(alert, animated: true)
    }
}

func styleNavigation(_ nav: UINavigationController) {
    nav.navigationBar.tintColor = TiloTheme.olive
    nav.navigationBar.isTranslucent = true
    let appearance = UINavigationBarAppearance(); appearance.configureWithTransparentBackground()
    appearance.backgroundColor = .clear
    appearance.backgroundEffect = nil; appearance.shadowColor = .clear
    appearance.titleTextAttributes = [.font: TiloTheme.font(22, heading: true), .foregroundColor: TiloTheme.ink]
    appearance.largeTitleTextAttributes = [.font: TiloTheme.font(34, heading: true), .foregroundColor: TiloTheme.ink]
    nav.navigationBar.standardAppearance = appearance; nav.navigationBar.scrollEdgeAppearance = appearance
    nav.navigationBar.compactAppearance = appearance; nav.navigationBar.compactScrollEdgeAppearance = appearance
}
