import PhotosUI
import UIKit

@MainActor
final class MeController: SocialPage {
    private let backend = TiloBackend.shared
    private var profile: Profile?
    private var selection = 0
    private let refresh = UIRefreshControl()
    private var collectionTask: Task<Void, Never>?
    private let collection = UIStackView()
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Me"
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: action("", icon: .settings) { [weak self] in self?.push(SettingsController()) })
        navigationItem.rightBarButtonItem?.customView?.accessibilityLabel = "Settings"
        refresh.tintColor = TiloTheme.red
        refresh.addTarget(self, action: #selector(reload), for: .valueChanged)
        scroll.refreshControl = refresh
        render()
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); reload() }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if isViewLoaded, previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory { render() }
    }
    @objc private func reload() {
        let accountID = backend.userID
        perform { [weak self] in
            guard let self else { return }
            defer { refresh.endRefreshing() }
            try await backend.refreshProfile()
            guard accountID == backend.userID else { return }
            profile = backend.profile
            render()
        }
    }
    private func render() {
        clearContent()
        guard let profile else {
            add(empty("Your kitchen, your story", detail: "Loading your profile and personal collections…", icon: .me))
            add(action("Refresh profile", icon: .clock) { [weak self] in self?.reload() })
            return
        }
        add(socialProfileIdentity(profile))
        add(socialProfileMetrics(profile) { [weak self] kind in self?.push(RelationshipController(userID: profile.id, kind: kind)) })
        add(action("My wallet", icon: .diamond) { [weak self] in self?.push(WalletController()) })
        add(socialPills(["Works", "Liked", "Saved"], selected: selection) { [weak self] index in self?.selection = index; self?.render() })
        let scopes = ["works", "liked", "saved"]
        collection.axis = .vertical
        collection.spacing = 14
        collection.accessibilityIdentifier = "profile-recipe-grid"
        collection.arrangedSubviews.forEach { $0.removeFromSuperview() }
        add(collection)
        loadCollection(scope: scopes[selection], userID: profile.id)
    }
    private func loadCollection(scope: String, userID: UUID) {
        collectionTask?.cancel()
        collection.addArrangedSubview(text("Loading recipes…", 14, color: TiloTheme.muted))
        collectionTask = Task { [weak self] in
            do {
                let recipes = try await TiloBackend.shared.recipeCollection(scope: scope, userID: userID)
                guard let self, !Task.isCancelled, TiloBackend.shared.userID == userID else { return }
                collection.arrangedSubviews.forEach { $0.removeFromSuperview() }
                if recipes.isEmpty {
                    collection.addArrangedSubview(empty("Something delicious starts here", detail: scope == "works" ? "Your published recipes will appear here." : scope == "liked" ? "Like a recipe to keep it in this collection." : "Save a recipe to find it here whenever you are ready to cook.", icon: .recipes))
                }
                collection.addArrangedSubview(recipeGrid(recipes, accessible:traitCollection.preferredContentSizeCategory.isAccessibilityCategory) { [weak self] recipe in self?.push(RecipeDetailController(recipe:recipe)) })
            } catch {
                guard let self, !Task.isCancelled else { return }
                collection.arrangedSubviews.forEach { $0.removeFromSuperview() }
                collection.addArrangedSubview(text(error.localizedDescription, 15, color: TiloTheme.red))
                collection.addArrangedSubview(action("Try again", icon: .clock) { [weak self] in self?.loadCollection(scope: scope, userID: userID) })
            }
        }
    }
    deinit { collectionTask?.cancel() }
}

