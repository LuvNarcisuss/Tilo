import AVFoundation
import UIKit
import XCTest
@testable import Tilo

@MainActor
final class TiloVideoCallPreviewTests: XCTestCase {
    func testGroupOmitsVideoEntryAndUnvalidatedDirectChatDisablesIt() throws {
        for isGroup in [false, true] {
            let conversation = Conversation(
                id: UUID(), title: "Kitchen conversation", isGroup: isGroup,
                ownerID: UUID(), lastMessage: nil, updatedAt: "", unreadCount: 0,
                isPinned: false, isMuted: false, draft: "", peerID: nil, avatarURL: nil
            )
            let chat = ConversationController(conversation: conversation)
            chat.loadViewIfNeeded()
            let item = chat.navigationItem.rightBarButtonItems?.first { $0.customView?.accessibilityIdentifier == "chat-video-call" }
            if isGroup {
                XCTAssertNil(item)
            } else {
                let button = try XCTUnwrap(item?.customView as? UIButton)
                XCTAssertFalse(button.isEnabled)
            }
        }
    }

    func testUnavailableCameraKeepsLocalControlsAndEndCallAvailable() async throws {
        try XCTSkipIf(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil)
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let presenter = UIViewController()
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let preview = VideoCallPreviewController(conversationTitle: "Kitchen conversation")
        preview.modalPresentationStyle = .fullScreen
        await withCheckedContinuation { continuation in
            presenter.present(preview, animated: false) { continuation.resume() }
        }

        let status = try XCTUnwrap(find("video-preview-status", in: preview.view) as? UILabel)
        let unavailable = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            status.text == "The camera is unavailable on this device right now."
        }, object: nil)
        await fulfillment(of: [unavailable], timeout: 3)
        XCTAssertFalse(status.isHidden)
        let microphone = try XCTUnwrap(find("video-preview-microphone", in: preview.view) as? UIButton)
        let speaker = try XCTUnwrap(find("video-preview-speaker", in: preview.view) as? UIButton)
        XCTAssertEqual(microphone.accessibilityValue, "On")
        XCTAssertEqual(speaker.accessibilityValue, "On")
        microphone.sendActions(for: .primaryActionTriggered)
        speaker.sendActions(for: .primaryActionTriggered)
        XCTAssertEqual(microphone.configuration?.title, "Microphone off")
        XCTAssertEqual(microphone.accessibilityValue, "Off")
        XCTAssertEqual(speaker.configuration?.title, "Speaker off")
        XCTAssertEqual(speaker.accessibilityValue, "Off")

        let end = try XCTUnwrap(find("video-preview-end", in: preview.view) as? UIButton)
        attachScreenshot("Local video preview with camera unavailable", in: window)
        if #available(iOS 17.0, *) {
            preview.traitOverrides.preferredContentSizeCategory = .accessibilityExtraExtraExtraLarge
            preview.view.layoutIfNeeded()
            let controls = try XCTUnwrap(microphone.superview as? UIStackView)
            XCTAssertEqual(controls.axis, .vertical)
            for button in [microphone, end, speaker] {
                XCTAssertGreaterThanOrEqual(button.bounds.height, 44)
            }
            attachScreenshot("Local video preview heading with large accessibility text", in: window)
            let scroll = preview.scroll
            let bottom = scroll.contentSize.height - scroll.bounds.height + scroll.adjustedContentInset.bottom
            scroll.setContentOffset(CGPoint(x: 0, y: bottom), animated: false)
            let endFrame = end.convert(end.bounds, to: window)
            XCTAssertTrue(window.bounds.contains(endFrame))
            attachScreenshot("Local video preview controls with large accessibility text", in: window)
        }
        end.sendActions(for: .primaryActionTriggered)
        let dismissed = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            presenter.presentedViewController == nil
        }, object: nil)
        await fulfillment(of: [dismissed], timeout: 3)
    }

    func testServerValidatedDirectChatOpensAndClosesPreview() async throws {
        try XCTSkipUnless(ProcessInfo.processInfo.environment["TILO_ISOLATED_VIDEO_ACCEPTANCE"] == "1")
        try XCTSkipIf(AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) != nil)
        let backend = TiloBackend.shared
        let hasExistingSession = try await backend.restoreSession()
        try XCTSkipIf(hasExistingSession || backend.userID != nil, "The test must preserve an existing session.")
        guard TiloBackendConfiguration.projectURL.host == "hdapofqufmxlghmcrftg.supabase.co" else {
            throw FixtureError.unexpectedProject
        }

        var partner: AcceptanceSession?
        var simulatorAccount: UUID?
        var flowError: Error?
        do {
            do { try await backend.signIn() }
            catch {
                simulatorAccount = backend.userID
                throw error
            }
            let account = try XCTUnwrap(backend.userID)
            simulatorAccount = account
            XCTAssertTrue(backend.conversations.isEmpty)
            let session = try JSONDecoder().decode(AcceptanceSession.self, from: await fixtureRequest(
                "auth/v1/signup", body: ["data": ["acceptance_run": "tilo-video-preview"]]
            ))
            partner = session
            XCTAssertNotEqual(account, session.user.id)
            print("Video acceptance fixture IDs: \(account.uuidString), \(session.user.id.uuidString)")
            _ = try await fixtureRequest("functions/v1/bootstrap", token: session.accessToken)
            _ = try await fixtureRequest("rest/v1/rpc/toli_action", token: session.accessToken, body: [
                "action": "acceptAgreements",
                "body": ["version": TiloBackendConfiguration.agreementVersion, "adultConfirmed": true]
            ])
            _ = try await fixtureRequest("rest/v1/rpc/toli_action", token: session.accessToken, body: [
                "action": "profile", "body": [:]
            ])
            try await backend.setFollow(userID: session.user.id, following: true)
            let following = try await backend.relationships(userID: account, kind: "following")
            XCTAssertTrue(following.contains { $0.id == session.user.id })
            let direct = try await backend.createDirect(userID: session.user.id)
            XCTAssertFalse(direct.isGroup)
            try await exerciseDirectChat(direct, backend: backend, partnerID: session.user.id)
        } catch {
            flowError = error
        }
        if let simulatorAccount {
            if backend.userID == simulatorAccount {
                do { try await backend.deleteAccount() }
                catch { XCTFail("The simulator fixture could not be deleted: \(error)") }
            } else {
                XCTFail("The simulator session changed. Preserve the current account.")
            }
        }
        if let partner {
            do {
                _ = try await fixtureRequest("functions/v1/delete-account", token: partner.accessToken)
            } catch {
                XCTFail("The peer fixture could not be deleted: \(error)")
            }
        }
        if let flowError { throw flowError }
    }

    private func exerciseDirectChat(_ direct: Conversation, backend: TiloBackend, partnerID: UUID) async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let presenter = UIViewController()
        let chat = ConversationController(conversation: direct)
        let navigation = UINavigationController(rootViewController: chat)
        styleNavigation(navigation)
        navigation.modalPresentationStyle = .fullScreen
        window.rootViewController = presenter
        window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        await withCheckedContinuation { continuation in
            presenter.present(navigation, animated: false) { continuation.resume() }
        }

        chat.loadViewIfNeeded()
        let entry = try XCTUnwrap(videoEntry(in: chat))
        try await waitFor("Video entry enabled after server validation") { entry.isEnabled }
        attachScreenshot("Video entry in validated direct chat", in: window)
        entry.sendActions(for: .primaryActionTriggered)
        try await waitFor("Full-screen video preview opened from chat") {
            (navigation.presentedViewController ?? chat.presentedViewController) is VideoCallPreviewController
        }
        let preview = try XCTUnwrap((navigation.presentedViewController ?? chat.presentedViewController) as? VideoCallPreviewController)
        XCTAssertEqual(preview.modalPresentationStyle, .fullScreen)
        let status = try XCTUnwrap(find("video-preview-status", in: preview.view) as? UILabel)
        try await waitFor("Simulator camera unavailable notice shown") {
            status.text == "The camera is unavailable on this device right now."
        }
        let end = try XCTUnwrap(find("video-preview-end", in: preview.view) as? UIButton)
        end.sendActions(for: .primaryActionTriggered)
        try await waitFor("Hang-up returns to the same direct chat") {
            navigation.presentedViewController == nil && chat.presentedViewController == nil && entry.isEnabled
        }
        XCTAssertTrue(navigation.topViewController === chat)
        let messages = try await backend.loadMessages(conversationID: direct.id)
        XCTAssertTrue(messages.isEmpty)

        try await backend.setFollow(userID: partnerID, following: false)
        let reopened = ConversationController(conversation: direct)
        navigation.setViewControllers([reopened], animated: false)
        reopened.loadViewIfNeeded()
        let disabledEntry = try XCTUnwrap(videoEntry(in: reopened))
        try await waitFor("Existing chat acknowledges that the sender no longer follows the peer") {
            containsText("Follow this cook to send private messages.", in: reopened.view)
        }
        XCTAssertFalse(disabledEntry.isEnabled)
        attachScreenshot("Video entry disabled after unfollowing", in: window)
    }

    private func videoEntry(in chat: ConversationController) -> UIButton? {
        chat.navigationItem.rightBarButtonItems?.first {
            $0.customView?.accessibilityIdentifier == "chat-video-call"
        }?.customView as? UIButton
    }

    private func containsText(_ value: String, in view: UIView) -> Bool {
        (view as? UILabel)?.text == value || view.subviews.contains { containsText(value, in: $0) }
    }

    private func waitFor(_ description: String, _ condition: () -> Bool) async throws {
        let deadline = Date().addingTimeInterval(18)
        while !condition() {
            guard Date() < deadline else { throw FixtureError.timeout(description) }
            try await Task.sleep(for: .milliseconds(100))
        }
    }

    private struct AcceptanceSession: Decodable {
        struct User: Decodable { let id: UUID }
        let accessToken: String
        let user: User
        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case user
        }
    }

    private enum FixtureError: Error {
        case unexpectedProject
        case invalidResponse(String, Int)
        case timeout(String)
    }

    private func fixtureRequest(_ path: String, token: String? = nil, body: [String: Any] = [:]) async throws -> Data {
        let url = TiloBackendConfiguration.projectURL.appendingPathComponent(path)
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.httpMethod = "POST"
        request.setValue(TiloBackendConfiguration.publishableKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token { request.setValue("Bearer " + token, forHTTPHeaderField: "Authorization") }
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else { throw FixtureError.invalidResponse(path, status) }
        return data
    }

    private func attachScreenshot(_ name: String, in window: UIWindow) {
        let rendered = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
        let attachment = XCTAttachment(image: rendered)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func find(_ identifier: String, in view: UIView) -> UIView? {
        if view.accessibilityIdentifier == identifier { return view }
        return view.subviews.lazy.compactMap { self.find(identifier, in: $0) }.first
    }
}
