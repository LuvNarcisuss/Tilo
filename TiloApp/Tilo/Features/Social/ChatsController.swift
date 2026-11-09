import UIKit

@MainActor
final class ChatsController: SocialPage, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate {
    private let backend = TiloBackend.shared
    private let search = UISearchBar()
    private let filters = UIStackView()
    private let body = UIStackView()
    private let table = UITableView(frame: .zero, style: .plain)
    private var tableHeight: NSLayoutConstraint!
    private var all: [Conversation] = []
    private var visible: [Conversation] = []
    private var friends: [Profile] = []
    private var selection = 0
    private var polling: Task<Void, Never>?
    private var loading = false
    private let refresh = UIRefreshControl()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chats"
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: action("", icon: .plus) { [weak self] in self?.showCreate() }),
            UIBarButtonItem(customView: action("", icon: .search) { [weak self] in self?.toggleSearch() })
        ]
        navigationItem.rightBarButtonItems?[0].customView?.accessibilityLabel = "New conversation"
        navigationItem.rightBarButtonItems?[1].customView?.accessibilityLabel = "Search chats"
        add(text("Good food. Great company.", 29, heading: true))
        add(text("Keep the kitchen conversation going.", 15, color: TiloTheme.muted))
        search.delegate = self
        search.placeholder = "Search conversations"
        search.searchBarStyle = .minimal
        search.showsCancelButton = true
        styleSocialSearch(search)
        search.isHidden = true
        add(search)
        filters.axis = .vertical
        add(filters)
        body.axis = .vertical
        body.spacing = 16
        add(body)
        table.backgroundColor = .clear
        table.separatorStyle = .none
        table.dataSource = self
        table.delegate = self
        table.isScrollEnabled = false
        table.register(SocialInboxCell.self, forCellReuseIdentifier: "Chat")
        tableHeight = table.heightAnchor.constraint(equalToConstant: 1)
        tableHeight.isActive = true
        refresh.tintColor = TiloTheme.red
        refresh.addTarget(self, action: #selector(refreshRequested), for: .valueChanged)
        scroll.refreshControl = refresh
        render()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        polling?.cancel()
        polling = Task { [weak self] in
            while !Task.isCancelled {
                await self?.reload(showError: true)
                try? await Task.sleep(nanoseconds: 8_000_000_000)
            }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        polling?.cancel()
    }
    @objc private func refreshRequested() { Task { await reload(showError: true) } }
    private func reload(showError: Bool) async {
        guard !loading, UIApplication.shared.applicationState == .active, let accountID = backend.userID else { refresh.endRefreshing(); return }
        loading = true
        defer { loading = false; refresh.endRefreshing() }
        do {
            let updated = try await backend.refreshConversations()
            let contacts = try await backend.relationships(userID: accountID, kind: "following")
            guard backend.userID == accountID, !Task.isCancelled else { return }
            let changed = all != updated || friends != contacts || body.arrangedSubviews.contains { $0.accessibilityIdentifier == "chat-refresh-error" }
            all = updated
            friends = contacts
            if changed { render() }
        } catch {
            guard showError, !Task.isCancelled else { return }
            if all.isEmpty && friends.isEmpty {
                body.arrangedSubviews.forEach { $0.removeFromSuperview() }
                body.addArrangedSubview(empty("Your kitchen is waiting", detail: error.localizedDescription))
                body.addArrangedSubview(action("Try again", icon: .clock, filled: true) { [weak self] in
                    Task { await self?.reload(showError: true) }
                })
            } else {
                body.arrangedSubviews.filter { $0.accessibilityIdentifier == "chat-refresh-error" }.forEach { $0.removeFromSuperview() }
                let banner = text("Could not refresh conversations. Pull down to try again.", 14, color: TiloTheme.red)
                banner.accessibilityIdentifier = "chat-refresh-error"
                banner.accessibilityLabel = "Could not refresh conversations. " + error.localizedDescription
                body.insertArrangedSubview(banner, at: 0)
            }
        }
    }
    private func render() {
        filters.arrangedSubviews.forEach { $0.removeFromSuperview() }
        filters.isHidden = friends.isEmpty
        if !filters.isHidden {
            filters.addArrangedSubview(socialPills(["All", "Unread", "Pinned", "Drafts", "Groups"], selected: selection) { [weak self] index in
                self?.selection = index
                self?.render()
            })
        } else { selection = 0 }
        let query = (search.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        visible = all.filter { conversation in
            let matches = query.isEmpty || conversation.title.localizedCaseInsensitiveContains(query)
                || (conversation.lastMessage ?? "").localizedCaseInsensitiveContains(query)
                || conversation.draft.localizedCaseInsensitiveContains(query)
            guard matches else { return false }
            switch selection {
            case 1: return conversation.unreadCount > 0
            case 2: return conversation.isPinned
            case 3: return !conversation.draft.isEmpty
            case 4: return conversation.isGroup
            default: return true
            }
        }.sorted { first, second in
            first.isPinned != second.isPinned ? first.isPinned : first.updatedAt > second.updatedAt
        }
        body.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if visible.isEmpty && all.isEmpty && friends.isEmpty && query.isEmpty {
            body.addArrangedSubview(empty("A table for your people", detail: "Swap recipes, ask a cooking question, and share what is on the stove. Follow a cook to start a private conversation."))
            body.addArrangedSubview(action("Find people", icon: .search, filled: true) { [weak self] in self?.push(PeopleController()) })
            body.addArrangedSubview(action("Create a cooking group", icon: .group) { [weak self] in self?.push(CreateGroupController()) })
        } else if visible.isEmpty && all.isEmpty && !friends.isEmpty && query.isEmpty {
            body.addArrangedSubview(empty("Your people are here", detail: "Choose a cook you follow below and start the conversation."))
        } else if visible.isEmpty {
            body.addArrangedSubview(empty("No conversations here yet", detail: query.isEmpty ? "Your conversations will appear in this view when they match the selected filter." : "Try another name or a few words from a conversation."))
            body.addArrangedSubview(action("Back to all chats", icon: .chats) { [weak self] in
                self?.selection = 0
                self?.search.text = ""
                self?.render()
            })
        } else {
            body.addArrangedSubview(table)
            tableHeight.constant = CGFloat(visible.count) * max(104, UIFontMetrics.default.scaledValue(for: 104))
            table.reloadData()
        }
        let existingPeers = Set(all.compactMap(\.peerID))
        let availableFriends = friends.filter { !existingPeers.contains($0.id) }
        if selection == 0 && query.isEmpty && !availableFriends.isEmpty {
            body.addArrangedSubview(text("Cooks you follow", 22, heading: true))
            for friend in availableFriends {
                body.addArrangedSubview(socialPersonRow(friend) { [weak self] in
                    self?.perform { [weak self] in
                        let conversation = try await TiloBackend.shared.createDirect(userID: friend.id)
                        self?.push(ConversationController(conversation: conversation))
                    }
                })
            }
        }
    }
    private func toggleSearch() {
        search.isHidden.toggle()
        if search.isHidden { search.text = ""; search.resignFirstResponder(); render() }
        else { search.becomeFirstResponder() }
    }
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) { render() }
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        search.isHidden = true; search.text = ""; search.resignFirstResponder(); render()
    }
    private func showCreate() {
        let sheet = UIAlertController(title: "Bring people together", message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "Find people", style: .default) { [weak self] _ in self?.push(PeopleController()) })
        sheet.addAction(UIAlertAction(title: "Create a group", style: .default) { [weak self] _ in self?.push(CreateGroupController()) })
        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        present(sheet, animated: true)
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { visible.count }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { max(104, UIFontMetrics.default.scaledValue(for: 104)) }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Chat", for: indexPath) as! SocialInboxCell
        let conversation = visible[indexPath.row]
        cell.configure(conversation)
        cell.more.menu = menu(conversation)
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        push(ConversationController(conversation: visible[indexPath.row]))
    }
    private func menu(_ conversation: Conversation) -> UIMenu {
        var entries: [UIMenuElement] = []
        if let peerID = conversation.peerID {
            entries.append(UIAction(title: "View profile") { [weak self] _ in self?.push(CreatorController(userID: peerID)) })
        }
        entries += [
            UIAction(title: conversation.isPinned ? "Unpin" : "Pin") { [weak self] _ in self?.mutate(conversation, operation: "pin") },
            UIAction(title: conversation.isMuted ? "Unmute" : "Mute") { [weak self] _ in self?.mutate(conversation, operation: "mute") },
            UIAction(title: "Mark as read") { [weak self] _ in self?.mutate(conversation, operation: "read") },
            UIAction(title: "Delete conversation", attributes: .destructive) { [weak self] _ in self?.mutate(conversation, operation: "delete") }
        ]
        return UIMenu(children: entries)
    }
    private func mutate(_ conversation: Conversation, operation: String) {
        let work: () async throws -> Void = { [weak self] in
            let backend = TiloBackend.shared
            switch operation {
            case "pin": try await backend.updateConversation(id: conversation.id, pinned: !conversation.isPinned)
            case "mute": try await backend.updateConversation(id: conversation.id, muted: !conversation.isMuted)
            case "read": try await backend.markRead(conversationID: conversation.id)
            default: try await backend.deleteConversation(id: conversation.id)
            }
            await self?.reload(showError: true)
        }
        if operation == "delete" {
            confirm("Delete conversation?", detail: "This removes the conversation from your inbox. Other members keep their own history.", destructive: "Delete", operation: work)
        } else { perform(work) }
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let conversation = visible[indexPath.row]
        let actions = [
            (conversation.isPinned ? "Unpin" : "Pin", "pin", TiloTheme.olive),
            (conversation.isMuted ? "Unmute" : "Mute", "mute", TiloTheme.muted),
            ("Delete", "delete", TiloTheme.red)
        ].map { title, operation, color in
            let action = UIContextualAction(style: .normal, title: title) { [weak self] _, _, done in
                self?.mutate(conversation, operation: operation); done(true)
            }
            action.backgroundColor = color
            return action
        }
        let config = UISwipeActionsConfiguration(actions: Array(actions.reversed()))
        config.performsFirstActionWithFullSwipe = false
        return config
    }
}

