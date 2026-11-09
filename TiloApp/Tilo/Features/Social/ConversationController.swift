import Combine
import PhotosUI
import UIKit

@MainActor
final class ConversationController: UIViewController, UITextViewDelegate, PHPickerViewControllerDelegate {
    private struct PendingSend: Codable {
        let body: String
        let rawDraft: String
        let photoToken: UUID?
        let id: UUID
        let photoData: Data?
        var photoPath: String?
        var acknowledged = false
    }
    private let conversation: Conversation
    private let backend = TiloBackend.shared
    private let history = UIScrollView()
    private let messagesStack = UIStackView()
    private let composer = UITextView()
    private let state = UILabel()
    private let connection = text("Connecting…",12,color:TiloTheme.muted)
    private let send = UIButton(type: .custom)
    private let attachment = UIStackView()
    private let attachmentPhoto = UIImageView()
    private lazy var photoButton = action("", icon: .camera) { [weak self] in self?.choosePhoto() }
    private lazy var removePhotoButton = action("Remove photo", icon: .close) { [weak self] in self?.removePhoto(userInitiated: true) }
    private var selectedPhotoData: Data?
    private var selectedPhotoPath: String?
    private var selectedPhotoToken: UUID?
    private var pickingPhoto = false
    private var messages: [Message] = []
    private var members: [Profile] = []
    private var poll: Task<Void, Never>?
    private var draftTask: Task<Void, Never>?
    private var lastDraft: String
    private var pendingDraft: String?
    private var draftWriteTask: Task<Void, Never>?
    private var retryMessage: PendingSend?
    private var opening = false
    private var sending = false
    private var canSend = false
    private var loading = false
    private var firstLoad = true
    private var accountID: UUID?
    private var accessValidated = false
    private var accessRevoked = false
    private var operationEpoch = UUID()
    private var draftLoaded = false
    private var restoringDraft = false
    private var localDraftSaved = false
    private var sendTask: Task<Void, Never>?
    private lazy var retryDraft = action("Retry saved draft", icon: .clock) { [weak self] in Task { await self?.restoreLocalDraft() } }
    private lazy var retryOpening = action("Retry connection", icon: .clock) { [weak self] in self?.openConversation() }
    private lazy var videoPreviewItem: UIBarButtonItem = {
        let button = action("", icon: .video) { [weak self] in self?.openVideoPreview() }
        button.accessibilityLabel = "Video call"
        button.accessibilityIdentifier = "chat-video-call"
        return UIBarButtonItem(customView: button)
    }()
    private var draftKey: String { "chat-" + conversation.id.uuidString.lowercased() }
    private var pendingSendKey: String { "chat-send-" + conversation.id.uuidString.lowercased() }
    private var hasAccess: Bool { accessValidated && !accessRevoked && backend.userID == accountID }
    private var observations = Set<AnyCancellable>()