@MainActor
final class CreatorController: SocialPage {
    let userID: UUID
    private let backend = TiloBackend.shared
    private var profile: Profile?
    private var following = false
    private var recipes: [Recipe] = []
    init(userID: UUID) { self.userID = userID; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Cook profile"
        add(empty("Pull up a chair", detail: "Loading this cook's profile…", icon: .person))
        add(action("Refresh profile", icon: .clock) { [weak self] in self?.reload() })
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); reload() }
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if isViewLoaded, previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory { render() }
    }
    private func reload() {
        perform { [weak self] in
            guard let self, let accountID = backend.userID else { return }
            async let personRequest = backend.fetchProfile(id: userID)
            async let connectionsRequest = backend.relationships(userID: accountID, kind: "following")
            async let worksRequest = backend.recipeCollection(scope: "works", userID: userID)
            let (person, connections, works) = try await (personRequest, connectionsRequest, worksRequest)
            guard backend.userID == accountID else { return }
            profile = person
            following = connections.contains { $0.id == self.userID }
            recipes = works
            render()
        }
    }
    private func render() {
        guard let profile else { return }
        clearContent()
        add(socialProfileIdentity(profile, compact: true))
        add(socialProfileMetrics(profile) { [weak self] kind in self?.push(RelationshipController(userID: profile.id, kind: kind)) })
        if profile.id == backend.userID {
            navigationItem.rightBarButtonItem = nil
        } else {
            let report = action("", icon: .flag) { [weak self] in self?.push(ReportProfileController(userID: profile.id)) }
            report.accessibilityLabel = "Report profile"
            navigationItem.rightBarButtonItem = UIBarButtonItem(customView: report)
            let follow = action(following ? "Following" : "Follow", icon: following ? .check : .plus, filled: !following) { [weak self] in self?.toggleFollow() }
            follow.accessibilityIdentifier = "profile-follow"
            let block = action("", icon: .shield) { [weak self] in self?.confirmBlock() }
            block.accessibilityLabel = "Block cook"
            block.widthAnchor.constraint(equalToConstant: 48).isActive = true
            let accessible = traitCollection.preferredContentSizeCategory.isAccessibilityCategory || view.bounds.width < 375
            let primary = socialStack([follow], axis: accessible ? .vertical : .horizontal, spacing: 8)
            if following {
                let message = action("Message", icon: .chats, filled: true) { [weak self] in self?.openChat() }
                message.accessibilityIdentifier = "profile-message"
                primary.addArrangedSubview(message)
            }
            primary.distribution = .fillEqually
            add(row([primary, block], spacing: 8))
        }
        add(text("Recipes", 22, heading: true))
        if recipes.isEmpty { add(empty("A fresh page", detail: "Published recipes will appear here.", icon: .recipes)) }
        add(recipeGrid(recipes, accessible: traitCollection.preferredContentSizeCategory.isAccessibilityCategory) { [weak self] recipe in self?.push(RecipeDetailController(recipe: recipe)) })
    }
    private func toggleFollow() {
        perform { [weak self] in
            guard let self, let accountID = backend.userID else { return }
            let desired = !following
            try await backend.setFollow(userID: userID, following: desired)
            let current = try await backend.fetchProfile(id: userID)
            let connections = try await backend.relationships(userID: accountID, kind: "following")
            guard accountID == backend.userID else { return }
            following = connections.contains { $0.id == self.userID }
            profile = current
            render()
        }
    }
    private func openChat() {
        perform { [weak self] in
            guard let self, let accountID = backend.userID else { return }
            let connections = try await backend.relationships(userID: accountID, kind: "following")
            guard backend.userID == accountID else { return }
            following = connections.contains { $0.id == self.userID }
            guard following else { render(); message("Follow to message", "Follow this cook before sending a private message."); return }
            let conversation = try await backend.createDirect(userID: userID)
            guard backend.userID == accountID else { return }
            push(ConversationController(conversation: conversation))
        }
    }
    private func confirmBlock() {
        confirm("Block this cook?", detail: "Their profile and content will be hidden and you will no longer be able to message each other.", destructive: "Block") { [weak self] in
            guard let self else { return }
            try await backend.block(userID: userID)
            navigationController?.popToRootViewController(animated: true)
        }
    }
}

@MainActor
private func socialProfileIdentity(_ profile: Profile, compact: Bool = false) -> UIView {
    let avatar = SocialAvatar(url: profile.avatarURL, size: compact ? 76 : 104)
    let name = text(profile.displayName, 30, heading: true)
    name.textAlignment = .center
    let username = text("@" + profile.username, 14, color: TiloTheme.muted)
    username.textAlignment = .center
    let bio = text(profile.bio.isEmpty ? "A new story is cooking." : profile.bio, 16)
    bio.textAlignment = .center
    let labels = socialStack([name, username, bio], spacing: 5)
    if compact { [name, username, bio].forEach { $0.textAlignment = .left } }
    let identity = compact ? socialStack([row([avatar, labels], spacing: 14)], spacing: 10) : socialStack([avatar, name, username, bio], spacing: 10)
    identity.alignment = compact ? .fill : .center
    var tags = profile.dietaryTags
    if profile.isEditorial == true { tags.insert("Editorial kitchen · Illustrative portrait", at: 0) }
    else if !profile.skillLevel.isEmpty { tags.insert(profile.skillLevel, at: 0) }
    if !tags.isEmpty {
        let label = text(tags.joined(separator: " · "), 13, color: TiloTheme.olive)
        label.textAlignment = .center
        identity.addArrangedSubview(label)
    }
    return socialCard([identity])
}

@MainActor
private func socialProfileMetrics(_ profile: Profile, open: @escaping (String) -> Void) -> UIView {
    let values = profile.visibleMetrics
    let titles = ["Likes", "Saves", "Following", "Followers"]
    let accessible = UIApplication.shared.preferredContentSizeCategory.isAccessibilityCategory
    let columns = accessible ? 2 : 4
    let metrics = socialStack(spacing: accessible ? 16 : 0)
    var metricRow: UIStackView?
    for index in 0..<4 {
        if index % columns == 0 {
            let line = socialStack(axis: .horizontal, spacing: accessible ? 12 : 4)
            line.distribution = .fillEqually
            line.alignment = .center
            metrics.addArrangedSubview(line)
            metricRow = line
        }
        let value = text(String(values[index]), 23, heading: true)
        value.textAlignment = .center
        let label = text(titles[index], 11, color: TiloTheme.muted)
        label.textAlignment = .center
        let column = socialStack([value, label], spacing: 4)
        if index >= 2 {
            let button = UIButton(type: .custom)
            button.addSubview(column)
            column.isUserInteractionEnabled = false
            column.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                column.leadingAnchor.constraint(equalTo: button.leadingAnchor), column.trailingAnchor.constraint(equalTo: button.trailingAnchor),
                column.topAnchor.constraint(equalTo: button.topAnchor, constant: 8), column.bottomAnchor.constraint(equalTo: button.bottomAnchor, constant: -8)
            ])
            button.accessibilityLabel = "\(values[index]) \(titles[index])"
            button.accessibilityIdentifier = "profile-metric-" + titles[index].lowercased()
            button.addAction(UIAction { _ in open(index == 2 ? "following" : "followers") }, for: .touchUpInside)
            metricRow?.addArrangedSubview(button)
        } else {
            column.isAccessibilityElement = true
            column.accessibilityLabel = "\(values[index]) received \(titles[index].lowercased())"
            column.accessibilityIdentifier = "profile-metric-" + titles[index].lowercased()
            metricRow?.addArrangedSubview(column)
        }
    }
    return metrics
}

