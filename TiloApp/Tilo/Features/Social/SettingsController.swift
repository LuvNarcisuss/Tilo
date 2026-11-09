import PDFKit
import UIKit

@MainActor
final class SettingsController: SocialPage {
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        add(text("Make yourself at home.", 29, heading: true))
        add(text("Your account", 19, heading: true))
        add(action("Edit profile", icon: .pencil) { [weak self] in
            guard let profile = TiloBackend.shared.profile else { self?.message("Profile unavailable", "Return to Me and refresh your profile."); return }
            self?.push(EditProfileController(profile: profile))
        })
        add(action("Wallet and transactions", icon: .diamond) { [weak self] in self?.push(WalletController()) })
        add(text("Privacy and safety", 19, heading: true))
        add(action("Blocked cooks", icon: .shield) { [weak self] in self?.push(BlockedPeopleController()) })
        add(action("Hidden content", icon: .shield) { [weak self] in self?.push(HiddenContentController()) })
        add(action("Device permissions", icon: .settings) {
            guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
            UIApplication.shared.open(url)
        })
        add(text("About Tilo", 19, heading: true))
        add(action("Media credits", icon: .camera) { [weak self] in self?.push(MediaCreditsController()) })
        add(action("Terms of Service", icon: .list) { [weak self] in self?.push(TiloPDFController(url: TiloBackendConfiguration.termsURL, title: "Terms of Service")) })
        add(action("Privacy Policy", icon: .shield) { [weak self] in self?.push(TiloPDFController(url: TiloBackendConfiguration.privacyURL, title: "Privacy Policy")) })
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        add(text("Tilo · Version " + version, 13, color: TiloTheme.muted))
        add(action("Log out", icon: .person) { [weak self] in
            self?.confirm("Log out?", detail: "This is a guest account. Once you log out, you may be unable to recover it or its saved content. Your cloud account is not deleted.", destructive: "Log out") {
                try await TiloBackend.shared.signOut()
            }
        })
        add(action("Delete account", icon: .trash) { [weak self] in self?.confirmDeletion() })
    }
    private func confirmDeletion() {
        let first = UIAlertController(title: "Delete your account?", message: "This permanently deletes your Tilo profile and owned cloud data. Other people may retain messages they received. Photos in your device library are not deleted.", preferredStyle: .alert)
        first.addAction(UIAlertAction(title: "Keep account", style: .cancel))
        first.addAction(UIAlertAction(title: "Continue", style: .destructive) { [weak self] _ in
            self?.confirm("Permanently delete account?", detail: "This cannot be undone. Any remaining Diamonds and account access will be lost.", destructive: "Delete account") {
                try await TiloBackend.shared.deleteAccount()
            }
        })
        present(first, animated: true)
    }
}

@MainActor
final class HiddenContentController: SocialPage {
    override func viewDidLoad() { super.viewDidLoad(); title = "Hidden content"; reload() }
    private func reload() {
        perform { [weak self] in
            guard let self else { return }
            let contents = try await TiloBackend.shared.hiddenContents()
            render(contents)
        }
    }
    private func render(_ contents: [HiddenContent]) {
        clearContent()
        if contents.isEmpty { add(text("Nothing hidden",24,heading:true)); add(text("Recipes and replays you hide will appear here.",16,color:TiloTheme.muted)) }
        for content in contents {
            let restore = action("Show again",icon:.check) { [weak self] in
                    self?.perform { [weak self] in
                        try await TiloBackend.shared.unhideContent(content)
                        let contents = try await TiloBackend.shared.hiddenContents()
                        self?.render(contents)
                    }
                }
            restore.accessibilityIdentifier = "show-hidden-" + content.kind + "-" + content.id
            add(socialCard([text(content.title,21,heading:true),restore]))
        }
    }
}

@MainActor
final class BlockedPeopleController: SocialPage {
    override func viewDidLoad() { super.viewDidLoad(); title = "Blocked cooks"; reload() }
    private func reload() {
        perform { [weak self] in
            guard let self else { return }
            let blocked = try await TiloBackend.shared.blockedUsers()
            clearContent()
            if blocked.isEmpty { add(empty("A comfortable kitchen", detail: "You have not blocked anyone. Manage blocked cooks here whenever you need to.", icon: .shield)) }
            for person in blocked {
                let unblock = action("Unblock", icon:.person) { [weak self] in
                    self?.confirm("Unblock " + person.displayName + "?", detail:"Their content may appear again. Previous follows are not automatically restored.", destructive:"Unblock") { [weak self] in
                        try await TiloBackend.shared.unblock(userID:person.id)
                        let remaining = try await TiloBackend.shared.blockedUsers()
                        self?.render(remaining)
                    }
                }
                unblock.accessibilityIdentifier = "Unblock " + person.displayName
                add(socialCard([
                    text(person.displayName, 22, heading: true),
                    unblock
                ]))
            }
        }
    }
    private func render(_ people: [Profile]) {
        clearContent()
        if people.isEmpty { add(empty("A comfortable kitchen", detail: "You have not blocked anyone.", icon: .shield)) }
        for person in people {
            add(action("Unblock " + person.displayName, icon: .person) { [weak self] in
                self?.perform { [weak self] in
                    try await TiloBackend.shared.unblock(userID: person.id)
                    let remaining = try await TiloBackend.shared.blockedUsers()
                    self?.render(remaining)
                }
            })
        }
    }
}