    init(conversation: Conversation) {
        self.conversation = conversation
        lastDraft = conversation.draft
        canSend = conversation.isGroup
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = conversation.title
        overrideUserInterfaceStyle = .light
        view.backgroundColor = TiloTheme.cream
        let background = UIImageView(image: UIImage(named: "TiloBackground"))
        background.contentMode = .scaleAspectFill
        background.isUserInteractionEnabled = false
        view.addSubview(background)
        background.fill(view)
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: TiloIcon.back.image(), style: .plain, target: self, action: #selector(goBack))
        navigationItem.leftBarButtonItem?.accessibilityLabel = "Back"
        accountID = backend.userID
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: action("", icon: .info) { [weak self] in
            guard let self else { return }
            self.push(ConversationDetailsController(conversation: self.conversation))
        })
        navigationItem.rightBarButtonItem?.customView?.accessibilityLabel = "Conversation details"
        if !conversation.isGroup, let details = navigationItem.rightBarButtonItem {
            navigationItem.rightBarButtonItems = [details, videoPreviewItem]
        }
        history.accessibilityIdentifier = "chat-history"; history.keyboardDismissMode = .interactive
        messagesStack.axis = .vertical
        messagesStack.spacing = 14
        messagesStack.isLayoutMarginsRelativeArrangement = true
        messagesStack.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 24, leading: 18, bottom: 24, trailing: 18)
        history.addSubview(messagesStack)
        state.font = TiloTheme.font(12)
        state.textColor = TiloTheme.muted
        state.numberOfLines = 0
        state.text = "Loading your conversation…"
        connection.accessibilityIdentifier = "chat-connection"
        connection.accessibilityLabel = "Chat connection"
        backend.$realtimeConnected.receive(on:RunLoop.main).sink { [weak self] connected in
            self?.connection.text = connected ? "Connected" : "Reconnecting…"
            self?.connection.accessibilityValue = connected ? "Connected" : "Reconnecting"
        }.store(in:&observations)
        composer.font = TiloTheme.font(16)
        composer.adjustsFontForContentSizeCategory = true
        composer.textColor = TiloTheme.ink
        composer.backgroundColor = .white
        composer.round(20)
        composer.textContainerInset = UIEdgeInsets(top: 12, left: 10, bottom: 12, right: 10)
        composer.text = ""
        composer.isEditable = false
        composer.delegate = self
        composer.accessibilityLabel = "Message"
        composer.accessibilityHint = "Up to 2,000 characters."
        send.setImage(TiloIcon.send.image(28), for: .normal)
        send.backgroundColor = TiloTheme.red
        send.round(24)
        send.accessibilityLabel = "Send message"
        send.addAction(UIAction { [weak self] _ in self?.sendMessage() }, for: .touchUpInside)
        photoButton.accessibilityLabel = "Attach photo"
        photoButton.widthAnchor.constraint(equalToConstant: 48).isActive = true
        attachment.axis = .horizontal
        attachment.spacing = 12
        attachment.alignment = .center
        attachmentPhoto.contentMode = .scaleAspectFill
        attachmentPhoto.round(14)
        attachmentPhoto.isAccessibilityElement = true
        attachmentPhoto.accessibilityLabel = "Selected message photo"
        attachmentPhoto.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([attachmentPhoto.widthAnchor.constraint(equalToConstant: 84), attachmentPhoto.heightAnchor.constraint(equalToConstant: 84)])
        attachment.addArrangedSubview(attachmentPhoto)
        attachment.addArrangedSubview(removePhotoButton)
        attachment.isHidden = true
        let input = socialStack([photoButton, composer, send], axis: .horizontal, spacing: 8)
        input.alignment = .bottom
        retryDraft.isHidden = true
        retryOpening.isHidden = true
        let footer = socialStack([connection, state, retryOpening, retryDraft, attachment, input], spacing: 8)
        footer.isLayoutMarginsRelativeArrangement = true
        footer.directionalLayoutMargins = NSDirectionalEdgeInsets(top: 8, leading: 18, bottom: 12, trailing: 18)
        footer.backgroundColor = TiloTheme.cream
        view.addSubview(history)
        view.addSubview(footer)
        [history, messagesStack, footer, send, composer].forEach { $0.translatesAutoresizingMaskIntoConstraints = false }
        NSLayoutConstraint.activate([
            history.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            history.leadingAnchor.constraint(equalTo: view.leadingAnchor), history.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            history.bottomAnchor.constraint(equalTo: footer.topAnchor),
            footer.leadingAnchor.constraint(equalTo: view.leadingAnchor), footer.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            footer.bottomAnchor.constraint(equalTo: view.keyboardLayoutGuide.topAnchor),
            composer.heightAnchor.constraint(equalToConstant: 72), send.heightAnchor.constraint(equalToConstant: 48), send.widthAnchor.constraint(equalToConstant: 48),
            messagesStack.topAnchor.constraint(equalTo: history.contentLayoutGuide.topAnchor),
            messagesStack.leadingAnchor.constraint(equalTo: history.contentLayoutGuide.leadingAnchor),
            messagesStack.trailingAnchor.constraint(equalTo: history.contentLayoutGuide.trailingAnchor),
            messagesStack.bottomAnchor.constraint(equalTo: history.contentLayoutGuide.bottomAnchor),
            messagesStack.widthAnchor.constraint(equalTo: history.frameLayoutGuide.widthAnchor)
        ])
        backend.$messages.receive(on: RunLoop.main).sink { [weak self] loaded in
            guard let self, hasAccess, viewIfLoaded?.window != nil else { return }
            let relevant = loaded.filter { $0.conversationID == self.conversation.id }
            guard !relevant.isEmpty else { return }
            receive(relevant)
        }.store(in: &observations)
        backend.$inaccessibleConversationIDs.sink { [weak self] denied in
            guard let self, denied.contains(conversation.id) else { return }
            invalidateAccess("This conversation is no longer available.")
        }.store(in: &observations)
        backend.$session.sink { [weak self] session in
            guard let self, session?.user.id != accountID else { return }
            invalidateAccess("Your account has changed. Return to Chats to continue.")
        }.store(in: &observations)
        updateSend()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if pickingPhoto { return }
        openConversation()
    }
    private func openConversation() {
        guard !opening, !accessRevoked else { return }
        guard backend.userID == accountID else { invalidateAccess("Your account has changed. Return to Chats to continue."); return }
        poll?.cancel()
        opening = true
        retryOpening.isHidden = true
        state.text = "Opening conversation…"
        accessValidated = false
        canSend = false
        composer.isEditable = false
        history.isHidden = true
        updateSend()
        let epoch = operationEpoch
        poll = Task { [weak self] in
            guard let self else { return }
            do {
                let currentMembers = try await backend.conversationMembers(id: conversation.id)
                try await backend.openConversation(id: conversation.id)
                guard !Task.isCancelled, epoch == operationEpoch, backend.userID == accountID else { return }
                members = currentMembers
                accessRevoked = false
                accessValidated = true
                title = conversation.title
                navigationItem.rightBarButtonItem?.isEnabled = true
                history.isHidden = false
                canSend = conversation.isGroup
                if !conversation.isGroup, let accountID,
                   let peerID = conversation.peerID ?? members.first(where: { $0.id != accountID })?.id {
                    let connections = try await backend.relationships(userID: accountID, kind: "following")
                    guard !Task.isCancelled, epoch == operationEpoch, hasAccess else { return }
                    canSend = connections.contains { $0.id == peerID }
                }
                await restoreLocalDraft()
                updateSend()
                opening = false
            } catch {
                guard !Task.isCancelled, epoch == operationEpoch else { return }
                opening = false
                if isAccessFailure(error) { invalidateAccess("This conversation is no longer available."); return }
                accessValidated = false
                canSend = false
                history.isHidden = true
                composer.isEditable = false
                retryOpening.isHidden = false
                state.text = "Could not open conversation. " + error.localizedDescription
                updateSend()
                return
            }
            while !Task.isCancelled && epoch == operationEpoch && hasAccess {
                await load()
                try? await Task.sleep(nanoseconds: backend.realtimeConnected ? 30_000_000_000 : 5_000_000_000)
            }
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if pickingPhoto { persistDraft(); return }
        poll?.cancel()
        opening = false
        persistDraft()
        backend.closeConversation()
    }
    private func load() async {
        guard !loading, hasAccess, UIApplication.shared.applicationState == .active else { return }
        let epoch = operationEpoch
        loading = true
        defer { loading = false }
        do {
            let loaded = try await backend.loadMessages(conversationID: conversation.id)
            guard !Task.isCancelled, epoch == operationEpoch, hasAccess else { return }
            receive(loaded)
            if draftLoaded { state.text = canSend ? (messages.isEmpty ? "Say hello and share what you are cooking." : "Conversation updated.") : "Follow this cook to send private messages." }

        } catch {
            guard !Task.isCancelled, epoch == operationEpoch else { return }
            if isAccessFailure(error) { invalidateAccess("This conversation is no longer available."); return }
            state.text = "Could not refresh. " + error.localizedDescription
        }
    }
    private func receive(_ loaded: [Message]) {
        guard hasAccess else { return }
        let known = Set(messages.map(\.id))
        let incoming = loaded.filter { !known.contains($0.id) }
        if !incoming.isEmpty || firstLoad {
            let nearBottom = firstLoad || history.contentSize.height - history.contentOffset.y - history.bounds.height < 120
            messages = (messages + incoming).sorted { $0.createdAt < $1.createdAt }
            renderMessages()
            if nearBottom { scrollToBottom() }
            if incoming.contains(where: { $0.senderID != accountID }) {
                Task { [weak self] in
                    guard let self, hasAccess, viewIfLoaded?.window != nil else { return }
                    do { try await backend.markRead(conversationID: conversation.id) }
                    catch {
                        guard hasAccess else { return }
                        if isAccessFailure(error) { invalidateAccess("This conversation is no longer available."); return }
                        state.text = "Read status could not be updated. " + error.localizedDescription
                    }
                }
            }
        }
        firstLoad = false
    }
    private func renderMessages() {
        messagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if messages.isEmpty {
            let picture = UIImageView(image: TiloIcon.chats.image(88))
            picture.contentMode = .scaleAspectFit
            picture.fixedHeight(120)
            messagesStack.addArrangedSubview(socialCard([picture, text("A fresh conversation", 24, heading: true), text("Share what is cooking, trade a recipe, or simply say hello.", 16, color: TiloTheme.muted)]))
        }
        if let oldest = messages.first {
            let older = action("Load earlier messages", icon: .clock) { [weak self] in
                self?.loadEarlier(before: oldest.createdAt)
            }
            messagesStack.addArrangedSubview(older)
        }
        for message in messages {
            let own = message.senderID == accountID
            let author = members.first { $0.id == message.senderID }
            let name = own ? "You" : (author?.displayName ?? "Cook")
            let nameLabel = text(name, 12, heading: true, color: own ? .white : TiloTheme.olive)
            let body = text(message.body, 16, color: own ? .white : TiloTheme.ink)
            let time = text(socialDate(message.createdAt), 11, color: own ? .white : TiloTheme.muted)
            var contents: [UIView] = [nameLabel, body]
            if let imagePath = message.imagePath {
                contents.append(SocialMessagePhoto(path: imagePath, conversationID: conversation.id))
            }
            contents.append(time)
            let bubble = socialCard(contents, color: own ? TiloTheme.olive : .white)
            let row = UIView()
            row.addSubview(bubble)
            bubble.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                bubble.topAnchor.constraint(equalTo: row.topAnchor), bubble.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                bubble.widthAnchor.constraint(lessThanOrEqualTo: row.widthAnchor, multiplier: 0.88),
                own ? bubble.trailingAnchor.constraint(equalTo: row.trailingAnchor) : bubble.leadingAnchor.constraint(equalTo: row.leadingAnchor)
            ])
            if !own {
                let interaction = UIContextMenuInteraction(delegate: self)
                row.addInteraction(interaction)
                row.accessibilityIdentifier = message.senderID.uuidString
                row.isAccessibilityElement = true
                row.accessibilityLabel = name + ", " + message.body + ", " + socialDate(message.createdAt)
                row.accessibilityCustomActions = [
                    UIAccessibilityCustomAction(name: "View profile") { [weak self] _ in
                        self?.push(CreatorController(userID: message.senderID))
                        return true
                    },
                    UIAccessibilityCustomAction(name: "Report sender") { [weak self] _ in
                        self?.push(ReportProfileController(userID: message.senderID))
                        return true
                    }
                ]
            }
            messagesStack.addArrangedSubview(row)
        }
    }
    private func loadEarlier(before: String) {
        guard !loading, hasAccess else { return }
        let epoch = operationEpoch
        loading = true
        Task { [weak self] in
            guard let self else { return }
            defer { loading = false }
            do {
                let earlier = try await backend.loadMessages(conversationID: conversation.id, before: before)
                guard !Task.isCancelled, epoch == operationEpoch, hasAccess else { return }
                let existing = Set(messages.map(\.id))
                messages.insert(contentsOf: earlier.filter { !existing.contains($0.id) }.sorted { $0.createdAt < $1.createdAt }, at: 0)
                renderMessages()
                state.text = earlier.isEmpty ? "You have reached the start of this conversation." : "Earlier messages loaded."
            } catch {
                guard epoch == operationEpoch else { return }
                if isAccessFailure(error) { invalidateAccess("This conversation is no longer available."); return }
                state.text = error.localizedDescription
            }
        }
    }
    private func scrollToBottom() {
        view.layoutIfNeeded()
        history.setContentOffset(CGPoint(x: 0, y: max(-history.adjustedContentInset.top, history.contentSize.height - history.bounds.height)), animated: false)
    }
    func textViewDidChange(_ textView: UITextView) {
        guard hasAccess, draftLoaded else { return }
        saveLocalDraft()
        updateSend()
        draftTask?.cancel()
        draftTask = Task { [weak self] in
            do { try await Task.sleep(nanoseconds: 600_000_000) } catch { return }
            self?.persistDraft()
        }
    }
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let range = Range(range, in: textView.text ?? "") else { return false }
        return (textView.text ?? "").replacingCharacters(in: range, with: text).count <= 2_000
    }
    private func updateSend() {
        let hasContent = !(composer.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedPhotoData != nil
        send.isEnabled = hasAccess && draftLoaded && canSend && !sending && hasContent
        send.alpha = send.isEnabled ? 1 : 0.45
        photoButton.isEnabled = hasAccess && draftLoaded && canSend && !sending
        photoButton.alpha = photoButton.isEnabled ? 1 : 0.45
        removePhotoButton.isEnabled = !sending
        if !conversation.isGroup, let button = videoPreviewItem.customView as? UIButton {
            button.isEnabled = hasAccess && canSend
            button.alpha = button.isEnabled ? 1 : 0.45
        }
    }
    private func openVideoPreview() {
        guard !conversation.isGroup, hasAccess, canSend, presentedViewController == nil else { return }
        view.endEditing(true)
        let preview = VideoCallPreviewController(conversationTitle: conversation.title)
        preview.modalPresentationStyle = .fullScreen
        present(preview, animated: true)
    }
    private func persistDraft() {
        guard hasAccess, draftLoaded, !sending else { return }
        let value = composer.text ?? ""
        guard value != lastDraft || pendingDraft != nil else { return }
        pendingDraft = value
        guard draftWriteTask == nil else { return }
        draftWriteTask = Task { [weak self] in
            guard let self else { return }
            defer { draftWriteTask = nil }
            let epoch = operationEpoch
            while let value = pendingDraft, hasAccess, epoch == operationEpoch, !Task.isCancelled {
                pendingDraft = nil
                do {
                    try await backend.updateConversation(id: conversation.id, draft: value)
                    guard epoch == operationEpoch, hasAccess, !Task.isCancelled else { return }
                    lastDraft = value
                } catch {
                    guard epoch == operationEpoch, hasAccess, !Task.isCancelled else { return }
                    if isAccessFailure(error) { invalidateAccess("This conversation is no longer available."); return }
                    state.text = (localDraftSaved ? "Draft saved on this device. Cloud sync failed. " : "Draft could not be synced. ") + error.localizedDescription
                }
            }
        }
    }

    private func sendMessage() {
        let rawDraft = composer.text ?? ""
        let caption = rawDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        let value = caption.isEmpty && selectedPhotoData != nil ? "Photo" : caption
        let photoToken = selectedPhotoToken
        let photoData = selectedPhotoData
        guard hasAccess, draftLoaded, canSend, !sending, !value.isEmpty, value.count <= 2_000 else { return }
        let epoch = operationEpoch
        sending = true
        draftTask?.cancel()
        updateSend()
        let clientID: UUID
        if let retryMessage, retryMessage.body == value, retryMessage.photoToken == photoToken { clientID = retryMessage.id } else { clientID = UUID() }
        var pending = PendingSend(body: value, rawDraft: rawDraft, photoToken: photoToken, id: clientID, photoData: photoData, photoPath: selectedPhotoPath)
        do {
            if let saved = try readPendingSend(), saved.body == value, saved.photoToken == photoToken {
                pending = saved
            }
            if pending.acknowledged || backend.messages.contains(where: { $0.clientID == pending.id && $0.senderID == accountID }) {
                sendTask = Task { [weak self] in
                    guard let self else { return }
                    defer { sending = false; updateSend(); sendTask = nil }
                    do {
                        try await reconcileAcknowledgedSend(pending)
                        state.text = "This message was already sent."
                    } catch {
                        guard !Task.isCancelled, epoch == operationEpoch, hasAccess else { return }
                        if isAccessFailure(error) { invalidateAccess("This conversation is no longer available."); return }
                        draftLoaded = false
                        composer.isEditable = false
                        retryDraft.isHidden = false
                        state.text = "Message sent. Its saved draft still needs reconciliation. Retry before editing. " + error.localizedDescription
                    }
                }
                return
            }
            try savePendingSend(pending)
            retryMessage = pending
        } catch {
            sending = false
            updateSend()
            state.text = "The saved message could not be checked safely. No new send was started. Retry sending. " + error.localizedDescription
            return
        }
        state.text = "Sending…"
        sendTask = Task { [weak self] in
            guard let self else { return }
            defer { sending = false; updateSend(); sendTask = nil }
            do {
                await draftWriteTask?.value
                guard !Task.isCancelled, epoch == operationEpoch, hasAccess else { return }
                var imagePath = pending.photoPath
                if imagePath == nil, let photoData = pending.photoData {
                    imagePath = try await backend.uploadChatImage(data: photoData, conversationID: conversation.id)
                    guard !Task.isCancelled, epoch == operationEpoch, hasAccess else { return }
                    pending.photoPath = imagePath
                    try savePendingSend(pending)
                    retryMessage = pending
                    if selectedPhotoToken == photoToken { selectedPhotoPath = imagePath }
                }
                try await backend.sendMessage(conversationID: conversation.id, body: value, clientID: pending.id, imagePath: imagePath)
                guard !Task.isCancelled, epoch == operationEpoch, hasAccess else { return }
                pending.acknowledged = true
                do { try savePendingSend(pending) }
                catch {
                    retryMessage = pending
                    state.text = "Message sent. Its confirmation could not be saved on this device. Retry before sending again. " + error.localizedDescription
                    return
                }
                retryMessage = pending
                var draftWarning: String?
                do {
                    try await reconcileAcknowledgedSend(pending)
                    guard !Task.isCancelled, epoch == operationEpoch, hasAccess else { return }
                } catch {
                    guard !Task.isCancelled, epoch == operationEpoch, hasAccess else { return }
                    if isAccessFailure(error) { invalidateAccess("This conversation is no longer available."); return }
                    draftLoaded = false
                    composer.isEditable = false
                    retryDraft.isHidden = false
                    draftWarning = "Message sent. Its saved draft still needs reconciliation. Retry before editing. " + error.localizedDescription
                }
                await load()
                guard !Task.isCancelled, epoch == operationEpoch, hasAccess else { return }
                if let draftWarning { state.text = draftWarning }
                scrollToBottom()
            } catch {
                guard !Task.isCancelled, epoch == operationEpoch, hasAccess else { return }
                if isAccessFailure(error) { invalidateAccess("This conversation is no longer available."); return }
                state.text = "Could not confirm this message. Retry to check its status. " + error.localizedDescription
            }
        }
    }
    private func restoreLocalDraft() async {
        guard hasAccess, !restoringDraft, let accountID else { return }
        if draftLoaded { composer.isEditable = true; return }
        restoringDraft = true
        defer { restoringDraft = false }
        do {
            let data = try TiloDraftStorage.read(key: draftKey, accountID: accountID)
            if let data { composer.text = try JSONDecoder().decode(String.self, from: data); localDraftSaved = true }
            else { localDraftSaved = false; composer.text = backend.conversations.first(where: { $0.id == conversation.id })?.draft ?? conversation.draft }
            if let pending = try readPendingSend() {
                retryMessage = pending
                if pending.acknowledged || backend.messages.contains(where: { $0.clientID == pending.id && $0.senderID == accountID }) {
                    try await reconcileAcknowledgedSend(pending)
                } else if data == nil || composer.text == pending.rawDraft {
                    composer.text = pending.rawDraft
                    selectedPhotoData = pending.photoData
                    selectedPhotoPath = pending.photoPath
                    selectedPhotoToken = pending.photoToken
                    attachmentPhoto.image = pending.photoData.flatMap { UIImage(data: $0) }
                    attachment.isHidden = pending.photoData == nil
                }
            }
            guard !Task.isCancelled, hasAccess else { return }
            draftLoaded = true
            composer.isEditable = true
            retryDraft.isHidden = true
            updateSend()
        } catch {
            guard !Task.isCancelled, hasAccess else { return }
            if isAccessFailure(error) { invalidateAccess("This conversation is no longer available."); return }
            composer.isEditable = false
            retryDraft.isHidden = false
            state.text = "Your saved draft could not be read. Retry before editing. " + error.localizedDescription
            updateSend()
        }
    }
    private func readPendingSend() throws -> PendingSend? {
        guard let accountID, backend.userID == accountID else { throw CancellationError() }
        guard let data = try TiloDraftStorage.read(key: pendingSendKey, accountID: accountID) else { return nil }
        return try JSONDecoder().decode(PendingSend.self, from: data)
    }
    private func savePendingSend(_ pending: PendingSend) throws {
        guard hasAccess, let accountID else { throw CancellationError() }
        try TiloDraftStorage.save(JSONEncoder().encode(pending), key: pendingSendKey, accountID: accountID)
    }
    private func removePendingSend() throws {
        guard hasAccess, let accountID else { throw CancellationError() }
        try TiloDraftStorage.remove(key: pendingSendKey, accountID: accountID)
    }
    private func reconcileAcknowledgedSend(_ pending: PendingSend) async throws {
        let epoch = operationEpoch
        guard try readPendingSend()?.id == pending.id else { throw CancellationError() }
        var confirmed = pending
        confirmed.acknowledged = true
        try savePendingSend(confirmed)
        retryMessage = confirmed
        // Finish the old writer before checking whether it restored an acknowledged draft.
        await draftWriteTask?.value
        guard !Task.isCancelled, epoch == operationEpoch, hasAccess,
              try readPendingSend()?.id == pending.id else { throw CancellationError() }
        let refreshed = try await backend.refreshConversations()
        guard !Task.isCancelled, epoch == operationEpoch, hasAccess,
              try readPendingSend()?.id == pending.id,
              let remote = refreshed.first(where: { $0.id == conversation.id }) else { throw CancellationError() }
        var remainingRemote = remote.draft
        if remote.draft == pending.rawDraft && !remote.draft.isEmpty {
            try await backend.updateConversation(id: conversation.id, draft: "")
            guard !Task.isCancelled, epoch == operationEpoch, hasAccess,
                  try readPendingSend()?.id == pending.id else { throw CancellationError() }
            remainingRemote = ""
        }
        guard let accountID else { throw CancellationError() }
        var remainingLocal: String?
        if let data = try TiloDraftStorage.read(key: draftKey, accountID: accountID) {
            let saved = try JSONDecoder().decode(String.self, from: data)
            if saved == pending.rawDraft { try TiloDraftStorage.remove(key: draftKey, accountID: accountID) }
            else { remainingLocal = saved }
        }
        if composer.text == pending.rawDraft { composer.text = remainingLocal ?? remainingRemote }
        lastDraft = remainingRemote
        localDraftSaved = remainingLocal != nil
        if selectedPhotoToken == pending.photoToken { removePhoto() }
        // Keep the acknowledgement tombstone until matching cloud cleanup has succeeded.
        guard try readPendingSend()?.id == pending.id else { throw CancellationError() }
        try removePendingSend()
        retryMessage = nil
    }
    private func saveLocalDraft() {
        guard hasAccess, draftLoaded, let accountID else { return }
        do {
            try TiloDraftStorage.save(JSONEncoder().encode(composer.text ?? ""), key: draftKey, accountID: accountID)
            localDraftSaved = true
        } catch {
            localDraftSaved = false
            state.text = "Draft could not be saved on this device. " + error.localizedDescription
        }
    }
    private func choosePhoto() {
        guard hasAccess, canSend, draftLoaded, !sending else { return }
        var configuration = PHPickerConfiguration(photoLibrary: .shared())
        configuration.filter = .images
        configuration.selectionLimit = 1
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        pickingPhoto = true
        present(picker, animated: true)
    }
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) { [weak self] in self?.pickingPhoto = false }
        guard hasAccess, let provider = results.first?.itemProvider else { return }
        let epoch = operationEpoch
        provider.loadObject(ofClass: UIImage.self) { [weak self] object, error in
            Task { @MainActor in
                guard let self, epoch == self.operationEpoch, self.hasAccess else { return }
                guard let image = object as? UIImage else {
                    self.state.text = "The photo could not be read. " + (error?.localizedDescription ?? "Choose another photo.")
                    return
                }
                let scale = min(1, 1_600 / max(image.size.width, image.size.height))
                let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
                let format = UIGraphicsImageRendererFormat()
                format.scale = 1
                let prepared = UIGraphicsImageRenderer(size: size, format: format).image { _ in image.draw(in: CGRect(origin: .zero, size: size)) }
                guard let data = prepared.jpegData(compressionQuality: 0.85), data.count <= 10_485_760 else {
                    self.state.text = "Choose a photo smaller than 10 MB."
                    return
                }
                do { try self.removePendingSend() }
                catch {
                    self.state.text = "The previous photo retry could not be cleared safely. Please try again. " + error.localizedDescription
                    return
                }
                self.selectedPhotoData = data
                self.selectedPhotoPath = nil
                self.selectedPhotoToken = UUID()
                self.retryMessage = nil
                self.attachmentPhoto.image = prepared
                self.attachment.isHidden = false
                self.updateSend()
            }
        }
    }
    private func removePhoto(userInitiated: Bool = false) {
        if userInitiated {
            do { try removePendingSend() }
            catch {
                state.text = "The saved photo retry could not be cleared safely. Please try again. " + error.localizedDescription
                return
            }
        }
        selectedPhotoData = nil
        selectedPhotoPath = nil
        selectedPhotoToken = nil
        attachmentPhoto.image = nil
        attachment.isHidden = true
        retryMessage = nil
        updateSend()
    }
    private func isAccessFailure(_ error: Error) -> Bool {
        guard let error = error as? TiloBackend.BackendError else { return false }
        switch error {
        case .accessDenied, .authentication: return true
        case .message: return false
        }
    }
    private func invalidateAccess(_ explanation: String) {
        (presentedViewController as? VideoCallPreviewController)?.endPreview()
        operationEpoch = UUID()
        accessRevoked = true
        opening = false
        retryOpening.isHidden = true
        accessValidated = false
        canSend = false
        draftLoaded = false
        localDraftSaved = false
        poll?.cancel()
        draftTask?.cancel()
        draftWriteTask?.cancel()
        sendTask?.cancel()
        pendingDraft = nil
        retryMessage = nil
        removePhoto()
        messages = []
        members = []
        lastDraft = ""
        composer.text = ""
        composer.isEditable = false
        composer.resignFirstResponder()
        messagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        history.isHidden = true
        retryDraft.isHidden = true
        navigationItem.rightBarButtonItem?.isEnabled = false
        title = "Conversation unavailable"
        state.text = explanation
        updateSend()
    }

    @objc private func goBack() { navigationController?.popViewController(animated: true) }
    private func push(_ controller: UIViewController) {
        controller.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(controller, animated: true)
    }
    deinit { poll?.cancel(); draftTask?.cancel(); draftWriteTask?.cancel(); sendTask?.cancel() }
}

