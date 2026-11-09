import XCTest
import UIKit
@testable import Tilo

@MainActor
final class TiloGiftEffectTests: XCTestCase {
    private func receipt() -> TiloGiftReceipt {
        TiloGiftReceipt(id: UUID(), giftID: "warm-thanks", giftName: "Warm thanks", unitDiamonds: 10,
                        quantity: 5, diamonds: 50, roomID: "effect-rendering", recipientID: UUID(), recipientName: "Rendering test", date: Date())
    }
    func testAnimatedEffectLeavesPlaybackControlsAvailableAndCleansUp() async throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.first as? UIWindowScene)
        let previous = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        window.frame = CGRect(x: 0, y: 0, width: 402, height: 874)
        let controller = UIViewController(); controller.view.backgroundColor = .black
        window.rootViewController = controller; window.makeKeyAndVisible()
        defer { window.isHidden = true; previous?.makeKeyAndVisible() }
        let playbackControl = UIButton(type: .custom); playbackControl.frame = controller.view.bounds
        controller.view.addSubview(playbackControl)
        let effect = RoomGiftEffectView(receipt: receipt())
        effect.frame = CGRect(x: 8, y: 145, width: 386, height: 276)
        controller.view.addSubview(effect)
        let finished = expectation(description: "Gift effect completes and removes its overlay")
        effect.play(reduceMotion: false) { finished.fulfill() }
        try await Task.sleep(for: .milliseconds(350))
        XCTAssertTrue(controller.view.hitTest(CGPoint(x: 201, y: 260), with: nil) === playbackControl)
        XCTAssertLessThan(effect.frame.maxY, 437, "The effect stays in the visible video above a half-height sheet")
        XCTAssertEqual(effect.accessibilityLabel, "Gift recorded: 5 × Warm thanks")
        let rendered = UIGraphicsImageRenderer(bounds: window.bounds).image { _ in window.drawHierarchy(in: window.bounds, afterScreenUpdates: true) }
        let attachment = XCTAttachment(image: rendered); attachment.name = "Gift effect raster animation rendering"; attachment.lifetime = .keepAlways; add(attachment)
        await fulfillment(of: [finished], timeout: 4)
        XCTAssertNil(effect.superview)
    }
    func testReducedMotionAndCancellationDoNotLeaveAnOverlay() async throws {
        let parent = UIView(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        let effect = RoomGiftEffectView(receipt: receipt())
        effect.frame = CGRect(x: 8, y: 145, width: 386, height: 276); parent.addSubview(effect)
        var completions = 0
        effect.play(reduceMotion: true) { completions += 1 }
        XCTAssertEqual(effect.subviews.compactMap { $0 as? UIImageView }.count, 1, "Reduced Motion uses a static gift without flying particles")
        XCTAssertEqual(effect.alpha, 1)
        XCTAssertFalse(effect.isUserInteractionEnabled)
        effect.cancel(); effect.cancel()
        XCTAssertEqual(completions, 1)
        XCTAssertNil(effect.superview)
        try await Task.sleep(for: .milliseconds(150))
        XCTAssertEqual(completions, 1)
    }
}