@MainActor
final class EditProfileController: SocialPage, PHPickerViewControllerDelegate {
    private let profile: Profile
    private let name: UITextField
    private let username: UITextField
    private let biography: UITextView
    private let skill: UITextField
    private let dietary: UITextField
    private var imageData: Data?
    private let preview: SocialAvatar
    init(profile: Profile) {
        self.profile = profile
        name = socialField("Display name", value: profile.displayName)
        username = socialField("Username", value: profile.username)
        skill = socialField("Cooking level", value: profile.skillLevel)
        dietary = socialField("Dietary preferences", value: profile.dietaryTags.joined(separator: ", "))
        biography = UITextView()
        preview = SocialAvatar(url: profile.avatarURL, size: 104)
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Edit profile"
        preview.isAccessibilityElement = true; preview.accessibilityIdentifier = "profile-photo-preview"
        preview.accessibilityLabel = "Profile photo"; preview.accessibilityValue = profile.avatarURL == nil ? "Default profile photo" : "Current profile photo"
        let portrait = socialStack([preview])
        portrait.alignment = .center
        add(portrait)
        add(action("Choose profile photo", icon: .camera) { [weak self] in self?.choosePhoto() })
        add(text("Display name", 14, heading: true)); add(name)
        add(text("Username", 14, heading: true)); add(username)
        username.autocapitalizationType = .none
        username.autocorrectionType = .no
        add(text("About your kitchen", 14, heading: true))
        biography.text = profile.bio
        biography.font = TiloTheme.font(16)
        biography.textColor = TiloTheme.ink
        biography.backgroundColor = .white
        biography.round(16)
        biography.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        biography.accessibilityLabel = "About your kitchen"
        biography.fixedHeight(120)
        add(biography)
        add(text("Cooking level", 14, heading: true)); add(skill)
        add(text("Dietary preferences", 14, heading: true)); add(dietary)
        add(text("Separate preferences with commas, such as Vegetarian, Gluten-free.", 13, color: TiloTheme.muted))
        add(action("Save profile", icon: .check, filled: true) { [weak self] in self?.save() })
        scroll.keyboardDismissMode = .interactive
    }
    private func choosePhoto() {
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        present(picker, animated: true)
    }
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true)
        guard let item = results.first?.itemProvider, item.canLoadObject(ofClass: UIImage.self) else { return }
        item.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            Task { @MainActor in
                guard let self else { return }
                guard let image = object as? UIImage else {
                    self.message("Photo unavailable", error?.localizedDescription ?? "Choose a different photo and try again.")
                    return
                }
                let side: CGFloat = 1024
                let scale = min(1, side / max(image.size.width, image.size.height))
                let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                let renderer = UIGraphicsImageRenderer(size: size, format: format)
                let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
                guard let data = resized.jpegData(compressionQuality: 0.86) else { self.message("Photo unavailable", "The selected photo could not be prepared."); return }
                self.imageData = data
                self.preview.image = resized
                self.preview.contentMode = .scaleAspectFill
                self.preview.accessibilityValue = "Selected profile photo"
            }
        }
    }
    private func save() {
        let displayName = (name.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let handle = (username.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let bio = biography.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let level = (skill.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let preferences = (dietary.text ?? "").split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        guard !displayName.isEmpty, displayName.count <= 50, handle.range(of: "^[a-z0-9_]{3,30}$", options: .regularExpression) != nil,
              bio.count <= 300, level.count <= 40, preferences.count <= 10, preferences.allSatisfy({ $0.count <= 40 }) else {
            message("Check your profile", "Use a name up to 50 characters, a 3–30 character username containing letters, numbers or underscores, and a biography up to 300 characters. Add up to ten dietary preferences.")
            return
        }
        view.endEditing(true)
        perform { [weak self] in
            guard let self, TiloBackend.shared.userID == profile.id else { return }
            var avatar: String?
            if let imageData { avatar = try await TiloBackend.shared.uploadAvatar(data: imageData) }
            try await TiloBackend.shared.updateProfile(displayName: displayName, username: handle, bio: bio, dietaryTags: preferences, skillLevel: level, avatarURL: avatar)
            navigationController?.popViewController(animated: true)
        }
    }
}