@MainActor
class ReportController: SocialPage {
    private let kind: String
    private let targetID: String
    private var selected = "Harassment or bullying"
    private let reasons = ["Harassment or bullying", "Hate or discrimination", "Sexual content", "Violence or threats", "Spam or scam", "Impersonation", "Other"]
    private let choices = UIStackView()
    private let detail = UITextView()
    init(kind: String, targetID: String) { self.kind = kind; self.targetID = targetID; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = kind == "profile" ? "Report profile" : "Report content"
        add(text("Help keep the table welcoming.", 28, heading: true))
        add(text("Choose a reason and add any details that help explain your concern.", 16, color: TiloTheme.muted))
        choices.axis = .vertical
        choices.spacing = 8
        add(choices)
        renderReasons()
        add(text("Additional details", 14, heading: true))
        detail.font = TiloTheme.font(16)
        detail.textColor = TiloTheme.ink
        detail.backgroundColor = .white
        detail.round(16)
        detail.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        detail.accessibilityLabel = "Report details"
        detail.fixedHeight(130)
        add(detail)
        add(action("Submit report", icon: .flag, filled: true) { [weak self] in
            guard let self else { return }
            let notes = detail.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let reason = selected + (notes.isEmpty ? "" : ": " + notes)
            guard reason.count <= 1_000 else { message("Report is too long", "Keep the complete report within 1,000 characters."); return }
            perform { [weak self] in
                guard let self else { return }
                try await TiloBackend.shared.report(kind: kind, targetID: targetID, reason: reason)
                let confirmation = UIAlertController(title: "Report received", message: "Your report has been submitted.", preferredStyle: .alert)
                confirmation.addAction(UIAlertAction(title: "Done", style: .default) { [weak self] _ in
                    guard let self else { return }
                    if navigationController?.viewControllers.first === self { dismiss(animated: true) }
                    else { navigationController?.popViewController(animated: true) }
                })
                present(confirmation, animated: true)
            }
        })
    }
    private func renderReasons() {
        choices.arrangedSubviews.forEach { $0.removeFromSuperview() }
        for reason in reasons {
            let button = action(reason, icon: selected == reason ? .check : nil, filled: selected == reason) { [weak self] in
                self?.selected = reason; self?.renderReasons()
            }
            button.accessibilityTraits = selected == reason ? [.button, .selected] : [.button]
            choices.addArrangedSubview(button)
        }
    }
}

@MainActor
final class ReportProfileController: ReportController {
    init(userID: UUID) { super.init(kind: "profile", targetID: userID.uuidString) }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
}

@MainActor
final class TiloPDFController: UIViewController {
    private let remoteURL: URL?
    private let documentView = PDFView()
    private let status = UILabel()
    private var task: Task<Void, Never>?
    init(url: URL?, title: String) { remoteURL = url; super.init(nibName: nil, bundle: nil); self.title = title }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad()
        overrideUserInterfaceStyle = .light
        view.backgroundColor = TiloTheme.cream
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: TiloIcon.back.image(), style: .plain, target: self, action: #selector(goBack))
        navigationItem.leftBarButtonItem?.accessibilityLabel = "Back"
        documentView.backgroundColor = TiloTheme.cream
        documentView.autoScales = true
        documentView.displayMode = .singlePageContinuous
        documentView.displayDirection = .vertical
        view.addSubview(documentView)
        status.font = TiloTheme.font(16)
        status.textColor = TiloTheme.muted
        status.numberOfLines = 0
        status.textAlignment = .center
        view.addSubview(status)
        [documentView, status].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            documentView.leadingAnchor.constraint(equalTo: view.leadingAnchor), documentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            documentView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor), documentView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            status.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 28), status.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -28),
            status.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: action("Retry", icon: .clock) { [weak self] in self?.load() })
        load()
    }
    private func load() {
        task?.cancel()
        guard let remoteURL, remoteURL.scheme == "https" else {
            status.text = "This agreement is not available yet. Please try again later."
            return
        }
        status.text = "Loading agreement…"
        task = Task { [weak self] in
            do {
                var request = URLRequest(url: remoteURL, cachePolicy: .reloadIgnoringLocalCacheData)
                request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
                let (data, response) = try await URLSession.shared.data(for: request)
                guard !Task.isCancelled, let self else { return }
                guard let response = response as? HTTPURLResponse, response.statusCode == 200, data.starts(with: Data("%PDF".utf8)), let document = PDFDocument(data: data) else {
                    status.text = "The agreement could not be opened. Please try again."
                    return
                }
                documentView.document = document
                status.text = nil
            } catch {
                guard !Task.isCancelled else { return }
                self?.status.text = "The agreement could not be loaded. " + error.localizedDescription
            }
        }
    }
    @objc private func goBack() { navigationController?.popViewController(animated: true) }
    deinit { task?.cancel() }
}
