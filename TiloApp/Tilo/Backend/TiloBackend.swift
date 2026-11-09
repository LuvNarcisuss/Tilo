import Foundation
import Combine
import UIKit
import Supabase

@MainActor
final class TiloBackend: ObservableObject {
    static let shared = TiloBackend()
    @Published private(set) var profile: Profile?
    @Published private(set) var session: Session?
    @Published private(set) var conversations: [Conversation] = []
    @Published private(set) var messages: [Message] = []
    @Published private(set) var users: [Profile] = []
    @Published var error: String?
    @Published private(set) var realtimeConnected = false
    @Published private(set) var inaccessibleConversationIDs: Set<UUID> = []
    private(set) var safetyRevision = 0
    var userID: UUID? { session?.user.id }

    private let client: SupabaseClient
    private let transport: URLSession
    private var channel: RealtimeChannelV2?
    private var eventTasks: [Task<Void, Never>] = []
    private var authTask: Task<Void, Never>?
    private var activeConversationID: UUID?
    private var generation = UUID()
    private var conversationLoadID = UUID()
    private var signingIn = false
    private var foregroundObserver: NSObjectProtocol?

    private init() {
        client = SupabaseClient(supabaseURL: TiloBackendConfiguration.projectURL, supabaseKey: TiloBackendConfiguration.publishableKey, options: .init(auth: .init(storage: KeychainSessionStorage())))
        let configuration = URLSessionConfiguration.ephemeral
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.timeoutIntervalForRequest = 30
        transport = URLSession(configuration: configuration)
        session = client.auth.currentSession
        authTask = Task { [weak self] in
            guard let self else { return }
            for await (_, restored) in await client.auth.authStateChanges {
                if Task.isCancelled { return }
                let previous = self.session?.user.id
                self.session = restored
                if previous != restored?.user.id { self.generation = UUID() }
                if restored == nil { await self.stopRealtime(); self.clearAccountState() }
            }
        }
        foregroundObserver = NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                guard let self, self.session != nil else { return }
                do { try await self.reconcile() } catch { self.error = error.localizedDescription }
            }
        }
    }

    /// Called only after the welcome screen confirms adulthood and both agreements.
    func signIn() async throws {
        guard !signingIn else { throw BackendError.message("Login is already in progress.") }
        signingIn = true
        defer { signingIn = false }
        error = nil
        if client.auth.currentSession != nil {
            session = try await client.auth.session
        } else {
            session = try await client.auth.signInAnonymously()
        }
        let _: BootstrapReply = try await function("bootstrap", body: [:])
        let _: EmptyReply = try await rpc("acceptAgreements", ["version": TiloBackendConfiguration.agreementVersion, "adultConfirmed": true])
        try await refreshProfile()
        try await startRealtime()
        try await refreshConversations()
    }

    /// Restores the same Keychain identity; a failed refresh never creates a replacement account.
    func restoreSession() async throws -> Bool {
        guard client.auth.currentSession != nil else { return false }
        session = try await client.auth.session
        let _: BootstrapReply = try await function("bootstrap", body: [:])
        try await refreshProfile()
        try await startRealtime()
        try await refreshConversations()
        return true
    }

    func signOut() async throws {
        try TiloWallet.shared.beginSessionEnd()
        defer { TiloWallet.shared.cancelSessionEnd() }
        try await client.auth.signOut()
        await stopRealtime()
        session = nil
        clearAccountState()
        NotificationCenter.default.post(name: Notification.Name("TiloSessionEnded"), object: nil)
    }

    func deleteAccount() async throws {
        guard let originalID = userID else { throw BackendError.authentication }
        try TiloWallet.shared.beginSessionEnd()
        defer { TiloWallet.shared.cancelSessionEnd() }
        let _: EmptyReply = try await function("delete-account", body: [:])
        var localCleanupFailed = false
        do { try TiloDraftStorage.deleteAccount(originalID) } catch { localCleanupFailed = true }
        do { try TiloWallet.shared.deleteLocalAccount(originalID) } catch { localCleanupFailed = true }
        // The server has revoked sessions and deleted the account; clear its local Keychain session.
        do { try await client.auth.signOut(scope: .local) } catch { localCleanupFailed = true }
        session = nil
        clearAccountState()
        TiloWallet.shared.endSession(preservingReservation: true)
        await stopRealtime()
        let warning = localCleanupFailed ? "Your cloud account was deleted, but some private data on this device could not be removed." : nil
        if let warning { self.error = warning }
        NotificationCenter.default.post(name: Notification.Name("TiloSessionEnded"), object: nil, userInfo: warning.map { ["warning": $0] })
    }

    func refreshProfile() async throws {
        profile = nil
        profile = try await rpc("profile")
    }
    func fetchProfile(id: UUID) async throws -> Profile { try await rpc("profile", ["userID": id.uuidString]) }
    func updateProfile(displayName: String, username: String, bio: String, dietaryTags: [String], skillLevel: String, avatarURL: String? = nil) async throws {
        var body: [String: Any] = ["displayName": displayName, "username": username, "bio": bio, "dietaryTags": dietaryTags, "skillLevel": skillLevel]
        if let avatarURL { body["avatarURL"] = avatarURL }
        let updated: Profile = try await rpc("updateProfile", body)
        profile = updated
    }
    func uploadAvatar(data: Data) async throws -> String {
        guard let userID else { throw BackendError.authentication }
        guard data.count <= 5_242_880, UIImage(data: data) != nil else { throw BackendError.message("Choose an image smaller than 5 MB.") }
        let path = "\(userID.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
        guard let jpeg = UIImage(data: data)?.jpegData(compressionQuality: 0.85) else { throw BackendError.message("This image could not be read.") }
        _ = try await client.storage.from("avatars").upload(path, data: jpeg, options: FileOptions(contentType: "image/jpeg", upsert: false))
        return try client.storage.from("avatars").getPublicURL(path: path).absoluteString
    }
    func searchUsers(query: String) async throws -> [Profile] {
        users = []
        let result: [Profile] = try await rpc("searchUsers", ["query": query])
        users = result
        return result
    }
    func relationships(userID: UUID, kind: String) async throws -> [Profile] { try await rpc("relationships", ["userID": userID.uuidString, "kind": kind]) }
    func setFollow(userID: UUID, following: Bool) async throws { try await mutate("setFollow", ["userID": userID.uuidString, "following": following]); try await refreshProfile() }
    func blockedUsers() async throws -> [Profile] { try await rpc("blockedUsers") }
    func block(userID: UUID) async throws { try await mutate("block", ["userID": userID.uuidString]); await safetyChanged(clearConversations:true) }
    func unblock(userID: UUID) async throws { try await mutate("unblock", ["userID": userID.uuidString]); await safetyChanged(clearConversations:false) }
    func report(kind: String, targetID: String, reason: String) async throws {
        let _: EmptyReply = try await safety("report", ["kind":kind, "id":targetID, "reason":reason])
    }
    func safetyContext(kind: String, id: String) async throws -> ContentSafetyContext { try await safety("context", ["kind":kind, "id":id]) }
    func blockContentAuthor(_ context: ContentSafetyContext) async throws {
        let _: EmptyReply = try await safety("blockAuthor", ["kind":context.kind, "id":context.id])
        await safetyChanged(clearConversations:true)
    }
    func hideContent(_ context: ContentSafetyContext) async throws {
        let _: EmptyReply = try await safety("hide", ["kind":context.kind, "id":context.id])
        await safetyChanged(clearConversations:false)
    }
    func hiddenContents() async throws -> [HiddenContent] { try await safety("hidden") }
    func unhideContent(_ content: HiddenContent) async throws {
        let _: EmptyReply = try await safety("unhide", ["kind":content.kind, "id":content.id])
        await safetyChanged(clearConversations:false)
    }
    private func safetyChanged(clearConversations: Bool) async {
        let current = generation
        safetyRevision += 1
        if clearConversations {
            conversations = []; messages = []; users = []
        }
        NotificationCenter.default.post(name:Notification.Name("TiloContentSafetyChanged"),object:nil)
        do { try await reconcile() }
        catch { if current == generation { self.error = "Your safety change was saved. Conversations could not refresh yet." } }
    }
    private func safety<T: Decodable>(_ action: String, _ body: [String: Any] = [:]) async throws -> T {
        try await request(path:"rest/v1/rpc/toli_safety", body:["action":action,"body":body])
    }
    func report(userID: UUID, reason: String) async throws { try await mutate("report", ["userID": userID.uuidString, "reason": reason]) }

    func recipes(category: String? = nil, query: String? = nil) async throws -> [Recipe] {
        var body: [String: Any] = [:]
        if let category { body["category"] = category }
        if let query { body["query"] = query }
        var all: [Recipe] = []
        for offset in stride(from: 0, through: 10_000, by: 100) {
            body["offset"] = offset
            let page: [Recipe] = try await rpc("recipes", body)
            all.append(contentsOf: page)
            if page.count < 100 { return all }
        }
        return all
    }
    func recipe(id: String) async throws -> Recipe { try await rpc("recipe", ["id": id]) }
    func videos() async throws -> [CookingVideo] { try await rpc("videos") }
    func savedRecipes() async throws -> [Recipe] { try await recipeCollection(scope: "saved", userID: nil) }
    func recipeCollection(scope: String, userID: UUID? = nil) async throws -> [Recipe] {
        var body: [String: Any] = ["scope": scope]
        if let userID { body["userID"] = userID.uuidString }
        return try await rpc("recipeCollection", body)
    }
    func saveRecipe(draft: RecipeDraft) async throws -> Recipe { try await publishRecipe(draft) }
    func publishRecipe(_ draft: RecipeDraft) async throws -> Recipe {
        let data = try JSONEncoder().encode(draft)
        guard let body = try JSONSerialization.jsonObject(with: data) as? [String: Any] else { throw BackendError.message("Recipe could not be saved.") }
        return try await rpc("publishRecipe", body)
    }
    func uploadRecipePhoto(data: Data) async throws -> String {
        guard let userID else { throw BackendError.authentication }
        guard data.count <= 10_485_760, let jpeg = UIImage(data: data)?.jpegData(compressionQuality: 0.85) else { throw BackendError.message("Choose an image smaller than 10 MB.") }
        let path = "\(userID.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
        _ = try await client.storage.from("recipe-photos").upload(path, data: jpeg, options: FileOptions(contentType: "image/jpeg", upsert: false))
        return try client.storage.from("recipe-photos").getPublicURL(path: path).absoluteString
    }
    func addGroceries(items: [RecipeIngredient], scale: Double) async throws {
        let body: [[String: Any]] = items.map { ["name": $0.name, "quantity": $0.quantity, "unit": $0.unit] }
        try await mutate("addGroceries", ["items": body, "scale": scale])
    }
    func deleteRecipe(id: String) async throws { try await mutate("deleteRecipe", ["id": id]) }
    func toggleBookmark(recipeID: String, saved: Bool) async throws { try await mutate("toggleBookmark", ["recipeID": recipeID, "saved": saved]) }
    func toggleLike(contentID: String, liked: Bool) async throws { try await mutate("toggleLike", ["contentID": contentID, "liked": liked]) }
    func likedContentIDs() async throws -> [String] { try await rpc("likedContentIDs") }
    func comments(contentID: String) async throws -> [ContentComment] { try await rpc("comments", ["contentID": contentID]) }
    func addComment(contentID: String, body: String) async throws { try await mutate("addComment", ["contentID": contentID, "body": body]) }
    func mealPlans() async throws -> [MealPlan] { try await rpc("mealPlans") }
    func saveMeal(date: String, slot: String, recipeID: String) async throws { try await mutate("saveMeal", ["date": date, "slot": slot, "recipeID": recipeID]) }
    func removeMeal(id: UUID) async throws { try await mutate("removeMeal", ["id": id.uuidString]) }
    func groceries() async throws -> [GroceryItem] { try await rpc("groceries") }
    func addGrocery(name: String, quantity: String) async throws { try await mutate("addGrocery", ["name": name, "quantity": quantity]) }
    func updateGrocery(id: UUID, checked: Bool) async throws { try await mutate("updateGrocery", ["id": id.uuidString, "checked": checked]) }
    func removeGrocery(id: UUID) async throws { try await mutate("removeGrocery", ["id": id.uuidString]) }

    func createDirect(userID: UUID) async throws -> Conversation {
        let result: Conversation = try await rpc("createDirect", ["userID": userID.uuidString])
        try await refreshConversations()
        return result
    }
    func createGroup(title: String, memberIDs: [UUID]) async throws -> Conversation {
        let result: Conversation = try await rpc("createGroup", ["title": title, "memberIDs": memberIDs.map(\.uuidString)])
        try await refreshConversations()
        return result
    }
    @discardableResult
    func refreshConversations() async throws -> [Conversation] {
        let current = generation
        let loadID = UUID()
        conversationLoadID = loadID
        let result: [Conversation] = try await rpc("conversations")
        guard current == generation else { throw CancellationError() }
        if loadID == conversationLoadID { conversations = result }
        return result
    }
    func openConversation(id: UUID) async throws {
        activeConversationID = id
        messages = []
        if channel == nil { try await startRealtime() }
        let result = try await loadMessages(conversationID: id)
        guard activeConversationID == id else { return }
        inaccessibleConversationIDs.remove(id)
        messages = result
        try await markRead(conversationID: id)
    }
    private func invalidateActiveConversation(_ id: UUID) { inaccessibleConversationIDs.insert(id); if activeConversationID == id { activeConversationID = nil; messages = [] } }
    func closeConversation() { activeConversationID = nil; messages = [] }
    func loadMessages(conversationID: UUID, before: String? = nil) async throws -> [Message] {
        var body: [String: Any] = ["conversationID": conversationID.uuidString]
        if let before { body["before"] = before }
        return try await rpc("messages", body)
    }
    func uploadChatImage(data: Data, conversationID: UUID) async throws -> String {
        let _: [Profile] = try await rpc("conversationMembers", ["conversationID": conversationID.uuidString])
        guard let userID else { throw BackendError.authentication }
        guard data.count <= 10_485_760, let jpeg = UIImage(data: data)?.jpegData(compressionQuality: 0.85) else { throw BackendError.message("Choose an image smaller than 10 MB.") }
        let path = "\(conversationID.uuidString.lowercased())/\(userID.uuidString.lowercased())/\(UUID().uuidString.lowercased()).jpg"
        do {
            _ = try await client.storage.from("chat-images").upload(path, data: jpeg, options: FileOptions(contentType: "image/jpeg", upsert: false))
            return path
        } catch {
            let _: [Profile] = try await rpc("conversationMembers", ["conversationID": conversationID.uuidString])
            throw BackendError.message("Photo could not upload. Please retry.")
        }
    }
    func chatImageURL(path: String) async throws -> URL {
        guard let first = path.split(separator: "/").first, let id = UUID(uuidString: String(first)) else { throw BackendError.message("Photo is unavailable.") }
        let _: [Profile] = try await rpc("conversationMembers", ["conversationID": id.uuidString])
        do { return try await client.storage.from("chat-images").createSignedURL(path: path, expiresIn: 300) }
        catch {
            let _: [Profile] = try await rpc("conversationMembers", ["conversationID": id.uuidString])
            throw BackendError.message("Photo could not load. Please retry.")
        }
    }
    func sendMessage(conversationID: UUID, body: String, clientID: UUID = UUID(), imagePath: String? = nil) async throws {
        var payload: [String: Any] = ["conversationID": conversationID.uuidString, "body": body, "clientID": clientID.uuidString]
        if let imagePath { payload["imagePath"] = imagePath }
        let message: Message = try await rpc("sendMessage", payload)
        if activeConversationID == conversationID { merge([message]) }
        Task { [weak self] in do { try await self?.refreshConversations() } catch { self?.error = "Message sent. Conversation list could not refresh." } }
    }
    func markRead(conversationID: UUID) async throws { try await mutate("markRead", ["conversationID": conversationID.uuidString]); try await refreshConversations() }
    func updateConversation(id: UUID, pinned: Bool? = nil, muted: Bool? = nil, draft: String? = nil) async throws {
        var body: [String: Any] = ["conversationID": id.uuidString]
        if let pinned { body["pinned"] = pinned }
        if let muted { body["muted"] = muted }
        if let draft { body["draft"] = draft }
        try await mutate("updateConversation", body)
        try await refreshConversations()
    }
    func deleteConversation(id: UUID) async throws { try await mutate("deleteConversation", ["conversationID": id.uuidString]); try await refreshConversations() }
    func conversationMembers(id: UUID) async throws -> [Profile] { try await rpc("conversationMembers", ["conversationID": id.uuidString]) }
    func changeMember(conversationID: UUID, userID: UUID, remove: Bool) async throws { try await mutate("changeMember", ["conversationID": conversationID.uuidString, "userID": userID.uuidString, "remove": remove]); try await refreshConversations() }
    func leaveGroup(id: UUID) async throws { try await mutate("leaveGroup", ["conversationID": id.uuidString]); if activeConversationID == id { closeConversation() }; try await refreshConversations() }

    private func startRealtime() async throws {
        await stopRealtime()
        guard let identity = userID else { throw BackendError.authentication }
        let current = generation
        let next = client.channel("toli-account-\(identity.uuidString)")
        let messageChanges = next.postgresChange(InsertAction.self, schema: "public", table: "messages")
        let conversationChanges = next.postgresChange(UpdateAction.self, schema: "public", table: "conversations")
        let memberChanges = next.postgresChange(UpdateAction.self, schema: "public", table: "conversation_members", filter: "user_id=eq.\(identity.uuidString.lowercased())")
        channel = next
        eventTasks.append(Task { [weak self] in
            for await _ in messageChanges { guard !Task.isCancelled, let self, self.generation == current else { return }; await self.handleRemoteChange() }
        })
        eventTasks.append(Task { [weak self] in
            for await _ in conversationChanges { guard !Task.isCancelled, let self, self.generation == current else { return }; await self.handleRemoteChange() }
        })
        eventTasks.append(Task { [weak self] in
            for await _ in memberChanges { guard !Task.isCancelled, let self, self.generation == current else { return }; await self.handleRemoteChange() }
        })
        eventTasks.append(Task { [weak self] in
            for await status in next.statusChange {
                guard !Task.isCancelled, let self, self.generation == current else { return }
                self.realtimeConnected = status == .subscribed
                if status == .subscribed { await self.handleRemoteChange() }
            }
        })
        do { try await next.subscribeWithError(); realtimeConnected = true }
        catch { await stopRealtime(); throw BackendError.message("Chat could not connect. Please try again.") }
    }
    private func stopRealtime() async {
        eventTasks.forEach { $0.cancel() }; eventTasks = []
        if let channel { await client.removeChannel(channel) }
        channel = nil
        realtimeConnected = false
    }
    private func handleRemoteChange() async {
        do { try await reconcile() } catch { self.error = error.localizedDescription }
    }
    private func reconcile() async throws {
        let current = generation
        let resultConversations: [Conversation] = try await rpc("conversations")
        guard current == generation else { return }
        conversations = resultConversations
        guard let id = activeConversationID else { return }
        guard resultConversations.contains(where: { $0.id == id }) else { invalidateActiveConversation(id); return }
        let result = try await loadMessages(conversationID: id)
        guard current == generation, activeConversationID == id else { return }
        merge(result)
    }
    private func merge(_ incoming: [Message]) {
        var unique = Dictionary(uniqueKeysWithValues: messages.map { ($0.id, $0) })
        incoming.forEach { unique[$0.id] = $0 }
        messages = unique.values.sorted { $0.createdAt == $1.createdAt ? $0.id.uuidString < $1.id.uuidString : $0.createdAt < $1.createdAt }
    }
    private func clearAccountState() { generation = UUID(); inaccessibleConversationIDs = []; profile = nil; conversations = []; messages = []; users = []; activeConversationID = nil }

    func addRoomReaction(contentID: String, id: UUID) async throws {
        guard let accountID = userID else { throw BackendError.authentication }
        let receipts: [RoomReactionReceipt] = try await request(path: "rest/v1/room_reactions", body: [
            "id": id.uuidString, "user_id": accountID.uuidString, "content_id": contentID
        ], returning: true)
        guard userID == accountID, receipts.count == 1, receipts.first?.id == id else {
            throw BackendError.message("Your reaction could not be confirmed. Please try again.")
        }
    }
    private struct RoomReactionReceipt: Decodable { let id: UUID }
    private func mutate(_ action: String, _ body: [String: Any] = [:]) async throws { let _: EmptyReply = try await rpc(action, body) }
    private func rpc<T: Decodable>(_ action: String, _ body: [String: Any] = [:]) async throws -> T {
        try await request(path: "rest/v1/rpc/toli_action", body: ["action": action, "body": body])
    }
    private func function<T: Decodable>(_ name: String, body: [String: Any]) async throws -> T { try await request(path: "functions/v1/\(name)", body: body) }
    private func request<T: Decodable>(path: String, body: [String: Any], returning: Bool = false) async throws -> T {
        let current = generation
        let expectedUserID = session?.user.id
        let fresh = try await client.auth.session
        guard current == generation, fresh.user.id == expectedUserID else { throw CancellationError() }
        var request = URLRequest(url: TiloBackendConfiguration.projectURL.appendingPathComponent(path))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if returning { request.setValue("return=representation", forHTTPHeaderField: "Prefer") }
        request.setValue(TiloBackendConfiguration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(fresh.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await transport.data(for: request)
        guard current == generation else { throw CancellationError() }
        guard let response = response as? HTTPURLResponse else { throw BackendError.message("The service did not respond. Please retry.") }
        guard (200..<300).contains(response.statusCode) else {
            if response.statusCode == 401 { throw BackendError.authentication }
            let parsed = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
            let message = parsed?["message"] as? String ?? ""
            if body["action"] as? String == "updateProfile", parsed?["code"] as? String == "23505",
               message.contains("profiles_username_key") {
                throw BackendError.message("That username is already in use. Choose another.")
            }
            if message == "Conversation access denied" {
                if let actionBody = body["body"] as? [String: Any], let cid = actionBody["conversationID"] as? String, let id = UUID(uuidString: cid) { invalidateActiveConversation(id) }
                throw BackendError.accessDenied
            }
            let safeMessages = ["Follow this cook to send private messages", "Invite mutual followers only", "Profile unavailable", "Conversation access denied", "Only the group owner can manage other members", "Remove other members before leaving your group", "Message retry differs from original", "Recipe unavailable", "Content unavailable"]
            if safeMessages.contains(message) { throw BackendError.message(message + ".") }
            throw BackendError.message("This change could not be saved. Please check your connection and try again.")
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
    private struct BootstrapReply: Decodable { let code: Int; let message: String; let data: [String: String] }
    private struct EmptyReply: Decodable {}
    enum BackendError: LocalizedError {
        case authentication, accessDenied, message(String)
        var errorDescription: String? {
            switch self { case .accessDenied: return "You no longer have access to this conversation."; case .authentication: return "Your session could not be restored. Please log in again."; case .message(let text): return text }
        }
    }
}
