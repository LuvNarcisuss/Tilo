import UIKit
import AVFoundation

private final class RoomCoverVideoSurface:UIView {
    override class var layerClass:AnyClass { AVPlayerLayer.self }
    var playerLayer:AVPlayerLayer { layer as! AVPlayerLayer }
}

private final class RoomCoverShade:UIView {
    override class var layerClass:AnyClass { CAGradientLayer.self }
    override init(frame:CGRect) {
        super.init(frame:frame)
        let gradient = layer as! CAGradientLayer
        gradient.colors = [UIColor.clear.cgColor,UIColor.black.withAlphaComponent(0.16).cgColor,UIColor.black.withAlphaComponent(0.9).cgColor]
        gradient.locations = [0,0.35,1]
        isUserInteractionEnabled = false
    }
    required init?(coder:NSCoder) { fatalError("init(coder:) is unavailable") }
}

/// A recorded cooking room, with real muted footage and no simulated audience or host identity.
final class TiloLiveRoomCard:UIView {
    let video:CookingVideo
    private let surface = RoomCoverVideoSurface()
    private let cover:RemotePhoto
    private let entry = UIButton(type:.custom)
    private var queue:AVQueuePlayer?
    private var looper:AVPlayerLooper?
    private var preparation:Task<Void,Never>?
    private var ready:NSKeyValueObservation?
    private var progressObserver:Any?
    private var wantsPlayback = false
    private var elapsed = 0.0
    private var lastTime:Double?

