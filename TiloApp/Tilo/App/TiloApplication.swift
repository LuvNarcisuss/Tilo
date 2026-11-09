import UIKit
import Combine

@main final class TiloAppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting session: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(name: "Tilo", sessionRole: session.role)
        configuration.sceneClass = UIWindowScene.self
        configuration.delegateClass = TiloSceneDelegate.self
        return configuration
    }
}

final class TiloSceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private var ended: NSObjectProtocol?
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options: UIScene.ConnectionOptions) {
        guard let scene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: scene); self.window = window
        window.backgroundColor = WelcomeController.entryBackground; window.overrideUserInterfaceStyle = .light
        showEntry(); window.makeKeyAndVisible()
        ended = NotificationCenter.default.addObserver(forName: Notification.Name("TiloSessionEnded"), object: nil, queue: .main) { [weak self] notification in
            let warning = notification.userInfo?["warning"] as? String
            Task { @MainActor in self?.showEntry(warning:warning) }
        }
    }
    private func showEntry(warning:String? = nil) {
        TiloWallet.shared.endSession()
        let entry = WelcomeController()
        entry.onEntered = { [weak self] in self?.window?.rootViewController = TiloTabsController() }
        let nav = UINavigationController(rootViewController: entry); styleNavigation(nav)
        window?.rootViewController = nav
        if let warning { DispatchQueue.main.async { [weak entry] in entry?.showNotice("Account update",warning) } }
    }
    func sceneDidEnterBackground(_ scene: UIScene) { NotificationCenter.default.post(name: Notification.Name("TiloPausePlayback"), object: nil) }
}

final class WelcomeController: TiloPage, UITextViewDelegate {
    static let entryBackground = UIColor(named: "TiloEntryBackground") ?? TiloTheme.cream
    override var backgroundArtwork: UIImage? { nil }
    var onEntered: (() -> Void)?
    private let brandAccent = UIColor(red: 0.61, green: 0.19, blue: 0.02, alpha: 1)
    private var accepted = false
    private var starting = false
    private var consentButton: UIButton?
    private var consentMark: UIImageView?
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tilo"
        view.backgroundColor = Self.entryBackground
        let mark = UIImageView(image: UIImage(named: "TiloBrandLogo"))
        mark.contentMode = .scaleAspectFit
        mark.round(32)
        mark.accessibilityLabel = "Tilo logo"
        mark.isAccessibilityElement = true