@MainActor
private final class SocialInboxCell: UITableViewCell {
    let more = UIButton(type: .custom)
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = .clear
        selectionStyle = .none
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    func configure(_ conversation: Conversation) {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        let image = SocialAvatar(url: conversation.avatarURL, group: conversation.isGroup)
        let heading = Tilo.text(conversation.title, 18, heading: true)
        heading.numberOfLines = 1
        let preview = conversation.draft.isEmpty ? (conversation.lastMessage ?? "Say hello over something delicious.") : "Draft: " + conversation.draft
        let detail = Tilo.text(preview, 14, color: conversation.draft.isEmpty ? TiloTheme.muted : TiloTheme.red)
        detail.numberOfLines = 2
        detail.numberOfLines = 1
        let state = [conversation.isPinned ? "Pinned" : nil, conversation.isMuted ? "Muted" : nil,
                     conversation.unreadCount > 0 ? "\(conversation.unreadCount) unread" : nil].compactMap { $0 }.joined(separator: " · ")
        let date = Tilo.text([socialDate(conversation.updatedAt), state].filter { !$0.isEmpty }.joined(separator: " · "), 11, color: TiloTheme.muted)
        date.numberOfLines = 1
        let labels = socialStack([heading, detail, date], spacing: 3)
        labels.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        more.setImage(TiloIcon.more.image(24), for: .normal)
        more.accessibilityLabel = "Manage conversation with " + conversation.title
        more.showsMenuAsPrimaryAction = true
        more.widthAnchor.constraint(equalToConstant: 44).isActive = true
        more.heightAnchor.constraint(equalToConstant: 44).isActive = true
        let row = socialStack([image, labels, more], axis: .horizontal, spacing: 12)
        row.alignment = .center
        row.backgroundColor = conversation.isPinned ? UIColor.white : .clear
        row.round(20)
        row.isLayoutMarginsRelativeArrangement = true
        row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 4)
        contentView.addSubview(row)
        row.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            row.leadingAnchor.constraint(equalTo: contentView.leadingAnchor), row.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            row.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 4), row.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }
}

