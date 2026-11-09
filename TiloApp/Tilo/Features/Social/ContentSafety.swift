import UIKit

@MainActor
enum ContentSafety {
    static func addActions(to sheet: UIAlertController, context: ContentSafetyContext, host: UIViewController, changed: @escaping () -> Void) {
        guard !context.isOwn else { return }
        let label = context.kind == "video" ? "Report replay" : context.kind == "comment" ? "Report comment" : "Report recipe"
        sheet.addAction(UIAlertAction(title:label, style:.destructive) { [weak host] _ in
            guard let host else { return }; report(kind:context.kind, id:context.id, host:host)
        })
        if let authorID = context.authorID {
            sheet.addAction(UIAlertAction(title:"Report cook", style:.destructive) { [weak host] _ in
                guard let host else { return }; report(kind:"profile", id:authorID.uuidString.lowercased(), host:host)
            })
            sheet.addAction(UIAlertAction(title:"Block cook", style:.destructive) { [weak host] _ in
                guard let host else { return }
                confirm(host:host, title:"Block this cook?", detail:"Their content and messages will be hidden. Your follows will be removed. You can manage blocked cooks in Settings.", action:"Block") {
                    try await TiloBackend.shared.blockContentAuthor(context); changed()
                }
            })
        }
        if context.kind == "recipe" || context.kind == "video" {
            let name = context.kind == "video" ? "replay" : "recipe"
            sheet.addAction(UIAlertAction(title:"Hide " + name, style:.destructive) { [weak host] _ in
                guard let host else { return }
                confirm(host:host, title:"Hide this " + name + "?", detail:"It will be hidden from your discovery and collections. You can restore it in Settings under Hidden content.", action:"Hide") {
                    try await TiloBackend.shared.hideContent(context); changed()
                }
            })
        }
    }

    static func message(_ comment: ContentComment, host: UIViewController, source: UIView?, changed: @escaping () -> Void) {
        guard comment.userID != TiloBackend.shared.userID else { return }
        Task { [weak host, weak source] in
            guard let host else { return }
            do {
                let context = try await TiloBackend.shared.safetyContext(kind:"comment", id:comment.id.uuidString.lowercased())
                guard host.viewIfLoaded?.window != nil, host.presentedViewController == nil else { return }
                let sheet = UIAlertController(title:comment.displayName, message:nil, preferredStyle:.actionSheet)
                addActions(to:sheet, context:context, host:host, changed:changed)
                sheet.addAction(UIAlertAction(title:"Cancel", style:.cancel))
                sheet.popoverPresentationController?.sourceView = source ?? host.view
                host.present(sheet, animated:true)
            } catch { show(error, host:host) }
        }
    }

    private static func report(kind: String, id: String, host: UIViewController) {
        let page = ReportController(kind:kind, targetID:id)
        let navigation = UINavigationController(rootViewController:page); styleNavigation(navigation)
        host.present(navigation, animated:true)
    }
    private static func confirm(host: UIViewController, title: String, detail: String, action: String, operation: @escaping () async throws -> Void) {
        let alert = UIAlertController(title:title, message:detail, preferredStyle:.alert)
        alert.addAction(UIAlertAction(title:"Cancel", style:.cancel))
        alert.addAction(UIAlertAction(title:action, style:.destructive) { [weak host] _ in
            Task { do { try await operation() } catch { if let host { show(error, host:host) } } }
        })
        host.present(alert, animated:true)
    }
    private static func show(_ error: Error, host: UIViewController) {
        guard host.viewIfLoaded?.window != nil, host.presentedViewController == nil else { return }
        let alert = UIAlertController(title:"Safety change unavailable", message:error.localizedDescription, preferredStyle:.alert)
        alert.addAction(UIAlertAction(title:"OK", style:.default)); host.present(alert, animated:true)
    }
}

final class SafetyLongPress: UILongPressGestureRecognizer {
    private let handler: () -> Void
    init(handler: @escaping () -> Void) {
        self.handler = handler; super.init(target:nil, action:nil)
        addTarget(self, action:#selector(held))
    }
    @objc private func held() { if state == .began { handler() } }
}
