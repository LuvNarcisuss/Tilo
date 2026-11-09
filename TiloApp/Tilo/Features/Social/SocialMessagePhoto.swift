import UIKit

@MainActor
final class SocialMessagePhoto: UIView {
    private let path: String
    private let conversationID: UUID
    private let accountID: UUID?
    private let photo = UIImageView()
    private let status = UILabel()
    private var task: Task<Void, Never>?
    private lazy var retry = Tilo.action("Retry photo", icon: .clock) { [weak self] in self?.load() }
    private static let transport = URLSession(configuration: .ephemeral)

    init(path: String, conversationID: UUID) {
        self.path = path
        self.conversationID = conversationID
        accountID = TiloBackend.shared.userID
        super.init(frame: .zero)
        backgroundColor = TiloTheme.cream
        round(16)
        photo.contentMode = .scaleAspectFit
        photo.isAccessibilityElement = true
        photo.accessibilityLabel = "Photo attached to message"
        status.font = TiloTheme.font(13)
        status.textColor = TiloTheme.muted
        status.numberOfLines = 0
        status.textAlignment = .center
        let controls = socialStack([status, retry], spacing: 8)
        addSubview(photo)
        addSubview(controls)
        photo.translatesAutoresizingMaskIntoConstraints = false
        controls.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 210), widthAnchor.constraint(greaterThanOrEqualToConstant: 160),
            photo.leadingAnchor.constraint(equalTo: leadingAnchor), photo.trailingAnchor.constraint(equalTo: trailingAnchor),
            photo.topAnchor.constraint(equalTo: topAnchor), photo.bottomAnchor.constraint(equalTo: bottomAnchor),
            controls.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12), controls.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            controls.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
        load()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is unavailable") }
    private func load() {
        task?.cancel()
        status.text = "Loading photo…"
        retry.isHidden = true
        task = Task { [weak self, path, conversationID, accountID] in
            do {
                let backend = TiloBackend.shared
                let url = try await backend.chatImageURL(path: path)
                guard !Task.isCancelled, backend.userID == accountID, !backend.inaccessibleConversationIDs.contains(conversationID) else { return }
                let (data, response) = try await Self.transport.data(from: url)
                guard !Task.isCancelled, let self, backend.userID == accountID, !backend.inaccessibleConversationIDs.contains(conversationID) else { return }
                guard (response as? HTTPURLResponse)?.statusCode == 200, data.count <= 10_485_760, let image = UIImage(data: data) else {
                    status.text = "Photo could not be opened."
                    retry.isHidden = false
                    return
                }
                photo.image = image
                status.text = nil
            } catch {
                guard !Task.isCancelled, let self, TiloBackend.shared.userID == accountID,
                      !TiloBackend.shared.inaccessibleConversationIDs.contains(conversationID) else { return }
                status.text = "Photo could not load."
                retry.isHidden = false
            }
        }
    }
    deinit { task?.cancel() }
}