        let heading = text("A little joy.\nA lot of flavor.", 32, heading: true)
        let introduction = text("Cook something lovely. Find your next recipe, plan your week, and share the table.", 18)
        let guestNote = text("Your guest profile is saved on this device. Signing out may lose access to your kitchen.", 16, color: TiloTheme.muted)
        for label in [heading, introduction, guestNote] { label.textAlignment = .center }
        let hero = column([mark, heading, introduction, guestNote], spacing: 16)
        hero.alignment = .center
        add(hero)
        mark.fixedHeight(168)
        mark.widthAnchor.constraint(equalTo: mark.heightAnchor).isActive = true
        for label in [heading, introduction, guestNote] {
            label.widthAnchor.constraint(equalTo: hero.widthAnchor).isActive = true
        }
        let consent = UIButton(type: .custom)
        consent.accessibilityIdentifier = "welcome-consent-checkbox"
        consent.accessibilityLabel = "I am 18+ and accept the agreements"
        consent.accessibilityHint = "Confirm your age and agreement to both linked documents."
        consent.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([consent.widthAnchor.constraint(equalToConstant:44),consent.heightAnchor.constraint(equalToConstant:44)])
        let outline = UIView(); outline.backgroundColor = UIColor.white.withAlphaComponent(0.8)
        outline.layer.cornerRadius = 5; outline.layer.borderWidth = 1.5; outline.layer.borderColor = brandAccent.cgColor
        outline.isUserInteractionEnabled = false; outline.translatesAutoresizingMaskIntoConstraints = false
        consent.addSubview(outline)
        let checkmark = UIImageView(image:TiloIcon.check.image(20)); checkmark.contentMode = .scaleAspectFit
        checkmark.translatesAutoresizingMaskIntoConstraints = false; checkmark.isAccessibilityElement = false; outline.addSubview(checkmark)
        NSLayoutConstraint.activate([outline.leadingAnchor.constraint(equalTo:consent.leadingAnchor,constant:10),outline.topAnchor.constraint(equalTo:consent.topAnchor,constant:2),outline.widthAnchor.constraint(equalToConstant:24),outline.heightAnchor.constraint(equalToConstant:24),checkmark.centerXAnchor.constraint(equalTo:outline.centerXAnchor),checkmark.centerYAnchor.constraint(equalTo:outline.centerYAnchor),checkmark.widthAnchor.constraint(equalToConstant:20),checkmark.heightAnchor.constraint(equalToConstant:20)])
        consent.addAction(UIAction { [weak self] _ in
            guard let self else { return }; self.accepted.toggle(); self.updateConsent()
        },for:.touchUpInside)
        consentButton = consent; consentMark = checkmark; updateConsent()
        let agreements = row([consent,agreementText()],spacing:4); agreements.alignment = .top
        let login = action("Log in", filled: true) { [weak self] in self?.begin() }
        login.configuration?.background.backgroundColor = UIColor(red: 1, green: 0.76, blue: 0.28, alpha: 1)
        login.configuration?.baseForegroundColor = UIColor(red: 0.27, green: 0.13, blue: 0.05, alpha: 1)
        login.heightAnchor.constraint(greaterThanOrEqualToConstant: 54).isActive = true
        setFooter(column([login,agreements],spacing:14))
    }
    private func updateConsent() {
        consentButton?.isSelected = accepted; consentMark?.isHidden = !accepted
        consentButton?.accessibilityValue = accepted ? "Checked" : "Unchecked"
        consentButton?.accessibilityTraits = accepted ? [.button,.selected] : .button
    }
    private func agreementText() -> UITextView {
        let body = UITextView(); body.backgroundColor = .clear
        body.isEditable = false; body.isSelectable = true; body.isScrollEnabled = false
        body.delegate = self; body.textContainerInset = .zero; body.textContainer.lineFragmentPadding = 0
        body.adjustsFontForContentSizeCategory = true; body.accessibilityIdentifier = "welcome-agreement-text"
        let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = 3
        let base: [NSAttributedString.Key:Any] = [.font:TiloTheme.font(16),.foregroundColor:TiloTheme.ink,.paragraphStyle:paragraph]
        let copy = NSMutableAttributedString(string:"I am 18 or older and have read and agree to the ",attributes:base)
        for (index,document) in [("Terms of Service",TiloBackendConfiguration.termsURL),("Privacy Policy",TiloBackendConfiguration.privacyURL)].enumerated() {
            if index > 0 { copy.append(NSAttributedString(string:" and ",attributes:base)) }
            var link = base
            if let url = document.1 { link[.link] = url }
            link[.foregroundColor] = brandAccent; link[.underlineStyle] = NSUnderlineStyle.single.rawValue
            copy.append(NSAttributedString(string:document.0,attributes:link))
        }
        copy.append(NSAttributedString(string:".",attributes:base)); body.attributedText = copy
        body.linkTextAttributes = [.foregroundColor:brandAccent,.underlineStyle:NSUnderlineStyle.single.rawValue]
        return body
    }
    private func openAgreement(_ url:URL) {
        if url == TiloBackendConfiguration.termsURL { openLegal(terms:true) }
        else if url == TiloBackendConfiguration.privacyURL { openLegal(terms:false) }
    }
    func textView(_ textView:UITextView,shouldInteractWith url:URL,in characterRange:NSRange,interaction:UITextItemInteraction) -> Bool {
        if #available(iOS 17.0, *) { return true }
        openAgreement(url); return false
    }
    @available(iOS 17.0, *)
    func textView(_ textView:UITextView,primaryActionFor textItem:UITextItem,defaultAction:UIAction) -> UIAction? {
        guard case .link(let url) = textItem.content else { return defaultAction }
        return UIAction { [weak self] _ in self?.openAgreement(url) }
    }
    private func openLegal(terms: Bool) {
        let url = terms ? TiloBackendConfiguration.termsURL : TiloBackendConfiguration.privacyURL
        guard let url else { showNotice("Agreements unavailable", "The agreements could not load. Please try again later."); return }
        push(TiloPDFController(url: url, title: terms ? "Terms of Service" : "Privacy Policy"))
    }
    private func begin() {
        guard !starting else { return }
        guard accepted else {
            let alert = UIAlertController(title: "Before we cook", message: "Confirm you are at least 18 and accept the Terms of Service and Privacy Policy.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Disagree", style: .cancel))
            alert.addAction(UIAlertAction(title: "Agree and continue", style: .default) { [weak self] _ in self?.accepted = true; self?.updateConsent(); self?.begin() })
            present(alert, animated: true); return
        }
        starting = true; view.isUserInteractionEnabled = false
        let spinner = UIActivityIndicatorView(style: .medium); spinner.startAnimating(); add(spinner)
        Task {
            defer { starting = false; view.isUserInteractionEnabled = true; spinner.removeFromSuperview() }
            do {
                try await TiloBackend.shared.signIn()
                await TiloWallet.shared.load()
                onEntered?()
            } catch { fail(error) }
        }
    }
}

