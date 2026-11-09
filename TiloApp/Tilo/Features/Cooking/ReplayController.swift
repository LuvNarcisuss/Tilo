import UIKit
import AVFoundation

private final class ReplaySurface:UIView {
    override class var layerClass:AnyClass { AVPlayerLayer.self }
    var playerLayer:AVPlayerLayer { layer as! AVPlayerLayer }
}

/// A recorded cooking room with server-acknowledged messages, never a synthetic audience.
final class ReplayController:UIViewController,UITextFieldDelegate {
    private let video:CookingVideo
    private let surface = ReplaySurface()
    private let input = UITextField()
    private let bubbles = UIStackView()
    private let state = text("Loading cooking replay…",16,color:.white)
    private var player:AVPlayer?
    private var ended:NSObjectProtocol?
    private var lifecycle:[NSObjectProtocol] = []
    private var status:NSKeyValueObservation?
    private var progressObserver:Any?
    private var roomTask:Task<Void,Never>?
    private var sending = false
    private var muted = false
    private var acknowledgedReactions = 0
    private var leaving = false
    private var loadingSafety = false
    private var messageIDs:[UUID] = []
    private let accountID = TiloBackend.shared.userID
    private weak var likeButton:UIButton?
    private var giftEffect: RoomGiftEffectView?
    private var animatedGiftIDs: Set<UUID> = []
    init(video:CookingVideo) { self.video = video; super.init(nibName:nil,bundle:nil) }
    required init?(coder:NSCoder) { fatalError("init(coder:) is unavailable") }
    override var preferredStatusBarStyle:UIStatusBarStyle { .lightContent }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = .black
        view.addSubview(surface); surface.fill(view); surface.playerLayer.videoGravity = .resizeAspectFill
        surface.isAccessibilityElement = true; surface.accessibilityLabel = "Cooking video"; surface.accessibilityIdentifier = "replay-progress"; surface.accessibilityValue = "0"
        let shade = UIView(); shade.backgroundColor = UIColor.black.withAlphaComponent(0.16); shade.isUserInteractionEnabled = false
        view.addSubview(shade); shade.fill(view)
        let heading = column([roomText("REPLAY · " + video.title,18,heading:true),roomText("Film by " + video.payload.chef,13)],spacing:0)
        heading.accessibilityLabel = "Recorded cooking film · No live audience"
        let top = row([heading,icon(.more,"More") { [weak self] in self?.more() },icon(.close,"Close") { [weak self] in self?.close() }],spacing:8)
        top.alignment = .center
        view.addSubview(top); top.translatesAutoresizingMaskIntoConstraints = false
        let footer = UIStackView(); footer.axis = .vertical; footer.spacing = 10
        state.accessibilityIdentifier = "room-status"; state.numberOfLines = 2; footer.addArrangedSubview(state)
        bubbles.axis = .vertical; bubbles.spacing = 6; bubbles.accessibilityIdentifier = "room-messages"
        footer.addArrangedSubview(bubbles)
        input.font = compactFont(16); input.textColor = .white; input.attributedPlaceholder = NSAttributedString(string:"Say something…",attributes:[.font:compactFont(16),.foregroundColor:UIColor.white.withAlphaComponent(0.85)])
        input.backgroundColor = UIColor.black.withAlphaComponent(0.48); input.layer.cornerRadius = 22
        let inset = UIView(frame:CGRect(x:0,y:0,width:12,height:1)); input.leftView = inset; input.leftViewMode = .always
        input.accessibilityLabel = "Room message"; input.returnKeyType = .send; input.delegate = self
        input.autocorrectionType = .yes; input.enablesReturnKeyAutomatically = true
        input.setContentHuggingPriority(.defaultLow,for:.horizontal); input.setContentCompressionResistancePriority(.defaultLow,for:.horizontal)
        input.heightAnchor.constraint(equalToConstant:44).isActive = true
        let send = icon(.send,"Send room message") { [weak self] in self?.sendMessage() }
        let like = icon(.heart,"Like replay") { [weak self] in self?.sendReaction() }; likeButton = like; updateReaction()
        let gift = icon(.gift,"Send a gift") { [weak self] in self?.gifts() }
        let share = icon(.share,"Share this kitchen") { [weak self] in self?.share() }
        footer.addArrangedSubview(row([input,send,like,gift,share],spacing:4))
        view.addSubview(footer); footer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            top.leadingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.leadingAnchor,constant:16),top.trailingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.trailingAnchor,constant:-16),top.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor,constant:8),
            footer.leadingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.leadingAnchor,constant:16),footer.trailingAnchor.constraint(equalTo:view.safeAreaLayoutGuide.trailingAnchor,constant:-16),footer.bottomAnchor.constraint(equalTo:view.keyboardLayoutGuide.topAnchor,constant:-12),footer.topAnchor.constraint(greaterThanOrEqualTo:top.bottomAnchor,constant:12)
        ])
        lifecycle.append(NotificationCenter.default.addObserver(forName:UIApplication.willResignActiveNotification,object:nil,queue:.main) { [weak self] _ in
            self?.player?.pause(); self?.roomTask?.cancel(); self?.roomTask = nil
        })
        lifecycle.append(NotificationCenter.default.addObserver(forName:UIApplication.didBecomeActiveNotification,object:nil,queue:.main) { [weak self] _ in self?.resume() })
        lifecycle.append(NotificationCenter.default.addObserver(forName:UIApplication.willResignActiveNotification,object:nil,queue:.main) { [weak self] _ in self?.giftEffect?.cancel(); self?.giftEffect = nil })
        load()
    }
    private func compactFont(_ size:CGFloat,heading:Bool = false) -> UIFont {
        let font = TiloTheme.font(size,heading:heading)
        return font.withSize(min(font.pointSize,heading ? 25 : 22))
    }
    private func roomText(_ copy:String,_ size:CGFloat,heading:Bool = false) -> UILabel {
        let label = text(copy,size,heading:heading,color:.white); label.font = compactFont(size,heading:heading); label.numberOfLines = 1
        label.layer.shadowColor = UIColor.black.cgColor; label.layer.shadowOpacity = 0.7; label.layer.shadowRadius = 3; label.layer.shadowOffset = .zero
        return label
    }
    private func icon(_ image:TiloIcon,_ name:String,_ handler:@escaping () -> Void) -> UIButton {
        let button = UIButton(type:.custom); button.setImage(image.image(27),for:.normal)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.48); button.layer.cornerRadius = 22; button.accessibilityLabel = name
        button.addAction(UIAction { _ in handler() },for:.touchUpInside); button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([button.widthAnchor.constraint(equalToConstant:44),button.heightAnchor.constraint(equalToConstant:44)])
        return button
    }
    override func viewDidAppear(_ animated:Bool) { super.viewDidAppear(animated); resume() }
    override func viewDidDisappear(_ animated:Bool) {
        super.viewDidDisappear(animated)
        if isBeingDismissed || presentingViewController == nil { stop() }
    }
    private func resume() {
        guard !leaving,viewIfLoaded?.window != nil,UIApplication.shared.applicationState == .active else { return }
        if player?.currentItem?.status == .readyToPlay { player?.play() }
        guard roomTask == nil else { return }
        roomTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refreshMessages()
                do { try await Task.sleep(for:.seconds(4)) } catch { return }
            }
        }
    }
    private func load() {
        guard let value = video.videoURL,let url = URL(string:value),url.scheme == "https" else { state.text = "This replay is unavailable."; return }
        if let progressObserver,let player { player.removeTimeObserver(progressObserver); self.progressObserver = nil }
        if let ended { NotificationCenter.default.removeObserver(ended); self.ended = nil }
        status = nil; player?.pause()
        do { try AVAudioSession.sharedInstance().setCategory(.playback,mode:.moviePlayback); try AVAudioSession.sharedInstance().setActive(true) }
        catch { state.text = "Audio is unavailable." }
        let item = AVPlayerItem(url:url); let created = AVPlayer(playerItem:item); player = created; surface.playerLayer.player = created; created.isMuted = muted
        progressObserver = created.addPeriodicTimeObserver(forInterval:CMTime(seconds:0.25,preferredTimescale:600),queue:.main) { [weak self] time in
            guard time.seconds.isFinite,time.seconds >= 0 else { return }
            self?.surface.accessibilityValue = String(format:"%.2f",time.seconds)
        }
        status = item.observe(\.status,options:[.new,.initial]) { [weak self] observed,_ in
            Task { @MainActor in
                guard let self,self.player?.currentItem === observed else { return }
                switch observed.status {
                case .readyToPlay: self.state.text = ""; self.resume()
                case .failed: self.state.text = "Replay could not play. Open More to retry."
                default: self.state.text = "Loading cooking replay…"
                }
            }
        }
        ended = NotificationCenter.default.addObserver(forName:.AVPlayerItemDidPlayToEndTime,object:item,queue:.main) { [weak self] _ in
            self?.player?.seek(to:.zero) { [weak self] _ in Task { @MainActor in self?.resume() } }
        }
        resume()
    }
    private func refreshMessages() async {
        guard !leaving,!Task.isCancelled,accountID == TiloBackend.shared.userID else { return }
        do {
            let received = try await TiloBackend.shared.comments(contentID:video.id)
            guard !leaving,!Task.isCancelled,accountID == TiloBackend.shared.userID else { return }
            if state.text?.hasPrefix("Room messages could not refresh") == true { state.text = "" }
            let recent = Array(received.sorted { ($0.createdAt,$0.id.uuidString) < ($1.createdAt,$1.id.uuidString) }.suffix(UIAccessibility.isVoiceOverRunning ? 1 : 5))
            guard recent.map(\.id) != messageIDs else { return }; messageIDs = recent.map(\.id)
            bubbles.arrangedSubviews.forEach { $0.removeFromSuperview() }
            for message in recent {
                let label = roomText(message.displayName + ": " + message.body,15)
                label.numberOfLines = 2; label.lineBreakMode = .byTruncatingTail
                label.backgroundColor = UIColor.black.withAlphaComponent(0.48); label.layer.cornerRadius = 10; label.clipsToBounds = true
                label.accessibilityIdentifier = "room-message-" + message.id.uuidString.lowercased()
                if message.userID != accountID {
                    label.isUserInteractionEnabled = true
                    let options = { [weak self, weak label] in
                        guard let self else { return }
                        ContentSafety.message(message, host:self, source:label) { [weak self] in Task { await self?.refreshMessages() } }
                    }
                    label.addGestureRecognizer(SafetyLongPress(handler:options))
                    label.accessibilityHint = "Touch and hold for report and block options."
                    label.accessibilityCustomActions = [UIAccessibilityCustomAction(name:"Comment options") { _ in options(); return true }]
                }
                bubbles.addArrangedSubview(label)
            }
            if !UIAccessibility.isReduceMotionEnabled { bubbles.alpha = 0.5; UIView.animate(withDuration:0.2) { self.bubbles.alpha = 1 } }
        } catch {
            if !Task.isCancelled,!leaving {
                if error.localizedDescription == "Content unavailable." { close() }
                else { state.text = "Room messages could not refresh. Try again in More." }
            }
        }
    }
    private func sendMessage() {
        let body = (input.text ?? "").trimmingCharacters(in:.whitespacesAndNewlines)
        guard !body.isEmpty,!sending,accountID == TiloBackend.shared.userID else { return }
        guard body.count <= 50 else { show("A little shorter, please","Keep room messages within 50 characters."); return }
        sending = true
        Task { [weak self] in
            guard let self else { return }; defer { sending = false }
            do {
                try await TiloBackend.shared.addComment(contentID:video.id,body:body)
                guard !leaving,accountID == TiloBackend.shared.userID else { return }
                if input.text?.trimmingCharacters(in:.whitespacesAndNewlines) == body { input.text = "" }
                view.endEditing(true); await refreshMessages()
            } catch { if !leaving { show("Message not sent",error.localizedDescription) } }
        }
    }
    func textFieldShouldReturn(_ textField:UITextField) -> Bool { sendMessage(); return false }
    private func updateReaction() {
        likeButton?.accessibilityValue = "\(acknowledgedReactions) reactions this visit"
        likeButton?.accessibilityHint = "Send another heart. Room reactions do not enter your liked recipes."
    }
    private func sendReaction() {
        guard !leaving, accountID == TiloBackend.shared.userID else { return }
        let id = UUID()
        Task { [weak self] in
            guard let self else { return }
            do {
                try await TiloBackend.shared.addRoomReaction(contentID:video.id, id:id)
                guard !leaving, accountID == TiloBackend.shared.userID else { return }
                acknowledgedReactions += 1; updateReaction()
                if state.text == "Your reaction could not be sent. Tap the heart to try again." { state.text = "" }
                guard !UIAccessibility.isReduceMotionEnabled, let likeButton else { return }
                UIView.animate(withDuration:0.12,delay:0,options:[.beginFromCurrentState,.allowUserInteraction]) { likeButton.transform = CGAffineTransform(scaleX:1.16,y:1.16) } completion: { _ in
                    UIView.animate(withDuration:0.18,delay:0,options:[.beginFromCurrentState,.allowUserInteraction]) { likeButton.transform = .identity }
                }
            } catch {
                if !leaving, accountID == TiloBackend.shared.userID { state.text = "Your reaction could not be sent. Tap the heart to try again." }
            }
        }
    }
    private func presentPage(_ page:UIViewController,largeSheet:Bool) {
        view.endEditing(true)
        let nav = UINavigationController(rootViewController:page); styleNavigation(nav)
        if largeSheet {
            nav.modalPresentationStyle = .pageSheet
            nav.sheetPresentationController?.detents = [.medium()]
            nav.sheetPresentationController?.selectedDetentIdentifier = .medium
            nav.sheetPresentationController?.largestUndimmedDetentIdentifier = .medium
            nav.sheetPresentationController?.prefersScrollingExpandsWhenScrolledToEdge = false
            nav.sheetPresentationController?.prefersGrabberVisible = true
        }
        present(nav,animated:true)
    }
    private func gifts() {
        let page = RoomGiftsController(video: video) { [weak self] receipt in
            guard let self, !leaving else { return }
            state.text = "Gift recorded · \(receipt.quantity) × \(receipt.giftName)"
            showGiftEffect(receipt)
        }
        presentPage(page,largeSheet:true)
    }
    private func showGiftEffect(_ receipt: TiloGiftReceipt) {
        guard animatedGiftIDs.insert(receipt.id).inserted else { return }
        giftEffect?.cancel()
        let top = view.safeAreaInsets.top + 90
        var bottom = view.bounds.height - view.safeAreaInsets.bottom - 100
        if let presentation = presentedViewController?.presentationController, let container = presentation.containerView {
            bottom = min(bottom, view.convert(presentation.frameOfPresentedViewInContainerView, from: container).minY - 8)
        }
        let effect = RoomGiftEffectView(receipt: receipt)
        effect.frame = CGRect(x: 8, y: top, width: view.bounds.width - 16, height: max(100, bottom - top))
        view.addSubview(effect); giftEffect = effect
        effect.play { [weak self, weak effect] in if self?.giftEffect === effect { self?.giftEffect = nil } }
    }
    private func openRecipe() {
        guard let id = video.payload.recipeID else { show("Recipe unavailable","This cooking film does not have a linked recipe."); return }
        Task { [weak self] in
            guard let self else { return }
            do { let recipe = try await TiloBackend.shared.recipe(id:id); guard !leaving else { return }; presentPage(RecipeDetailController(recipe:recipe),largeSheet:false) }
            catch { show("Could not load recipe",error.localizedDescription) }
        }
    }
    private func more() {
        guard !loadingSafety, !leaving else { return }; loadingSafety = true
        Task { [weak self] in
            guard let self else { return }; defer { loadingSafety = false }
            do {
                let context = try await TiloBackend.shared.safetyContext(kind:"video", id:video.id)
                guard !leaving, accountID == TiloBackend.shared.userID else { return }
                showMore(context)
            } catch { if !leaving { show("Room actions unavailable",error.localizedDescription) } }
        }
    }
    private func showMore(_ context: ContentSafetyContext) {
        view.endEditing(true)
        var credit = "Recorded cooking film · No live audience\nFilm by " + video.payload.chef
        if let name = context.authorName { credit += "\nShared by " + name }
        let sheet = UIAlertController(title:video.title,message:credit,preferredStyle:.actionSheet)
        sheet.addAction(UIAlertAction(title:muted ? "Sound on" : "Sound off",style:.default) { [weak self] _ in self?.muted.toggle(); self?.player?.isMuted = self?.muted ?? false })
        sheet.addAction(UIAlertAction(title:"Recipe",style:.default) { [weak self] _ in self?.openRecipe() })
        sheet.addAction(UIAlertAction(title:"Retry playback",style:.default) { [weak self] _ in self?.load() })
        sheet.addAction(UIAlertAction(title:"Refresh room messages",style:.default) { [weak self] _ in Task { await self?.refreshMessages() } })
        ContentSafety.addActions(to:sheet, context:context, host:self) { [weak self] in self?.close() }
        sheet.addAction(UIAlertAction(title:"Cancel",style:.cancel)); sheet.popoverPresentationController?.sourceView = view; present(sheet,animated:true)
    }
    private func share() { view.endEditing(true); let sheet = UIActivityViewController(activityItems:["Watch \(video.title) on Tilo · a cooking replay."],applicationActivities:nil); sheet.popoverPresentationController?.sourceView = view; present(sheet,animated:true) }
    private func show(_ title:String,_ detail:String) { let alert = UIAlertController(title:title,message:detail,preferredStyle:.alert); alert.addAction(UIAlertAction(title:"OK",style:.default)); present(alert,animated:true) }
    private func stop() { leaving = true; giftEffect?.cancel(); giftEffect = nil; roomTask?.cancel(); roomTask = nil; player?.pause(); player?.replaceCurrentItem(with:nil); try? AVAudioSession.sharedInstance().setActive(false,options:.notifyOthersOnDeactivation) }
    private func close() { stop(); dismiss(animated:true) }
    deinit { roomTask?.cancel(); if let progressObserver,let player { player.removeTimeObserver(progressObserver) }; player?.pause(); if let ended { NotificationCenter.default.removeObserver(ended) }; lifecycle.forEach { NotificationCenter.default.removeObserver($0) } }
}