@MainActor
func socialPersonRow(_ profile: Profile, selected: @escaping () -> Void) -> UIView {
    let button = UIButton(type: .custom)
    let subtitle = profile.bio.isEmpty ? "@" + profile.username : profile.bio
    let details = socialStack([text(profile.displayName, 18, heading: true), text(subtitle, 14, color: TiloTheme.muted)], spacing: 4)
    details.isUserInteractionEnabled = false
    let row = socialStack([SocialAvatar(url: profile.avatarURL), details], axis: .horizontal)
    row.alignment = .center
    row.isUserInteractionEnabled = false
    row.isLayoutMarginsRelativeArrangement = true
    row.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 14)
    button.addSubview(row)
    row.translatesAutoresizingMaskIntoConstraints = false
    NSLayoutConstraint.activate([
        row.leadingAnchor.constraint(equalTo: button.leadingAnchor), row.trailingAnchor.constraint(equalTo: button.trailingAnchor),
        row.topAnchor.constraint(equalTo: button.topAnchor), row.bottomAnchor.constraint(equalTo: button.bottomAnchor)
    ])
    button.backgroundColor = .white
    button.round(22)
    button.accessibilityLabel = profile.displayName + ", " + subtitle
    button.addAction(UIAction { _ in selected() }, for: .touchUpInside)
    return button
}