final class TiloTabsController: UIViewController, UINavigationControllerDelegate {
    private var pages: [UINavigationController] = []
    private let dock = UIStackView()
    private var buttons: [UIButton] = []
    private var selected = 0
    private var isVisible = false
    override var shouldAutomaticallyForwardAppearanceMethods:Bool { false }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = TiloTheme.cream
        let roots: [UIViewController] = [LiveController(), RecipesController(), KitchenController(), ChatsController(), MeController()]
        pages = roots.map { root in
            let nav = UINavigationController(rootViewController: root); styleNavigation(nav); nav.delegate = self; nav.additionalSafeAreaInsets.bottom = 80
            addChild(nav); view.addSubview(nav.view); nav.view.fill(view); nav.didMove(toParent: self); return nav
        }
        dock.axis = .horizontal; dock.distribution = .fillEqually; dock.spacing = 0
        dock.backgroundColor = .white; dock.round(28); dock.layer.borderWidth = 1; dock.layer.borderColor = TiloTheme.olive.withAlphaComponent(0.15).cgColor
        view.addSubview(dock); dock.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([dock.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16), dock.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16), dock.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -6), dock.heightAnchor.constraint(equalToConstant: 70)])
        let items: [(TiloIcon, String)] = [(.live,"Live"),(.recipes,"Recipes"),(.kitchen,"Kitchen"),(.chats,"Chats"),(.me,"Me")]
        for (index, item) in items.enumerated() {
            let button = UIButton(type: .custom)
            let image = UIImageView(image: item.0.image(30)); image.contentMode = .scaleAspectFit; image.fixedHeight(30)
            let caption = text(item.1, 12, heading: true); caption.textAlignment = .center; caption.numberOfLines = 1; caption.adjustsFontSizeToFitWidth = true
            let contents = column([image,caption], spacing: 0); contents.isUserInteractionEnabled = false
            button.addSubview(contents); contents.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([contents.leadingAnchor.constraint(equalTo: button.leadingAnchor,constant: 3),contents.trailingAnchor.constraint(equalTo: button.trailingAnchor,constant:-3),contents.centerYAnchor.constraint(equalTo: button.centerYAnchor)])
            button.accessibilityLabel = item.1; button.accessibilityIdentifier = "tab-" + item.1.lowercased(); button.round(22)
            button.addAction(UIAction { [weak self] _ in self?.select(index) }, for: .touchUpInside)
            dock.addArrangedSubview(button); buttons.append(button)
        }
        select(0)
    }
    override func viewWillAppear(_ animated:Bool) {
        super.viewWillAppear(animated); pages[selected].beginAppearanceTransition(true,animated:animated)
    }
    override func viewDidAppear(_ animated:Bool) {
        super.viewDidAppear(animated); pages[selected].endAppearanceTransition(); isVisible = true
    }
    override func viewWillDisappear(_ animated:Bool) {
        super.viewWillDisappear(animated); isVisible = false; pages[selected].beginAppearanceTransition(false,animated:animated)
    }
    override func viewDidDisappear(_ animated:Bool) {
        super.viewDidDisappear(animated); pages[selected].endAppearanceTransition()
    }
    private func select(_ index: Int) {
        guard index != selected || !isVisible else { return }
        let previous = selected
        if isVisible { pages[previous].beginAppearanceTransition(false,animated:false); pages[index].beginAppearanceTransition(true,animated:false) }
        selected = index
        for (i, nav) in pages.enumerated() { nav.view.isHidden = i != index }
        for (i, button) in buttons.enumerated() { button.backgroundColor = i == index ? TiloTheme.cream : .clear; button.accessibilityTraits = i == index ? [.button,.selected] : .button }
        if isVisible { pages[previous].endAppearanceTransition(); pages[index].endAppearanceTransition() }
        updateDock()
    }
    private func updateDock() {
        let nav = pages[selected]; dock.isHidden = nav.viewControllers.count > 1
        nav.additionalSafeAreaInsets.bottom = dock.isHidden ? 0 : 80
        view.bringSubviewToFront(dock)
    }
    func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) { updateDock() }
}