extension ConversationController: UIContextMenuInteractionDelegate {
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        guard let value = interaction.view?.accessibilityIdentifier, let userID = UUID(uuidString: value) else { return nil }
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { [weak self] _ in
            UIMenu(children: [UIAction(title: "View profile") { _ in
                self?.push(CreatorController(userID: userID))
            }, UIAction(title: "Report sender", attributes: .destructive) { _ in
                self?.push(ReportProfileController(userID: userID))
            }])
        }
    }
}

@MainActor
final class ConversationDetailsController: SocialPage {
    private let conversation: Conversation
    private var members: [Profile] = []
    private var accountID: UUID?
    private var accessRevoked = false
    init(conversation: Conversation) { self.conversation = conversation; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    override func viewDidLoad() {
        super.viewDidLoad()
        title = conversation.isGroup ? "Cooking group" : "Conversation"
        accountID = TiloBackend.shared.userID
        TiloBackend.shared.$inaccessibleConversationIDs.sink { [weak self] denied in
            guard let self, denied.contains(conversation.id) else { return }
            revokeDetails()
        }.store(in: &observations)
        TiloBackend.shared.$session.sink { [weak self] session in
            guard let self, session?.user.id != accountID else { return }
            revokeDetails()
        }.store(in: &observations)
    }
    override func viewWillAppear(_ animated: Bool) { super.viewWillAppear(animated); if !accessRevoked { loadMembers() } }
    private func revokeDetails() {
        accessRevoked = true
        members = []
        clearContent()
        title = "Conversation unavailable"
        add(text("This conversation is no longer available.", 18, color: TiloTheme.muted))
    }
    private func loadMembers() {
        perform { [weak self] in
            guard let self else { return }
            let current = try await TiloBackend.shared.conversationMembers(id: conversation.id)
            guard !accessRevoked, TiloBackend.shared.userID == accountID else { return }
            members = current
            render()
        }
    }
    private func render() {
        guard !accessRevoked, TiloBackend.shared.userID == accountID else { revokeDetails(); return }
        clearContent()
        add(text(conversation.title, 30, heading: true))
        add(text(conversation.isGroup ? "Around the table" : "People in this conversation", 18, heading: true))
        for member in members {
            add(socialPersonRow(member) { [weak self] in self?.push(CreatorController(userID: member.id)) })
            if conversation.isGroup, conversation.ownerID == TiloBackend.shared.userID, member.id != conversation.ownerID {
                add(action("Remove " + member.displayName, icon: .close) { [weak self] in
                    self?.confirm("Remove member?", detail: "They will no longer have access to this group.", destructive: "Remove") { [weak self] in
                        guard let self else { return }
                        try await TiloBackend.shared.changeMember(conversationID: conversation.id, userID: member.id, remove: true)
                        members = try await TiloBackend.shared.conversationMembers(id: conversation.id)
                        render()
                    }
                })
            }
        }
        if conversation.isGroup && conversation.ownerID == TiloBackend.shared.userID {
            add(action("Add a cooking friend", icon: .plus, filled: true) { [weak self] in
                guard let self else { return }
                self.push(GroupMemberPickerController(conversationID: self.conversation.id, existing: Set(self.members.map(\.id))))
            })
        }
        if conversation.isGroup {
            if conversation.ownerID == accountID && members.count > 1 {
                add(text("As the group owner, remove the other members before leaving.", 15, color:TiloTheme.muted))
            }
            add(action("Leave group", icon: .close) { [weak self] in
                guard let self else { return }
                if conversation.ownerID == accountID && members.count > 1 {
                    showNotice("Manage your group first", "Remove the other members before leaving your group.")
                    return
                }
                self.confirm("Leave this group?", detail: "You will stop receiving new group messages.", destructive: "Leave group") { [weak self] in
                    guard let self else { return }
                    try await TiloBackend.shared.leaveGroup(id: conversation.id)
                    navigationController?.popToRootViewController(animated: true)
                }
            })
        }
    }
}
