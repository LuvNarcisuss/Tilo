import UIKit

@MainActor
final class PeopleController: SocialPage, UISearchBarDelegate {
    private let search = UISearchBar()
    private let results = UIStackView()
    private var task: Task<Void, Never>?
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Find people"
        add(text("Find your kind of cook.", 29, heading: true))
        add(text("Search by name or username. Follow a cook to start a private conversation.", 16, color: TiloTheme.muted))
        search.placeholder = "Name or username"
        search.searchBarStyle = .minimal
        styleSocialSearch(search)
        search.delegate = self
        add(search)
        results.axis = .vertical
        results.spacing = 12
        add(results)
        results.addArrangedSubview(empty("Make room at the table", detail: "Search for a cook to discover their recipes and follow their kitchen." , icon: .person))
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        task?.cancel()
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        results.arrangedSubviews.forEach { $0.removeFromSuperview() }
        guard !query.isEmpty else { return }
        results.addArrangedSubview(text("Searching…", 15, color: TiloTheme.muted))
        let accountID = TiloBackend.shared.userID
        task = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: 350_000_000)
                let found = try await TiloBackend.shared.searchUsers(query: query)
                guard let self, !Task.isCancelled, accountID == TiloBackend.shared.userID else { return }
                results.arrangedSubviews.forEach { $0.removeFromSuperview() }
                let people = found.filter { $0.id != accountID }
                if people.isEmpty { results.addArrangedSubview(empty("No cooks found", detail: "Try another name or username.", icon: .search)) }
                for person in people {
                    results.addArrangedSubview(socialPersonRow(person) { [weak self] in self?.push(CreatorController(userID: person.id)) })
                }
            } catch {
                guard let self, !Task.isCancelled else { return }
                results.arrangedSubviews.forEach { $0.removeFromSuperview() }
                results.addArrangedSubview(text(error.localizedDescription, 16, color: TiloTheme.red))
            }
        }
    }
    deinit { task?.cancel() }
}

@MainActor
final class RelationshipController: SocialPage {
    private let userID: UUID
    private let kind: String
    init(userID: UUID, kind: String) { self.userID = userID; self.kind = kind; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = kind == "followers" ? "Followers" : kind == "mutuals" ? "Cooking friends" : "Following"
        perform { [weak self] in
            guard let self else { return }
            let people = try await TiloBackend.shared.relationships(userID: userID, kind: kind)
            clearContent()
            if people.isEmpty { add(empty("A little room to grow", detail: "People connected to this kitchen will appear here.", icon: .person)) }
            for person in people { add(socialPersonRow(person) { [weak self] in self?.push(CreatorController(userID: person.id)) }) }
        }
    }
}

@MainActor
final class CreateGroupController: SocialPage {
    private let name = socialField("Group name")
    private let peopleStack = UIStackView()
    private var people: [Profile] = []
    private var selected = Set<UUID>()
    private var createButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create a group"
        add(text("Gather around.", 30, heading: true))
        add(text("Give your cooking group a name and invite at least two mutual friends.", 16, color: TiloTheme.muted))
        add(text("Group name", 14, heading: true))
        add(name)
        name.addTarget(self, action: #selector(selectionChanged), for: .editingChanged)
        peopleStack.axis = .vertical
        peopleStack.spacing = 10
        add(peopleStack)
        createButton = action("Create group", icon: .group, filled: true) { [weak self] in self?.create() }
        add(createButton)
        updateCreate()
        perform { [weak self] in
            guard let self, let userID = TiloBackend.shared.userID else { return }
            people = try await TiloBackend.shared.relationships(userID: userID, kind: "mutuals")
            renderPeople()
        }
    }
    @objc private func selectionChanged() { updateCreate() }
    private func renderPeople() {
        peopleStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if people.isEmpty {
            peopleStack.addArrangedSubview(empty("Your next dinner crew", detail: "Follow other cooks and have them follow you back. Your mutual friends will be available to invite.", icon: .group))
            peopleStack.addArrangedSubview(action("Find people", icon: .search) { [weak self] in self?.push(PeopleController()) })
        }
        for person in people {
            let button = action((selected.contains(person.id) ? "Selected · " : "Invite · ") + person.displayName, icon: selected.contains(person.id) ? .check : .plus, filled: selected.contains(person.id)) { [weak self] in
                guard let self else { return }
                if selected.contains(person.id) { selected.remove(person.id) } else { selected.insert(person.id) }
                renderPeople()
                updateCreate()
            }
            button.accessibilityTraits = selected.contains(person.id) ? [.button, .selected] : [.button]
            peopleStack.addArrangedSubview(button)
        }
    }
    private func updateCreate() {
        let value = (name.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        createButton.isEnabled = selected.count >= 2 && !value.isEmpty && value.count <= 60
        createButton.alpha = createButton.isEnabled ? 1 : 0.45
    }
    private func create() {
        guard selected.count >= 2 else { return }
        let value = (name.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 60 else { message("Check your group name", "Use between 1 and 60 characters."); return }
        let members = Array(selected)
        perform { [weak self] in
            let conversation = try await TiloBackend.shared.createGroup(title: value, memberIDs: members)
            guard let navigation = self?.navigationController else { return }
            navigation.popViewController(animated: false)
            let screen = ConversationController(conversation: conversation)
            screen.hidesBottomBarWhenPushed = true
            navigation.pushViewController(screen, animated: true)
        }
    }
}

@MainActor
final class GroupMemberPickerController: SocialPage {
    private let conversationID: UUID
    private let existing: Set<UUID>
    init(conversationID: UUID, existing: Set<UUID>) { self.conversationID = conversationID; self.existing = existing; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Invite a friend"
        perform { [weak self] in
            guard let self, let userID = TiloBackend.shared.userID else { return }
            let people = try await TiloBackend.shared.relationships(userID: userID, kind: "mutuals").filter { !self.existing.contains($0.id) }
            if people.isEmpty { add(empty("Everyone is at the table", detail: "There are no other mutual friends available to invite.", icon: .group)) }
            for person in people {
                add(action("Invite " + person.displayName, icon: .plus) { [weak self] in
                    self?.perform { [weak self] in
                        guard let self else { return }
                        try await TiloBackend.shared.changeMember(conversationID: conversationID, userID: person.id, remove: false)
                        navigationController?.popViewController(animated: true)
                    }
                })
            }
        }
    }
}