    init(video:CookingVideo,open:@escaping () -> Void) {
        self.video = video; cover = RemotePhoto(video.imageURL,height:nil)
        super.init(frame:.zero)
        backgroundColor = UIColor(red:0.94,green:0.78,blue:0.40,alpha:1); round(23)
        layer.borderWidth = 1; layer.borderColor = TiloTheme.red.withAlphaComponent(0.5).cgColor
        let frame = UIView(); frame.backgroundColor = TiloTheme.olive; frame.round(20)
        addSubview(frame); frame.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([frame.leadingAnchor.constraint(equalTo:leadingAnchor,constant:3),frame.trailingAnchor.constraint(equalTo:trailingAnchor,constant:-3),frame.topAnchor.constraint(equalTo:topAnchor,constant:3),frame.bottomAnchor.constraint(equalTo:bottomAnchor,constant:-3)])
        frame.addSubview(surface); surface.fill(frame); surface.playerLayer.videoGravity = .resizeAspectFill
        surface.isUserInteractionEnabled = false; surface.isAccessibilityElement = true
        surface.accessibilityLabel = "Muted cover playback seconds"; surface.accessibilityValue = "0"
        surface.accessibilityIdentifier = "room-cover-progress-" + video.id; surface.accessibilityTraits = .updatesFrequently
        frame.addSubview(cover); cover.fill(frame); cover.round(20); cover.isAccessibilityElement = false
        let shade = RoomCoverShade(); frame.addSubview(shade); shade.fill(frame)
        let replay = text("REPLAY",11,heading:true,color:.white)
        let replayIcon = UIImageView(image:TiloIcon.video.image(16)); replayIcon.contentMode = .scaleAspectFit
        replayIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([replayIcon.widthAnchor.constraint(equalToConstant:16),replayIcon.heightAnchor.constraint(equalToConstant:16)])
        let badgeContent = row([replayIcon,replay],spacing:4)
        let badge = UIView(); badge.backgroundColor = TiloTheme.red; badge.round(11); badge.addSubview(badgeContent)
        badgeContent.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([badgeContent.leadingAnchor.constraint(equalTo:badge.leadingAnchor,constant:8),badgeContent.trailingAnchor.constraint(equalTo:badge.trailingAnchor,constant:-8),badgeContent.topAnchor.constraint(equalTo:badge.topAnchor,constant:5),badgeContent.bottomAnchor.constraint(equalTo:badge.bottomAnchor,constant:-5)])
        frame.addSubview(badge); badge.translatesAutoresizingMaskIntoConstraints = false; badge.isUserInteractionEnabled = false
        let room = text("COOKING ROOM",10,heading:true,color:UIColor(red:1,green:0.87,blue:0.56,alpha:1))
        let title = text(video.title,19,heading:true,color:.white); title.numberOfLines = 2
        let category = text(video.category,12,color:.white)
        let credit = text("Film by " + video.payload.chef,11,color:UIColor.white.withAlphaComponent(0.9)); credit.numberOfLines = 2
        let play = UIImageView(image:TiloIcon.play.image(22)); play.contentMode = .scaleAspectFit
        play.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([play.widthAnchor.constraint(equalToConstant:22),play.heightAnchor.constraint(equalToConstant:22)])
        let roomLine = row([room,play],spacing:4)
        let caption = column([roomLine,title,category,credit],spacing:3)
        caption.isUserInteractionEnabled = false; frame.addSubview(caption); caption.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([badge.leadingAnchor.constraint(equalTo:frame.leadingAnchor,constant:9),badge.topAnchor.constraint(equalTo:frame.topAnchor,constant:10),badge.trailingAnchor.constraint(lessThanOrEqualTo:frame.trailingAnchor,constant:-9),caption.leadingAnchor.constraint(equalTo:frame.leadingAnchor,constant:10),caption.trailingAnchor.constraint(equalTo:frame.trailingAnchor,constant:-10),caption.bottomAnchor.constraint(equalTo:frame.bottomAnchor,constant:-12),caption.topAnchor.constraint(greaterThanOrEqualTo:badge.bottomAnchor,constant:20)])
        entry.addAction(UIAction { _ in open() },for:.touchUpInside)
        entry.accessibilityIdentifier = "live-room-card-" + video.id
        entry.accessibilityLabel = "Enter kitchen"; entry.accessibilityValue = video.title + ", Cooking room replay, Film by " + video.payload.chef
        entry.accessibilityHint = "Opens a recorded cooking room."
        addSubview(entry); entry.fill(self)
        accessibilityElements = [title,entry,surface]
        if let publisher = video.publisher {
            let avatar = PublisherAvatarButton(publisher: publisher, contentID: video.id)
            addSubview(avatar)
            NSLayoutConstraint.activate([avatar.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),avatar.topAnchor.constraint(equalTo: topAnchor, constant: 12)])
            accessibilityElements = [title, entry, avatar, surface]
        }
    }
    required init?(coder:NSCoder) { fatalError("init(coder:) is unavailable") }

    func setPreviewing(_ active:Bool) {
        let active = active && !UIAccessibility.isReduceMotionEnabled
        guard active != wantsPlayback else { return }; wantsPlayback = active
        if active {
            if let queue { queue.play() }
            else { prepare() }
        } else {
            queue?.pause()
            if queue == nil { preparation?.cancel(); preparation = nil }
        }
    }
    private func prepare() {
        guard let value = video.videoURL,let url = URL(string:value),url.scheme == "https" else { return }
        preparation?.cancel()
        preparation = Task { [weak self] in
            let asset = AVURLAsset(url:url)
            guard let duration = try? await asset.load(.duration),duration.seconds.isFinite,duration.seconds > 0.1 else { return }
            guard !Task.isCancelled,let self,wantsPlayback,window != nil else { return }
            let clip = min(1,duration.seconds - 0.04)
            let start = max(0,(duration.seconds - clip) / 2)
            let item = AVPlayerItem(asset:asset)
            let player = AVQueuePlayer(); player.isMuted = true; queue = player
            surface.playerLayer.player = player
            ready = surface.playerLayer.observe(\.isReadyForDisplay,options:[.new,.initial]) { [weak self] layer,_ in
                Task { @MainActor in guard let self,layer.isReadyForDisplay,self.wantsPlayback else { return }; self.cover.isHidden = true }
            }
            progressObserver = player.addPeriodicTimeObserver(forInterval:CMTime(seconds:0.1,preferredTimescale:600),queue:.main) { [weak self,weak player] time in
                guard let self,let player,self.queue === player,wantsPlayback,time.seconds.isFinite,time.seconds >= 0 else { return }
                guard time.seconds >= start - 0.05,time.seconds <= start + clip + 0.1 else { return }
                if let previous = lastTime,time.seconds >= previous { elapsed += time.seconds - previous }
                lastTime = time.seconds; surface.accessibilityValue = String(format:"%.2f",elapsed)
            }
            looper = AVPlayerLooper(player:player,templateItem:item,timeRange:CMTimeRange(start:CMTime(seconds:start,preferredTimescale:600),duration:CMTime(seconds:clip,preferredTimescale:600)))
            if wantsPlayback { player.play() }
        }
    }
    func releasePreview() {
        wantsPlayback = false; preparation?.cancel(); preparation = nil; ready = nil
        if let progressObserver,let queue { queue.removeTimeObserver(progressObserver) }; progressObserver = nil
        queue?.pause(); looper?.disableLooping(); looper = nil; queue?.removeAllItems(); queue = nil
        surface.playerLayer.player = nil; cover.isHidden = false; lastTime = nil
    }
    deinit { preparation?.cancel(); if let progressObserver,let queue { queue.removeTimeObserver(progressObserver) }; queue?.pause(); looper?.disableLooping() }
}
